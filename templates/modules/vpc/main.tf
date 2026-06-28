resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.name}-private-subnet"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------
# SSM VPC Interface Endpoint
# Private Subnet의 인스턴스가 NAT/IGW 없이 AWS 내부망으로 SSM에 접근하도록 한다.
# Session Manager에는 ssm, ssmmessages, ec2messages 3종이 필요하다.
# 서비스명(com.amazonaws.<region>.<service>)은 data source로 자동 해석한다.
# -----------------------------------------------

data "aws_vpc_endpoint_service" "ssm" {
  service = "ssm"
}

data "aws_vpc_endpoint_service" "ssmmessages" {
  service = "ssmmessages"
}

data "aws_vpc_endpoint_service" "ec2messages" {
  service = "ec2messages"
}

locals {
  ssm_endpoint_service_names = {
    ssm         = data.aws_vpc_endpoint_service.ssm.service_name
    ssmmessages = data.aws_vpc_endpoint_service.ssmmessages.service_name
    ec2messages = data.aws_vpc_endpoint_service.ec2messages.service_name
  }
}

# 엔드포인트 ENI에 붙는 SG. VPC 내부에서 오는 HTTPS(443)만 허용한다.
resource "aws_security_group" "vpce" {
  name        = "${var.name}-vpce-sg"
  description = "Allow HTTPS from VPC to SSM interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-vpce-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = local.ssm_endpoint_service_names

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name}-${each.key}-endpoint"
  }
}
