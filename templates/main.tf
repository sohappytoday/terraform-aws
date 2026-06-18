module "vpc" {
  source = "./modules/vpc"

  name                = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

module "control_plane" {
  source = "./modules/ec2"

  instance_type    = var.control_plane_instance_type
  instance_name    = var.control_plane_instance_name
  root_volume_size = var.control_plane_root_volume_size
  root_volume_type = var.control_plane_root_volume_type
  key_pair_name    = aws_key_pair.worker_node.key_name
  ssh_allowed_cidr = var.control_plane_ssh_allowed_cidr
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_id
  user_data        = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname master-1
  EOF
}

resource "aws_key_pair" "worker_node" {
  key_name   = var.worker_key_pair_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group_rule" "cp_from_worker_6443" {
  for_each = module.worker_node

  type                     = "ingress"
  description              = "Worker Node → API Server"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = each.value.security_group_id
  security_group_id        = module.control_plane.security_group_id
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
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${each.key}
  EOF
}

resource "aws_security_group_rule" "worker_from_cp_10250" {
  for_each = module.worker_node

  type                     = "ingress"
  description              = "Control Plane → Kubelet API"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = module.control_plane.security_group_id
  security_group_id        = each.value.security_group_id
}

resource "aws_security_group_rule" "worker_from_cp_10256" {
  for_each = module.worker_node

  type                     = "ingress"
  description              = "Control Plane → kube-proxy"
  from_port                = 10256
  to_port                  = 10256
  protocol                 = "tcp"
  source_security_group_id = module.control_plane.security_group_id
  security_group_id        = each.value.security_group_id
}
