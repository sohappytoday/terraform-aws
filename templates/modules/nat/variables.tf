variable "name" {
  type        = string
  description = "리소스 이름 prefix"
}

variable "vpc_id" {
  type        = string
  description = "NAT 인스턴스 보안 그룹을 생성할 VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "NAT 인스턴스를 배치할 Public Subnet ID"
}

variable "instance_type" {
  type        = string
  description = "NAT 인스턴스 타입. NAT는 패킷 포워딩만 하므로 작은 타입으로 충분"
  default     = "t3.micro"
}

variable "private_subnet_cidr" {
  type        = string
  description = "NAT를 경유할 Private Subnet CIDR. 이 대역에서 오는 트래픽만 NAT 인스턴스로 허용"
}

variable "key_pair_name" {
  type        = string
  description = "NAT 인스턴스에 연결할 키 페어 이름. null이면 미연결"
  default     = null
}

variable "iam_instance_profile" {
  type        = string
  description = "NAT 인스턴스에 연결할 IAM 인스턴스 프로파일 (SSM 디버깅용). null이면 미연결"
  default     = null
}
