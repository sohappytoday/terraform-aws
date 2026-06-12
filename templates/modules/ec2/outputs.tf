output "instance_id" {
  value       = aws_instance.this.id
  description = "생성된 EC2 인스턴스 ID"
}

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "EC2 인스턴스 Public IP"
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "EC2 인스턴스 Private IP"
}

output "ami_id" {
  value       = aws_instance.this.ami
  description = "EC2 인스턴스 AMI"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "EC2 인스턴스에 연결된 Security Group ID"
}
