data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# NAT 인스턴스 SG
# Private Subnet에서 오는 트래픽(인터넷으로 나가려는 패킷)을 받아 외부로 중계한다.
resource "aws_security_group" "nat" {
  name        = "${var.name}-nat-sg"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id

  # Private Subnet 노드들이 인터넷으로 나가려고 보내는 트래픽을 전부 수용
  ingress {
    description = "All traffic from private subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-nat-sg"
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_pair_name
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = [aws_security_group.nat.id]

  # NAT는 자신이 아닌 다른 인스턴스의 트래픽을 중계하므로 source/destination check를 꺼야 한다.
  source_dest_check = false

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # 1. IP forwarding 활성화
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-nat.conf
    sysctl -p /etc/sysctl.d/99-nat.conf

    # 2. 기본 인터페이스로 나가는 트래픽에 MASQUERADE(NAT) 적용
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')
    iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

    # 3. 재부팅 후에도 규칙이 유지되도록 영속화
    export DEBIAN_FRONTEND=noninteractive
    echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | debconf-set-selections
    echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | debconf-set-selections
    apt-get update -y
    apt-get install -y iptables-persistent
    netfilter-persistent save
  EOF

  tags = {
    Name = "${var.name}-nat"
  }
}
