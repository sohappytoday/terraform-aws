output "instance_id" {
  value       = module.worker_node.instance_id
  description = "생성된 EC2 인스턴스 ID"
}

output "public_ip" {
  value       = module.worker_node.public_ip
  description = "EC2 인스턴스 Public IP"
}

output "private_ip" {
  value       = module.worker_node.private_ip
  description = "EC2 인스턴스 Private IP"
}

output "ami_id" {
  value       = module.worker_node.ami_id
  description = "EC2 인스턴스 AMI"
}