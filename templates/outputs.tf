output "instance_id" {
  value = aws_instance.my_ec2.id
  description = "생성된 EC2 인스턴스 ID"
}
output "public_ip" {
  value       = aws_instance.my_ec2.public_ip
  description = "EC2 인스턴스 Public IP"
}

output "private_ip" {
  value       = aws_instance.my_ec2.private_ip
  description = "EC2 인스턴스 Private IP"
}

output "ami_id" {
  value       = aws_instance.my_ec2.ami
  description = "EC2 인스턴스 AMI"
}