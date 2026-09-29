resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventory/hosts.ini"

  content = templatefile("${path.module}/inventory.tftpl", {
    jenkins_master_ip = aws_instance.this["jenkins-master"].private_ip
    jenkins_agent_ip  = aws_instance.this["jenkins-agent"].private_ip
  })

  file_permission = "0644"
}

resource "null_resource" "push_inventory" {
  triggers = {
    inventory_hash = local_file.ansible_inventory.content_sha256
    controller_ip  = aws_instance.this["ansible-controller"].public_ip
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e
      for attempt in 1 2 3 4 5 6; do
        scp \
          -o StrictHostKeyChecking=accept-new \
          -o UserKnownHostsFile=/dev/null \
          -o ConnectTimeout=10 \
          -i ${pathexpand(var.ssh_private_key_path)} \
          ${local_file.ansible_inventory.filename} \
          ubuntu@${aws_instance.this["ansible-controller"].public_ip}:/home/ubuntu/hosts.ini && exit 0
        echo "scp attempt $attempt failed - waiting 10s for sshd..."
        sleep 10
      done
      exit 1
    BASH
  }
}
