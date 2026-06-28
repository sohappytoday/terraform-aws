output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "퍼블릭 서브넷 ID (control-plane)"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "프라이빗 서브넷 ID (worker-node)"
}

output "vpce_security_group_id" {
  value       = aws_security_group.vpce.id
  description = "SSM Interface Endpoint에 연결된 Security Group ID"
}
