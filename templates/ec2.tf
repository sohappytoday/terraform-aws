# 리소스 정의 (ubuntu 22.04)
data "aws_ami" "ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 리소스 정의 (ubuntu 24.04)
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 리소스 정의 (rocky 9.7)
data "aws_ami" "rocky_9" {
  most_recent = true
  owners      = ["648152685816"] # Rocky

  filter {
    name   = "name"
    values = ["Rocky-9.7*-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 리소스 정의 (rocky 8.10)
data "aws_ami" "rocky_8" {
  most_recent = true
  owners      = ["648152685816"] # Rocky

  filter {
    name   = "name"
    values = ["Rocky-8.10*-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 리소스 정의 (amazon linux 2023)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ec2 인스턴스 생성
resource "aws_instance" "my_ec2" {
  ami           = data.aws_ami.ubuntu_24.id
  instance_type = "t2.micro"

  tags = {
    Name = "test-ec2"
  }
}
