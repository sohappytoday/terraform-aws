variable "instance_type" {
  type        = string
  description = "EC2 instance type"
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
  description = "루트 볼륨 타입"
  default     = "gp3"
}

variable "key_pair_name" {
  type        = string
  description = "AWS에 등록할 키 페어 이름"
}

variable "ssh_allowed_cidr" {
  type        = list(string)
  description = "SSH 접속을 허용할 CIDR 대역 목록. 비어있으면 SSH 규칙을 생성하지 않음"
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "보안 그룹을 생성할 VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "EC2 인스턴스를 배치할 서브넷 ID"
}

variable "user_data" {
  type        = string
  description = "인스턴스 초기화 스크립트"
  default     = ""
}

variable "iam_instance_profile" {
  type        = string
  description = "EC2에 연결할 IAM 인스턴스 프로파일 이름 (SSM 접근 등). null이면 미연결"
  default     = null
}
