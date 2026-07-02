output "jenkins_public_ip" {
  value       = module.jenkins.public_ip
  description = "Jenkins 서버 Public IP"
}

output "jenkins_private_ip" {
  value       = module.jenkins.private_ip
  description = "Jenkins 서버 Private IP"
}
