# 공용 베이스: Jenkins/cluster가 공유하는 VPC와 키페어.
# 이 state는 한 번 올리면 계속 유지되며, jenkins/cluster는 여기 출력을 remote_state로 읽는다.

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

variable "availability_zone" {
  type        = string
  description = "서브넷을 배치할 가용 영역. c7i-flex.large는 ap-northeast-2a 미지원이라 2b 사용"
  default     = "ap-northeast-2b"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR 블록"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "퍼블릭 서브넷 CIDR 블록. Jenkins와 클러스터 노드 모두 여기에 배치"
  default     = "10.0.1.0/24"
}

variable "key_pair_name" {
  type        = string
  description = "AWS에 등록할 키 페어 이름"
  default     = "test-cardinal-staging"
}

variable "public_key_path" {
  type        = string
  description = "로컬 SSH 공개키(.pub) 경로"
  default     = "/home/kgeo6/.ssh/test-cardinal-staging.pub"
}
