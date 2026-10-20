#!/bin/bash
# =============================================================
# deploy.sh - Novatrix AB, AWS v42
# Skapar hela miljon fran kod: key pair, security group och
# EC2-instans som installerar Apache + webbsida via user data.
#
# Kors i AWS CloudShell (region Stockholm, eu-north-1):
#   git clone https://github.com/<user>/AWS-novatrix-mov25.git
#   cd AWS-novatrix-mov25/v42/scripts
#   bash deploy.sh
# =============================================================
set -euo pipefail

REGION="eu-north-1"            # Stockholm
NAMN="novatrix-web-v42"
INSTANSTYP="t3.micro"          # free tier-berattigad i Stockholm
KEY_NAME="novatrix-key"
SG_NAME="novatrix-web-sg"
MITT_IP="${1:-}"               # valfritt: din publika IP for SSH, t.ex. 83.250.10.20

export AWS_DEFAULT_REGION="$REGION"
cd "$(dirname "$0")"

echo "==> 1/5 Hamtar senaste Amazon Linux 2023-AMI"
AMI_ID=$(aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query 'Parameter.Value' --output text)
echo "    AMI: $AMI_ID"

echo "==> 2/5 Key pair"
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
  echo "    $KEY_NAME finns redan, ateranvands"
else
  aws ec2 create-key-pair --key-name "$KEY_NAME" --key-type ed25519 \
    --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  echo "    Sparad som ${KEY_NAME}.pem (ladda ner den, lagg den INTE i GitHub)"
fi

echo "==> 3/5 Security group i default-VPC"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values="$SG_NAME" Name=vpc-id,Values="$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)
if [ "$SG_ID" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" \
    --description "Novatrix webb: HTTP fran alla, SSH fran min IP" \
    --vpc-id "$VPC_ID" --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
  if [ -n "$MITT_IP" ]; then
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
      --protocol tcp --port 22 --cidr "${MITT_IP}/32" >/dev/null
    echo "    SSH oppnad for ${MITT_IP}/32"
  fi
fi
echo "    SG: $SG_ID"

echo "==> 4/5 Startar EC2-instans ($INSTANSTYP)"
INSTANS_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANSTYP" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --associate-public-ip-address \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAMN},{Key=Projekt,Value=novatrix}]" \
  --query 'Instances[0].InstanceId' --output text)
echo "    Instans: $INSTANS_ID - vantar pa att den ska bli 'running'..."
aws ec2 wait instance-running --instance-ids "$INSTANS_ID"

echo "==> 5/5 Klart"
PUBLIK_IP=$(aws ec2 describe-instances --instance-ids "$INSTANS_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo ""
echo "    Webbsida: http://$PUBLIK_IP  (ge user data 1-2 minuter)"
echo "    Testa:    curl -I http://$PUBLIK_IP"
echo "    Riv ner:  bash teardown.sh"
