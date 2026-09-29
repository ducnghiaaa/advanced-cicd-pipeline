# Architecture (AWS) — pip install diagrams ; brew install graphviz ; python architecture.py
from diagrams import Cluster, Diagram, Edge, Node
from diagrams.aws.compute import EC2, ECR, EKS
from diagrams.aws.integration import EventbridgeScheduler
from diagrams.aws.management import SystemsManager
from diagrams.aws.network import ELB, InternetGateway, NATGateway
from diagrams.aws.security import IAMRole, KMS
from diagrams.aws.storage import S3
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import User, Users
from diagrams.onprem.iac import Terraform
from diagrams.onprem.network import Internet
from diagrams.onprem.vcs import Github

TF  = dict(color="#7B42BC", penwidth="2.5")
IMG = dict(color="#E8710A", penwidth="2")
DEP = dict(color="#1E8E3E", penwidth="2")
NET = dict(color="#1A73E8", penwidth="1.8")
OPS = dict(color="#5F6368", style="dotted")
INV = dict(style="invis")

def note(text, fill="#FFF8DC", border="#C9B458"):
    return Node(text, shape="note", style="filled", fillcolor=fill, color=border,
                fontsize="13", fixedsize="false", margin="0.25,0.15")

graph_attr = {"fontsize": "28", "pad": "0.6", "nodesep": "0.5", "ranksep": "1.0", "labelloc": "t"}

with Diagram("Project Architecture on AWS", filename="architecture", show=False,
             direction="LR", graph_attr=graph_attr):

    with Cluster("Infrastructure as Code"):
        gha = GithubActions("GitHub Actions\nplan on PR · apply on approval")
        tf = Terraform("Terraform · 5 stacks\nbootstrap · network · registry\ncompute · eks")

    admin = User("Admin (you)")
    github = Github("GitHub")
    users = Users("End users")
    internet = Internet("Internet")

    with Cluster("AWS Cloud · ap-southeast-1"):

        with Cluster("VPC 10.60.0.0/16   [tf: network]"):
            igw = InternetGateway("Internet Gateway")

            with Cluster("AZ ap-southeast-1a"):
                with Cluster("Public subnet 10.60.0.0/24   [tf: compute]"):
                    ansible = EC2("Ansible controller")
                    master = EC2("Jenkins master\nElastic IP")
                    agent = EC2("Jenkins agent")
                    nat = NATGateway("NAT Gateway\n(single, EIP)")
                with Cluster("Private subnet 10.60.10.0/24   [tf: eks]"):
                    node_a = EKS("Worker node")

            with Cluster("AZ ap-southeast-1b"):
                with Cluster("Public subnet 10.60.1.0/24"):
                    elb = ELB("Load Balancer\nK8s Service type=LoadBalancer\n(ENIs in both public subnets)")
                with Cluster("Private subnet 10.60.11.0/24   [tf: eks]"):
                    node_b = EKS("Worker node")

        with Cluster("AWS-managed services   [tf: registry · eks]"):
            eks_cp = EKS("EKS control plane")
            ecr = ECR("ECR\nIMMUTABLE · scan on push")

        with Cluster("Security & Ops   [tf: bootstrap · compute]"):
            iam = IAMRole("IAM\nOIDC + instance roles")
            kms = KMS("KMS\n(AWS-managed keys)")
            s3 = S3("S3 tfstate\nversioning · lockfile")
            ssm = SystemsManager("SSM\nSession Manager")
            sched = EventbridgeScheduler("EventBridge\nauto-stop EC2 23:30")
            iam - Edge(**INV) - kms
            s3 - Edge(**INV) - ssm
            sched - Edge(**INV) - kms

    security = note("Security controls\l"
                    "• No static AWS keys: GitHub OIDC + EC2 instance roles\l"
                    "• IMDSv2 · encrypted EBS · KMS for S3 state & ECR\l"
                    "• SG least-privilege: :22 admin IP → controller only\l"
                    "• Jenkins :8080 only from admin IP + GitHub hooks\l"
                    "• Break-glass access via SSM Session Manager\l")
    tradeoff = note("Lab trade-offs\l"
                    "• 1 NAT GW (AZ-1a): saves cost, but cross-AZ traffic\l"
                    "  and single point of failure for AZ-1b egress\l"
                    "• Prod: 1 NAT per AZ + VPC endpoints (ECR, S3, STS)\l"
                    "• Jenkins over HTTP (no TLS yet)\l", fill="#FCE8E6", border="#D93025")
    legend = note("Legend\l"
                  "purple  Terraform (IaC)\l"
                  "blue    network path (ingress / egress)\l"
                  "orange  container image\l"
                  "green   deploy to EKS\l"
                  "dotted  ops / admin access\l", fill="#F1F3F4", border="#9AA0A6")

    # IaC
    gha >> Edge(label="runs", **TF) >> tf
    tf >> Edge(label="OIDC assume role", **TF) >> iam
    tf >> Edge(label="state + lock", **TF) >> s3
    tf >> Edge(label="terraform apply → every [tf: …] box", style="bold", **TF) >> igw

    # Ingress
    users >> Edge(label="HTTP", **NET) >> internet
    github >> Edge(label="webhook", **NET) >> internet
    internet >> Edge(**NET) >> igw
    igw >> Edge(label=":8080 webhook", **NET) >> master
    igw >> Edge(label="HTTP", **NET) >> elb
    elb >> Edge(**NET) >> node_a
    elb >> Edge(**NET) >> node_b

    # Egress of private subnets: node -> NAT (public) -> IGW -> Internet
    node_a >> Edge(label="egress 0.0.0.0/0", style="dashed", **NET) >> nat
    node_b >> Edge(label="egress (cross-AZ)", style="dashed", **NET) >> nat
    nat >> Edge(label="0.0.0.0/0 → IGW", style="dashed", constraint="false", **NET) >> igw

    # CI/CD (chi tiết: cicd_workflow.png)
    master >> Edge(label="SSH launch") >> agent
    agent >> Edge(label="docker push", **IMG) >> ecr
    agent >> Edge(label="kubectl apply", **DEP) >> eks_cp
    eks_cp >> Edge(label="schedule pods", **DEP) >> node_a
    eks_cp >> Edge(**DEP) >> node_b
    ecr >> Edge(label="pull image (via NAT)", style="dashed", **IMG) >> node_b

    # Ops
    admin >> Edge(label="ssh -A (admin IP)", **OPS) >> ansible
    ansible >> Edge(label="Ansible", **OPS) >> master
    ansible >> Edge(**OPS) >> agent
    ssm >> Edge(label="session", **OPS) >> ansible

    security - Edge(**INV) - tradeoff - Edge(**INV) - legend