variable "instance_name" {
  type        = string
  description = "Lightsail 인스턴스 이름"
}

variable "availability_zone" {
  type        = string
  description = "인스턴스를 생성할 가용 영역 (예: ap-northeast-2a)"
}

variable "blueprint_id" {
  type        = string
  description = "OS 이미지 ID (예: ubuntu_22_04)"
  default     = "ubuntu_22_04"
}

variable "bundle_id" {
  type        = string
  description = "인스턴스 사양 번들 ID (예: small_3_0 = 2GB RAM, 1vCPU)"
  default     = "small_3_0"
}

variable "key_pair_name" {
  type        = string
  description = "Lightsail에 등록할 키 페어 이름"
}

variable "public_key_path" {
  type        = string
  description = "로컬에 저장된 SSH 공개키(.pub) 파일 경로"
}

variable "ip_address_type" {
  type        = string
  description = "IP 주소 유형 (dualstack, ipv4, ipv6)"
  default     = "dualstack"
}

variable "port_rules" {
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    cidrs     = list(string)
  }))
  description = "개방할 포트 규칙 목록"
  default = [
    {
      protocol  = "tcp"
      from_port = 22
      to_port   = 22
      cidrs     = ["0.0.0.0/0"]
    },
    {
      protocol  = "tcp"
      from_port = 80
      to_port   = 80
      cidrs     = ["0.0.0.0/0"]
    },
    {
      protocol  = "tcp"
      from_port = 443
      to_port   = 443
      cidrs     = ["0.0.0.0/0"]
    }
  ]
}
