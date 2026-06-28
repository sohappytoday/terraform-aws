output "instance_id" {
  value       = aws_instance.nat.id
  description = "NAT 인스턴스 ID"
}

output "network_interface_id" {
  value       = aws_instance.nat.primary_network_interface_id
  description = "NAT 인스턴스 기본 ENI ID (Private 라우트 테이블의 타겟으로 사용)"
}

output "public_ip" {
  value       = aws_instance.nat.public_ip
  description = "NAT 인스턴스 Public IP"
}

output "security_group_id" {
  value       = aws_security_group.nat.id
  description = "NAT 인스턴스 Security Group ID"
}
