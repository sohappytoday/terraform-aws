output "instance_id" {
  value       = aws_instance.reverse_proxy.id
  description = "Reverse Proxy 인스턴스 ID"
}

output "public_ip" {
  value       = aws_instance.reverse_proxy.public_ip
  description = "Reverse Proxy Public IP (외부 사용자 진입점)"
}

output "security_group_id" {
  value       = aws_security_group.reverse_proxy.id
  description = "Reverse Proxy Security Group ID"
}
