resource "aws_key_pair" "deployer" {
  key_name   = "p06-deployer"
  public_key = var.ssh_public_key
}

locals {
  user_data_controller = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ansible python3 python3-pip git jq
  EOT

  nodes = {
    ansible-controller = {
      type      = "t3.micro"
      disk      = 20
      sg        = aws_security_group.controller.id
      profile   = aws_iam_instance_profile.controller.name
      user_data = local.user_data_controller
      role      = "ansible_controller"
    }
    jenkins-master = {
      type      = "t3.medium"
      disk      = 30
      sg        = aws_security_group.jenkins_master.id
      profile   = aws_iam_instance_profile.jenkins_master.name
      user_data = null
      role      = "jenkins_master"
    }
    jenkins-agent = {
      type      = "t3.medium"
      disk      = 40
      sg        = aws_security_group.jenkins_agent.id
      profile   = aws_iam_instance_profile.jenkins_agent.name
      user_data = null
      role      = "jenkins_agent"
    }
  }
}

resource "aws_instance" "this" {
  for_each = local.nodes

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.type
  subnet_id                   = data.aws_subnets.public.ids[0]
  vpc_security_group_ids      = [each.value.sg]
  iam_instance_profile        = each.value.profile
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = each.value.user_data
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = each.value.disk
    encrypted   = true
  }

  tags = {
    Name = "p06-${each.key}"
    Role = each.value.role
  }

  lifecycle {
    ignore_changes = [ami, associate_public_ip_address]
  }
}
