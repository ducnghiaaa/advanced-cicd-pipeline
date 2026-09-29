resource "aws_eip" "jenkins_master" {
  domain = "vpc"

  tags = {
    Name = "p06-jenkins-master"
  }
}

resource "aws_eip_association" "jenkins_master" {
  allocation_id = aws_eip.jenkins_master.id
  instance_id   = aws_instance.this["jenkins-master"].id
}
