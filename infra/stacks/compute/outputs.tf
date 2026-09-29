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
