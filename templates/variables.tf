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
  default     = "ap-northeast-2a"
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

variable "control_plane_instance_name" {
  type        = string
  description = "control-plane EC2 인스턴스 이름"
}

variable "control_plane_instance_type" {
  type        = string
  description = "control-plane EC2 인스턴스 타입"
  default     = "t3.medium"
}

variable "control_plane_root_volume_size" {
  type        = number
  description = "control-plane 루트 볼륨 크기 (GB)"
  default     = 30
}

variable "control_plane_root_volume_type" {
  type        = string
  description = "control-plane 루트 볼륨 타입"
  default     = "gp3"
}

variable "control_plane_ssh_allowed_cidr" {
  type        = list(string)
  description = "control-plane SSH 허용 CIDR 목록"
}

variable "control_plane_ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "control-plane 추가 인바운드 규칙 목록 (SSH 제외)"
  default     = []
}