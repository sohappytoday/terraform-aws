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
  description = "control-plane SSH 허용 CIDR 목록. Private 이동 후에는 SSM으로만 접근하므로 빈 목록을 권장"
  default     = []
}

variable "apiserver_port" {
  type        = number
  description = "Kubernetes apiserver 포트. 내부 NLB listener/target group과 control-plane SG 허용에 사용"
  default     = 6443
}

# -----------------------------------------------
# NAT 인스턴스
# -----------------------------------------------

variable "nat_instance_type" {
  type        = string
  description = "NAT 인스턴스 타입. 패킷 포워딩만 하므로 작은 타입으로 충분하나, 이 계정은 free-tier 가능 타입만 허용해 t3.micro 사용"
  default     = "t3.micro"
}

# -----------------------------------------------
# Reverse Proxy
# -----------------------------------------------

variable "reverse_proxy_instance_type" {
  type        = string
  description = "Reverse Proxy 인스턴스 타입 (free-tier 가능 타입)"
  default     = "t3.micro"
}

variable "ingress_nodeport" {
  type        = number
  description = "worker에서 Ingress Controller가 노출되는 NodePort. Reverse Proxy가 이 포트로 포워딩"
  default     = 30080
}

# -----------------------------------------------
# Network ACL (Public Subnet)
# -----------------------------------------------

variable "blocked_cidrs" {
  type        = list(string)
  description = "Public Subnet에서 차단할 악성 출처 CIDR 목록. Security Group은 deny를 지원하지 않아 특정 IP를 막을 수 없으므로 NACL에서 deny한다. 예: [\"203.0.113.10/32\"]"
  default     = []
}

