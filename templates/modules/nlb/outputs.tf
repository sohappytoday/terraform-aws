output "dns_name" {
  value       = aws_lb.this.dns_name
  description = "내부 NLB의 DNS 이름. kubeadm --control-plane-endpoint 로 사용."
}

output "target_group_arn" {
  value       = aws_lb_target_group.apiserver.arn
  description = "apiserver Target Group ARN"
}
