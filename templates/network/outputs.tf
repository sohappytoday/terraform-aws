output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_id
  description = "퍼블릭 서브넷 ID"
}

output "key_name" {
  value       = aws_key_pair.this.key_name
  description = "공용 키 페어 이름"
}
