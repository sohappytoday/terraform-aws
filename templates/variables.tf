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

# VPC 생성 후 사용
# variable "subnet_id" {
#   type        = string
#   description = "EC2를 배치할 서브넷 ID"
# }

# variable "vpc_security_group_ids" {
#   type        = list(string)
#   description = "EC2에 적용할 보안 그룹 ID 목록"
# }

# variable "key_name" {
#   type        = string
#   description = "SSH 접속에 사용할 키페어 이름"
# }