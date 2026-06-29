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
  subnet_id            = module.vpc.private_subnet_id
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

  instance_type        = each.value.instance_type
  instance_name        = each.value.instance_name
  root_volume_size     = each.value.root_volume_size
  root_volume_type     = each.value.root_volume_type
  key_pair_name        = aws_key_pair.worker_node.key_name
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.private_subnet_id
  iam_instance_profile = aws_iam_instance_profile.ssm.name
  user_data            = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${each.key}
  EOF
}

# NAT 인스턴스 (Public Subnet)
# control-plane·worker가 모두 Private Subnet으로 이동하면서 인터넷 outbound 경로가
# 사라진다(패키지 설치·이미지 pull 불가). NAT Gateway는 비싸므로, 작은 EC2를
# NAT로 두어 Private Subnet의 outbound를 중계한다.
module "nat" {
  source = "./modules/nat"

  name                 = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  instance_type        = var.nat_instance_type
  private_subnet_cidr  = var.private_subnet_cidr
  key_pair_name        = aws_key_pair.worker_node.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm.name
}

# Private Subnet → 인터넷 outbound를 NAT 인스턴스로 보내는 라우트.
# 라우트 테이블(vpc 모듈)과 NAT ENI(nat 모듈)를 root에서 연결한다.
resource "aws_route" "private_to_nat" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat.network_interface_id
}

# Reverse Proxy (Public Subnet)
# 외부 사용자 트래픽의 유일한 진입점. 80/443으로 받아 worker의 Ingress NodePort로
# 포워딩한다. worker는 Private에 숨긴 채 서비스를 노출하기 위함.
module "reverse_proxy" {
  source = "./modules/reverse-proxy"

  name                 = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  instance_type        = var.reverse_proxy_instance_type
  key_pair_name        = aws_key_pair.worker_node.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm.name
  upstream_ips         = [for k, m in module.worker_node : m.private_ip]
  ingress_nodeport     = var.ingress_nodeport
}

# Reverse Proxy → Worker의 Ingress NodePort 허용.
# 외부 진입은 오직 Reverse Proxy를 통해서만 worker에 닿게 한다(SG 참조).
resource "aws_security_group_rule" "worker_from_reverse_proxy" {
  for_each = module.worker_node

  type                     = "ingress"
  description              = "Ingress NodePort from reverse proxy"
  from_port                = var.ingress_nodeport
  to_port                  = var.ingress_nodeport
  protocol                 = "tcp"
  source_security_group_id = module.reverse_proxy.security_group_id
  security_group_id        = each.value.security_group_id
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

# -----------------------------------------------
# Network ACL (Public Subnet) — 악성 IP 차단 (이중 방어선)
# -----------------------------------------------
# Reverse Proxy가 위치한 Public Subnet의 경계 방화벽.
# Security Group은 allow 전용이라 공개 서비스를 0.0.0.0/0으로 열 수밖에 없고
# 특정 악성 IP를 골라 막을 수 없다. NACL은 deny가 가능하므로, 트래픽 공격 같은
# 알려진 악성 출처를 서브넷 경계(인스턴스 도달 전)에서 차단한다.
#
# NACL은 stateless라 응답 트래픽(ephemeral port)까지 직접 허용해야 하며, 규칙은
# rule_number 오름차순으로 평가되어 먼저 매치되면 종료된다. 따라서 deny(100번대)를
# allow(200번대)보다 앞에 둔다. (inbound·outbound 번호 공간은 서로 독립적이다.)
resource "aws_network_acl" "public" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnet_id]

  tags = {
    Name = "${var.cluster_name}-public-nacl"
  }
}

# (1) 악성 IP 차단 — inbound. 최우선(가장 낮은 번호)으로 평가된다.
resource "aws_network_acl_rule" "public_deny_in" {
  count = length(var.blocked_cidrs)

  network_acl_id = aws_network_acl.public.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.blocked_cidrs[count.index]
}

# (1) 악성 IP 차단 — outbound. 차단 대상에는 응답도 보내지 않아 완전히 격리한다.
resource "aws_network_acl_rule" "public_deny_out" {
  count = length(var.blocked_cidrs)

  network_acl_id = aws_network_acl.public.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.blocked_cidrs[count.index]
}

# (2) VPC 내부 트래픽 허용 — inbound. 노드 간 통신, Private 노드가 NAT로 보내는
#     outbound 중계 트래픽 등 VPC 내부 흐름이 끊기지 않도록 VPC 전체를 허용한다.
resource "aws_network_acl_rule" "public_allow_vpc_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# (3) 서비스 inbound — Reverse Proxy의 HTTP(80) / HTTPS(443)
resource "aws_network_acl_rule" "public_allow_http_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 210
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_allow_https_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 220
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# (4) ephemeral port inbound — stateless이므로, 노드/RP가 시작한 outbound(NAT 경유,
#     이미지 pull 등)에 대한 인터넷의 응답이 되돌아 들어오는 경로를 열어야 한다.
resource "aws_network_acl_rule" "public_allow_ephemeral_in" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 230
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# (5) outbound 전체 허용 — RP→worker, NAT→인터넷, 사용자 응답 등.
#     악성 IP는 위 deny(100번대)에서 이미 걸러진다.
resource "aws_network_acl_rule" "public_allow_all_out" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
