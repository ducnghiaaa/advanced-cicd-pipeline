output "controller_public_ip" {
  description = "Public IP of the Ansible controller — SSH into it to run playbooks."
  value       = aws_instance.this["ansible-controller"].public_ip
}

output "jenkins_url" {
  description = "URL of the Jenkins master UI (stable across stop/start via EIP)."
  value       = "http://${aws_eip.jenkins_master.public_ip}:8080"
}

output "ssh_command" {
  description = "One-liner to SSH into the controller with agent forwarding."
  value       = "ssh -A ubuntu@${aws_instance.this["ansible-controller"].public_ip}"
}

# Consumed by the EKS stack: the access entry maps this role to K8s RBAC, and
# the eks:DescribeCluster policy is attached to it there (not here) so that
# tearing down the EKS stack alone also removes the permission.
output "jenkins_agent_role_arn" {
  description = "ARN of the Jenkins agent EC2 role."
  value       = aws_iam_role.jenkins_agent.arn
}

output "jenkins_agent_role_name" {
  description = "Name of the Jenkins agent EC2 role."
  value       = aws_iam_role.jenkins_agent.name
}
