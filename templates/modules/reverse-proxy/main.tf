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

locals {
  # nginx upstream 블록의 server 라인들 (worker IP : NodePort)
  upstream_servers = join("\n    ", [for ip in var.upstream_ips : "server ${ip}:${var.ingress_nodeport};"])
}

# Reverse Proxy SG — 외부 사용자 트래픽의 유일한 진입점
resource "aws_security_group" "reverse_proxy" {
  name        = "${var.name}-reverse-proxy-sg"
  description = "Security group for reverse proxy"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-reverse-proxy-sg"
  }
}

resource "aws_instance" "reverse_proxy" {
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_pair_name
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = [aws_security_group.reverse_proxy.id]

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx

    # 외부 80 트래픽을 worker의 Ingress NodePort로 포워딩
    cat > /etc/nginx/conf.d/reverse-proxy.conf <<'NGINX'
    upstream ingress_backend {
        ${local.upstream_servers}
    }
    server {
        listen 80 default_server;

        location / {
            proxy_pass http://ingress_backend;
            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    NGINX

    # 기본 default 서버 비활성화(80 포트 충돌 방지)
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    systemctl enable nginx
    systemctl restart nginx
  EOT

  tags = {
    Name = "${var.name}-reverse-proxy"
  }
}
