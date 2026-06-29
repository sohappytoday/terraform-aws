variable "name" {
  type        = string
  description = "리소스 이름 prefix (클러스터 이름)"
}

variable "vpc_id" {
  type        = string
  description = "Target Group을 생성할 VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "NLB를 배치할 서브넷 ID 목록. control-plane이 있는 private subnet."
}

variable "instance_ids" {
  type        = map(string)
  description = "Target Group에 등록할 control-plane 인스턴스 ID 맵 (키=노드 식별자)"
}

variable "apiserver_port" {
  type        = number
  description = "Kubernetes apiserver 포트"
  default     = 6443
}
