# Jenkins 서버 (클러스터 외 standalone). network state와 독립적으로 올리고 내린다.

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
  description = "Jenkins 인스턴스 타입"
  default     = "c7i-flex.large"
}

variable "my_ip" {
  type        = string
  description = "SSH(22)와 Jenkins UI 접속을 허용할 관리자 IP (CIDR 표기)"
  default     = "211.244.114.134/32"
}

variable "root_volume_size" {
  type        = number
  description = "Jenkins 루트 볼륨 크기 (GB). 빌드 워크스페이스/아티팩트 여유분 포함"
  default     = 30
}

variable "root_volume_type" {
  type        = string
  description = "Jenkins 루트 볼륨 타입"
  default     = "gp3"
}

variable "jenkins_port" {
  type        = number
  description = "Jenkins 웹 UI 및 GitHub webhook 수신 포트"
  default     = 8080
}
