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