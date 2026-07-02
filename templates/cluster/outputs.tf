output "cluster_public_ip" {
  value       = module.cluster.public_ip
  description = "단일 클러스터 노드 Public IP"
}

output "cluster_private_ip" {
  value       = module.cluster.private_ip
  description = "단일 클러스터 노드 Private IP"
}
