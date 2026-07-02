# network state에서 VPC/서브넷/키페어를 읽어온다. (먼저 network를 apply해야 함)
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../network/terraform.tfstate"
  }
}

# -----------------------------------------------
# GitHub webhook 소스 IP 대역
# push 시 GitHub가 Jenkins(8080)로 POST를 보내오므로, 그 출처만 인바운드로 연다.
# api.github.com/meta 의 hooks 배열이 webhook 발신 대역이며, apply 때마다 갱신된다.
# -----------------------------------------------
data "http" "github_meta" {
  url = "https://api.github.com/meta"
}

locals {
  github_hooks    = jsondecode(data.http.github_meta.response_body).hooks
  github_hooks_v4 = [for c in local.github_hooks : c if !strcontains(c, ":")]
  github_hooks_v6 = [for c in local.github_hooks : c if strcontains(c, ":")]
}

module "jenkins" {
  source = "../modules/ec2"

  instance_type    = var.instance_type
  instance_name    = "${var.cluster_name}-jenkins"
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  key_pair_name    = data.terraform_remote_state.network.outputs.key_name
  ssh_allowed_cidr = [var.my_ip]
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  subnet_id        = data.terraform_remote_state.network.outputs.public_subnet_id
  user_data        = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${var.cluster_name}-jenkins
  EOF
}

# Jenkins UI(관리자 IP) + GitHub webhook(GitHub hook 대역). 전 세계 개방은 피한다.
resource "aws_security_group_rule" "jenkins_web" {
  type              = "ingress"
  description       = "Jenkins UI (admin) + GitHub webhook"
  from_port         = var.jenkins_port
  to_port           = var.jenkins_port
  protocol          = "tcp"
  cidr_blocks       = concat([var.my_ip], local.github_hooks_v4)
  ipv6_cidr_blocks  = local.github_hooks_v6
  security_group_id = module.jenkins.security_group_id
}
