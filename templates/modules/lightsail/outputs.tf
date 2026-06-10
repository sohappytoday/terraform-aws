output "instance_id" {
  value       = aws_lightsail_instance.this.id
  description = "생성된 Lightsail 인스턴스 ID"
}

output "public_ip" {
  value       = aws_lightsail_instance.this.public_ip_address
  description = "Lightsail 인스턴스 Public IP"
}

output "private_ip" {
  value       = aws_lightsail_instance.this.private_ip_address
  description = "Lightsail 인스턴스 Private IP"
}
