# network state에서 VPC/서브넷/키페어를 읽어온다. (먼저 network를 apply해야 함)
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../network/terraform.tfstate"
  }
}

# 단일 노드 클러스터.
# 22는 관리자 IP만(ec2 모듈), 서비스 포트(80/443/32339/32340)는 전체 허용.
module "cluster" {
  source = "../modules/ec2"

  instance_type    = var.instance_type
  instance_name    = "${var.cluster_name}-control-plane"
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  key_pair_name    = data.terraform_remote_state.network.outputs.key_name
  ssh_allowed_cidr = [var.my_ip]
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  subnet_id        = data.terraform_remote_state.network.outputs.public_subnet_id
  user_data        = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${var.cluster_name}-control-plane
  EOF
}

resource "aws_security_group_rule" "service" {
  for_each = toset([for p in var.service_ports : tostring(p)])

  type              = "ingress"
  description       = "service port ${each.value}"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.cluster.security_group_id
}
