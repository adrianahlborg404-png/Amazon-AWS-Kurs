#!/bin/bash
# =============================================================
# teardown.sh - Novatrix AB, AWS v42
# Tar bort det deploy.sh skapade, sa att inget kostar i onodan.
# =============================================================
set -uo pipefail
export AWS_DEFAULT_REGION="eu-north-1"

INSTANSER=$(aws ec2 describe-instances \
  --filters Name=tag:Name,Values=novatrix-web-v42 \
            Name=instance-state-name,Values=pending,running,stopped \
  --query 'Reservations[].Instances[].InstanceId' --output text)

if [ -n "$INSTANSER" ]; then
  echo "==> Terminerar: $INSTANSER"
  aws ec2 terminate-instances --instance-ids $INSTANSER >/dev/null
  aws ec2 wait instance-terminated --instance-ids $INSTANSER
fi

echo "==> Tar bort security group och key pair"
aws ec2 delete-security-group --group-name novatrix-web-sg 2>/dev/null || true
aws ec2 delete-key-pair --key-name novatrix-key 2>/dev/null || true
rm -f novatrix-key.pem
echo "==> Klart, miljon ar borttagen"
