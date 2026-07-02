# 공용 VPC (Public Subnet + IGW) + 키페어.
# jenkins/cluster state가 이 출력을 remote_state로 읽어 같은 네트워크에 인스턴스를 올린다.

module "vpc" {
  source = "../modules/vpc"

  name               = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}
