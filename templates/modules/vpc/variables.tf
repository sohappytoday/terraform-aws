variable "name" {
  type        = string
  description = "리소스 이름 prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR 블록"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "퍼블릭 서브넷 CIDR 블록 (control-plane)"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "프라이빗 서브넷 CIDR 블록 (worker-node)"
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  type        = string
  description = "서브넷을 생성할 가용 영역"
  default     = "ap-northeast-2a"
}
