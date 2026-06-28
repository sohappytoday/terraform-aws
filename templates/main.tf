module "vpc" {
  source = "./modules/vpc"

  name                = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

module "control_plane" {
  for_each = var.control_plane_nodes
  source   = "./modules/ec2"

  instance_type        = each.value.instance_type
  instance_name        = each.value.instance_name
  root_volume_size     = each.value.root_volume_size
  root_volume_type     = each.value.root_volume_type
  key_pair_name        = aws_key_pair.worker_node.key_name
  ssh_allowed_cidr     = var.control_plane_ssh_allowed_cidr
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  iam_instance_profile = aws_iam_instance_profile.ssm.name
  user_data            = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${each.key}
  EOF
}

resource "aws_key_pair" "worker_node" {
  key_name   = var.worker_key_pair_name
  public_key = file(var.public_key_path)
}

module "worker_node" {
  for_each = var.worker_nodes
  source   = "./modules/ec2"

  instance_type    = each.value.instance_type
  instance_name    = each.value.instance_name
  root_volume_size = each.value.root_volume_size
  root_volume_type = each.value.root_volume_type
  key_pair_name    = aws_key_pair.worker_node.key_name
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.private_subnet_id
  user_data        = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${each.key}
  EOF
}

# 모든 클러스터 노드(control-plane + worker)의 SG를 한데 모음
locals {
  cluster_node_sg_ids = merge(
    { for k, m in module.control_plane : k => m.security_group_id },
    { for k, m in module.worker_node : k => m.security_group_id },
  )
}

# 노드 간(cp↔cp, cp↔worker, worker↔worker) 전체 허용
# CNI 포트 변동·HA 확장에 무관하게 동작하도록 SG 참조로 all-to-all 구성
resource "aws_security_group_rule" "node_to_node_all" {
  for_each = {
    for pair in setproduct(keys(local.cluster_node_sg_ids), keys(local.cluster_node_sg_ids)) :
    "${pair[0]}_from_${pair[1]}" => pair
  }

  type                     = "ingress"
  description              = "Cluster node traffic: ${each.value[0]} from ${each.value[1]}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = local.cluster_node_sg_ids[each.value[1]]
  security_group_id        = local.cluster_node_sg_ids[each.value[0]]
}
