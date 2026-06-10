# -----------------------------------------------
# EC2 (worker-node)
# -----------------------------------------------

variable "worker_nodes" {
  type = map(object({
    instance_type    = string
    instance_name    = string
    root_volume_size = number
    root_volume_type = string
    key_pair_name    = string
  }))
  description = "worker-node 목록. 키는 노드 식별자, 값은 노드별 사양"
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

variable "lightsail_key_pair_name" {
  type        = string
  description = "Lightsail에 등록할 키 페어 이름"
}

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