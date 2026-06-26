# -----------------------------------------------
# VPC
# -----------------------------------------------

variable "cluster_name" {
  type        = string
  description = "클러스터 이름. VPC, Subnet 등 리소스 이름 prefix로 사용"
  default     = "k8s"
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
  # c7i-flex.large 미지원
  # default     = "ap-northeast-2a"
  default = "ap-northeast-2b"
}

# -----------------------------------------------
# EC2 공통
# -----------------------------------------------

variable "ssh_user" {
  type        = string
  description = "EC2 인스턴스에 SSH 접속할 기본 사용자 (AMI에 따라 다름: ubuntu, ec2-user, rocky 등)"
  default     = "ubuntu"
}

# -----------------------------------------------
# EC2 (worker-node)
# -----------------------------------------------

variable "worker_nodes" {
  type = map(object({
    instance_type    = string
    instance_name    = string
    root_volume_size = number
    root_volume_type = string
  }))
  description = "worker-node 목록. 키는 노드 식별자, 값은 노드별 사양"
}

variable "worker_key_pair_name" {
  type        = string
  description = "모든 worker-node가 공유할 키 페어 이름"
}

variable "public_key_path" {
  type        = string
  description = "로컬에 저장된 SSH 공개키(.pub) 파일 경로"
}

# -----------------------------------------------
# EC2 (control-plane)
# -----------------------------------------------

variable "control_plane_nodes" {
  type = map(object({
    instance_type    = string
    instance_name    = string
    root_volume_size = number
    root_volume_type = string
  }))
  description = "control-plane 노드 목록. 키는 노드 식별자(hostname), 값은 노드별 사양. HA 확장 시 항목 추가"
}

variable "control_plane_ssh_allowed_cidr" {
  type        = list(string)
  description = "control-plane SSH 허용 CIDR 목록"
}

