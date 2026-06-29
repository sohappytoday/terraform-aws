output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_id
  description = "퍼블릭 서브넷 ID (control-plane)"
}

output "private_subnet_id" {
  value       = module.vpc.private_subnet_id
  description = "프라이빗 서브넷 ID (worker-node)"
}

output "worker_node_instance_ids" {
  value       = { for k, v in module.worker_node : k => v.instance_id }
  description = "worker-node별 EC2 인스턴스 ID"
}

output "worker_node_public_ips" {
  value       = { for k, v in module.worker_node : k => v.public_ip }
  description = "worker-node별 Public IP"
}

output "worker_node_private_ips" {
  value       = { for k, v in module.worker_node : k => v.private_ip }
  description = "worker-node별 Private IP"
}

output "control_plane_instance_ids" {
  value       = { for k, v in module.control_plane : k => v.instance_id }
  description = "control-plane별 EC2 인스턴스 ID"
}

output "control_plane_public_ips" {
  value       = { for k, v in module.control_plane : k => v.public_ip }
  description = "control-plane별 Public IP"
}

output "control_plane_private_ips" {
  value       = { for k, v in module.control_plane : k => v.private_ip }
  description = "control-plane별 Private IP"
}

output "control_plane_endpoint" {
  value       = module.nlb.dns_name
  description = "내부 NLB DNS 이름. kubeadm --control-plane-endpoint 로 사용하는 apiserver 단일 엔드포인트"
}

output "ssh_user" {
  value       = var.ssh_user
  description = "EC2 SSH 접속 사용자"
}

output "nat_instance_id" {
  value       = module.nat.instance_id
  description = "NAT 인스턴스 ID"
}

output "nat_public_ip" {
  value       = module.nat.public_ip
  description = "NAT 인스턴스 Public IP"
}

output "reverse_proxy_instance_id" {
  value       = module.reverse_proxy.instance_id
  description = "Reverse Proxy 인스턴스 ID"
}

output "reverse_proxy_public_ip" {
  value       = module.reverse_proxy.public_ip
  description = "Reverse Proxy Public IP (외부 사용자 진입점)"
}
