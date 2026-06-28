variable "name" {
  type        = string
  description = "리소스 이름 prefix"
}

variable "vpc_id" {
  type        = string
  description = "보안 그룹을 생성할 VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Reverse Proxy를 배치할 Public Subnet ID"
}

variable "instance_type" {
  type        = string
  description = "Reverse Proxy 인스턴스 타입 (free-tier 가능 타입)"
  default     = "t3.micro"
}

variable "key_pair_name" {
  type        = string
  description = "연결할 키 페어 이름. null이면 미연결"
  default     = null
}

variable "iam_instance_profile" {
  type        = string
  description = "연결할 IAM 인스턴스 프로파일 (SSM 디버깅용). null이면 미연결"
  default     = null
}

variable "upstream_ips" {
  type        = list(string)
  description = "포워딩 대상 백엔드(worker) private IP 목록"
}

variable "ingress_nodeport" {
  type        = number
  description = "worker에서 Ingress Controller가 노출되는 NodePort. 이 포트로 포워딩한다"
  default     = 30080
}
