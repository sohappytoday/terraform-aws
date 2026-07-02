# 단일 노드 클러스터 (control-plane). network state와 독립적으로 올리고 내린다.

variable "cluster_name" {
  type        = string
  description = "리소스 이름 prefix"
  default     = "cardinal-staging"
}

variable "region" {
  type        = string
  description = "리소스를 생성할 AWS 리전"
  default     = "ap-northeast-2"
}

variable "instance_type" {
  type        = string
  description = "클러스터 노드 인스턴스 타입"
  default     = "c7i-flex.large"
}

variable "my_ip" {
  type        = string
  description = "SSH(22) 접속을 허용할 관리자 IP (CIDR 표기)"
  default     = "211.244.114.134/32"
}

variable "root_volume_size" {
  type        = number
  description = "클러스터 노드 루트 볼륨 크기 (GB)"
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "클러스터 노드 루트 볼륨 타입"
  default     = "gp3"
}

# 단일 노드 클러스터가 외부로 노출하는 포트.
# 80/443: Ingress, 32339: ArgoCD NodePort, 32340: 서비스 NodePort. 모두 0.0.0.0/0 허용.
variable "service_ports" {
  type        = list(number)
  description = "클러스터 노드에서 전체(0.0.0.0/0)로 여는 서비스 포트 목록"
  default     = [80, 443, 32339, 32340]
}
