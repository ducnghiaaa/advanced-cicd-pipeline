#!/usr/bin/env bash
#
# Manage the advanced-cicd lab fleet: start | stop | status.
# Instances are discovered by tag Project=advanced-cicd - no hardcoded IDs.
#
# Usage:
#   scripts/lab.sh start
#   scripts/lab.sh stop
#   scripts/lab.sh status
#
# Env overrides:
#   AWS_PROFILE (default: devops-p06)
#   AWS_REGION  (default: ap-southeast-1)

set -euo pipefail

readonly PROJECT_TAG="advanced-cicd"
readonly PROFILE="${AWS_PROFILE:-devops-p06}"
readonly REGION="${AWS_REGION:-ap-southeast-1}"

usage() {
  cat >&2 <<EOF
Usage: $0 {start|stop|status}

  start   Start every stopped instance tagged Project=$PROJECT_TAG, wait until running,
          print controller SSH command and Jenkins URL.
  stop    Stop every running instance tagged Project=$PROJECT_TAG, wait until stopped.
  status  Print a table of Name / State / PublicIp.
EOF
  exit 2
}

aws_() {
  aws --profile "$PROFILE" --region "$REGION" "$@"
}

# Instance IDs for the project in a given state (empty string if none).
instance_ids_in_state() {
  local state="$1"
  aws_ ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" \
              "Name=instance-state-name,Values=$state" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text
}

# Public IP of the controller — freshly read from AWS, not from Terraform output.
controller_public_ip() {
  aws_ ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" \
              "Name=tag:Role,Values=ansible_controller" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
}

# EIP address bound to the Jenkins master (survives stop/start).
jenkins_eip() {
  aws_ ec2 describe-addresses \
    --filters "Name=tag:Name,Values=p06-jenkins-master" \
    --query 'Addresses[0].PublicIp' \
    --output text
}

cmd_start() {
  local ids
  ids="$(instance_ids_in_state stopped)"
  if [[ -z "${ids// /}" ]]; then
    echo "No stopped instances for Project=$PROJECT_TAG - nothing to start."
    return 0
  fi

  echo "Starting: $ids"
  # shellcheck disable=SC2086
  aws_ ec2 start-instances --instance-ids $ids >/dev/null
  echo "Waiting until instance-running..."
  # shellcheck disable=SC2086
  aws_ ec2 wait instance-running --instance-ids $ids

  local ctrl_ip eip
  ctrl_ip="$(controller_public_ip)"
  eip="$(jenkins_eip)"

  echo
  echo "Controller SSH : ssh -A ubuntu@${ctrl_ip}"
  echo "Jenkins URL    : http://${eip}:8080"
  echo
  echo "Note: controller public IP changes on every start - the Jenkins URL uses"
  echo "      the EIP so it is stable. Run 'terraform apply -refresh-only' in"
  echo "      infra/stacks/compute if you want the Terraform output to match."
}

cmd_stop() {
  local ids
  ids="$(instance_ids_in_state running)"
  if [[ -z "${ids// /}" ]]; then
    echo "No running instances for Project=$PROJECT_TAG - nothing to stop."
    return 0
  fi

  echo "Stopping: $ids"
  # shellcheck disable=SC2086
  aws_ ec2 stop-instances --instance-ids $ids >/dev/null
  echo "Waiting until instance-stopped..."
  # shellcheck disable=SC2086
  aws_ ec2 wait instance-stopped --instance-ids $ids
  echo "All instances stopped."
}

cmd_status() {
  aws_ ec2 describe-instances \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" \
              "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value, State.Name, PublicIpAddress]' \
    --output table
}

main() {
  [[ $# -eq 1 ]] || usage
  case "$1" in
    start)  cmd_start  ;;
    stop)   cmd_stop   ;;
    status) cmd_status ;;
    -h|--help) usage ;;
    *)      usage      ;;
  esac
}

main "$@"
