# -----------------------------------------------
# EC2 (worker-node)
# -----------------------------------------------

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the web server"
  default     = "t3.micro"
}

variable "instance_name" {
  type        = string
  description = "EC2 인스턴스 이름 태그"
  default     = "test-ec2"
}

variable "root_volume_size" {
  type        = number
  description = "루트 볼륨 크기 (GB)"
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "루트 볼륨 타입 (gp2, gp3, io1 등)"
  default     = "gp3"
}

variable "key_pair_name" {
  type        = string
  description = "AWS에 등록할 키 페어 이름"
}

variable "public_key_path" {
  type        = string
  description = "로컬에 저장된 SSH 공개키(.pub) 파일 경로"
}

variable "ssh_allowed_cidr" {
  type        = list(string)
  description = "SSH(22번 포트) 접속을 허용할 CIDR 대역 목록"
}

variable "ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "보안 그룹에 추가로 열어줄 인바운드 규칙 목록 (SSH 제외)"
  default = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# VPC 생성 후 사용
# variable "subnet_id" {
#   type        = string
#   description = "EC2를 배치할 서브넷 ID"
# }

# -----------------------------------------------
# Lightsail (control-plane)
# -----------------------------------------------

variable "lightsail_instance_name" {
  type        = string
  description = "Lightsail 인스턴스 이름"
  default     = "control-plane"
}

variable "lightsail_availability_zone" {
  type        = string
  description = "Lightsail 인스턴스 가용 영역 (예: ap-northeast-2a)"
  default     = "ap-northeast-2a"
}

variable "lightsail_blueprint_id" {
  type        = string
  description = "OS 이미지 ID (예: ubuntu_22_04)"
  default     = "ubuntu_22_04"
}

variable "lightsail_bundle_id" {
  type        = string
  description = "인스턴스 사양 번들 ID (예: small_3_0 = 2GB RAM, 1vCPU)"
  default     = "small_3_0"
}

variable "lightsail_ip_address_type" {
  type        = string
  description = "IP 주소 유형 (dualstack, ipv4, ipv6)"
  default     = "dualstack"
}

variable "lightsail_port_rules" {
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    cidrs     = list(string)
  }))
  description = "Lightsail 개방할 포트 규칙 목록"
  default     = []
}