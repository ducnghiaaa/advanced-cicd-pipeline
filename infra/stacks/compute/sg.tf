resource "aws_security_group" "controller" {
  name        = "p06-controller"
  description = "Ansible controller - SSH from admin CIDRs only."
  vpc_id      = data.aws_vpc.p06.id
}

resource "aws_security_group" "jenkins_master" {
  name        = "p06-jenkins-master"
  description = "Jenkins master - SSH from controller, HTTP 8080 from admins and GitHub webhooks."
  vpc_id      = data.aws_vpc.p06.id
}

resource "aws_security_group" "jenkins_agent" {
  name        = "p06-jenkins-agent"
  description = "Jenkins agent - SSH from controller and master only."
  vpc_id      = data.aws_vpc.p06.id
}

# ---------------------------------------------------------------------------
# Controller ingress
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "controller_ssh_admin" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.controller.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from admin CIDR"
}

# ---------------------------------------------------------------------------
# Jenkins master ingress
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "master_ssh_from_controller" {
  security_group_id            = aws_security_group.jenkins_master.id
  referenced_security_group_id = aws_security_group.controller.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from Ansible controller"
}

resource "aws_vpc_security_group_ingress_rule" "master_http_admin" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.jenkins_master.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  description       = "Jenkins UI from admin CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "master_http_github" {
  for_each = toset(local.github_hook_cidrs)

  security_group_id = aws_security_group.jenkins_master.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  description       = "GitHub webhook"
}

# ---------------------------------------------------------------------------
# Jenkins agent ingress
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "agent_ssh_from_controller" {
  security_group_id            = aws_security_group.jenkins_agent.id
  referenced_security_group_id = aws_security_group.controller.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from Ansible controller"
}

resource "aws_vpc_security_group_ingress_rule" "agent_ssh_from_master" {
  security_group_id            = aws_security_group.jenkins_agent.id
  referenced_security_group_id = aws_security_group.jenkins_master.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from Jenkins master (agent launch)"
}

# ---------------------------------------------------------------------------
# Egress — unrestricted for all three (needed for apt / ECR / GitHub / SSM)
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "controller_all" {
  security_group_id = aws_security_group.controller.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All egress"
}

resource "aws_vpc_security_group_egress_rule" "master_all" {
  security_group_id = aws_security_group.jenkins_master.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All egress"
}

resource "aws_vpc_security_group_egress_rule" "agent_all" {
  security_group_id = aws_security_group.jenkins_agent.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All egress"
}
