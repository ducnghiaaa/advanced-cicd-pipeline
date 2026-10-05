# Jenkins agent sits in a public subnet; from inside the VPC the EKS API
# hostname resolves to the private endpoint ENI (10.60.10.x), whose SG by
# default only accepts 443 from the node SG. Open 443 from the Jenkins agent
# SG so the pipeline Deploy stage can reach the API.
data "aws_security_group" "jenkins_agent" {
  filter {
    name   = "group-name"
    values = ["p06-jenkins-agent"]
  }

  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_jenkins_agent" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = data.aws_security_group.jenkins_agent.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Jenkins agent to EKS API"
}
