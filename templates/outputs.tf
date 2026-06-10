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

output "control_plane_public_ip" {
  value       = module.control_plane.public_ip
  description = "control-plane Public IP"
}

output "control_plane_private_ip" {
  value       = module.control_plane.private_ip
  description = "control-plane Private IP"
}
