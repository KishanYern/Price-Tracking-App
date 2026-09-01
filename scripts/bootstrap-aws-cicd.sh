#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   AWS_REGION=us-east-1 #   BACKEND_INSTANCE_ID=i-... #   FRONTEND_INSTANCE_ID=i-... #   VITE_API_URL=http://YOUR_BACKEND_ADDRESS:8000 #   ./scripts/bootstrap-aws-cicd.sh
#
# Run this with an AWS CLI identity that can create IAM roles/policies,
# ECR repositories, and attach policies to existing EC2 instance roles.

: "${AWS_REGION:?Set AWS_REGION}"
: "${BACKEND_INSTANCE_ID:?Set BACKEND_INSTANCE_ID}"
: "${FRONTEND_INSTANCE_ID:?Set FRONTEND_INSTANCE_ID}"
: "${VITE_API_URL:?Set VITE_API_URL}"

GITHUB_OWNER="KishanYern"
GITHUB_REPO="PricePulse"
DEPLOY_ROLE="PricePulseGitHubDeployRole"
DEPLOY_POLICY="PricePulseGitHubDeployPolicy"
BACKEND_REPO="pricepulse-backend"
FRONTEND_REPO="pricepulse-frontend"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

echo "AWS account: $ACCOUNT_ID"
echo "Region: $AWS_REGION"

aws ecr describe-repositories --region "$AWS_REGION" --repository-names "$BACKEND_REPO" >/dev/null 2>&1   || aws ecr create-repository --region "$AWS_REGION" --repository-name "$BACKEND_REPO"        --image-scanning-configuration scanOnPush=true >/dev/null

aws ecr describe-repositories --region "$AWS_REGION" --repository-names "$FRONTEND_REPO" >/dev/null 2>&1   || aws ecr create-repository --region "$AWS_REGION" --repository-name "$FRONTEND_REPO"        --image-scanning-configuration scanOnPush=true >/dev/null

if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider     --url https://token.actions.githubusercontent.com     --client-id-list sts.amazonaws.com >/dev/null
fi

cat >/tmp/pricepulse-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "$OIDC_ARN"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main"
      }
    }
  }]
}
EOF

if aws iam get-role --role-name "$DEPLOY_ROLE" >/dev/null 2>&1; then
  aws iam update-assume-role-policy     --role-name "$DEPLOY_ROLE"     --policy-document file:///tmp/pricepulse-trust.json
else
  aws iam create-role     --role-name "$DEPLOY_ROLE"     --assume-role-policy-document file:///tmp/pricepulse-trust.json >/dev/null
fi

cat >/tmp/pricepulse-deploy-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Sid": "ECRPush",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": [
        "arn:aws:ecr:${AWS_REGION}:${ACCOUNT_ID}:repository/${BACKEND_REPO}",
        "arn:aws:ecr:${AWS_REGION}:${ACCOUNT_ID}:repository/${FRONTEND_REPO}"
      ]
    },
    {
      "Sid": "SSMDeploy",
      "Effect": "Allow",
      "Action": ["ssm:SendCommand"],
      "Resource": [
        "arn:aws:ec2:${AWS_REGION}:${ACCOUNT_ID}:instance/${BACKEND_INSTANCE_ID}",
        "arn:aws:ec2:${AWS_REGION}:${ACCOUNT_ID}:instance/${FRONTEND_INSTANCE_ID}",
        "arn:aws:ssm:${AWS_REGION}::document/AWS-RunShellScript"
      ]
    },
    {
      "Sid": "SSMRead",
      "Effect": "Allow",
      "Action": [
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations",
        "ssm:ListCommands"
      ],
      "Resource": "*"
    }
  ]
}
EOF

POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${DEPLOY_POLICY}"
if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  DEFAULT_VERSION="$(aws iam get-policy --policy-arn "$POLICY_ARN" --query 'Policy.DefaultVersionId' --output text)"
  aws iam create-policy-version     --policy-arn "$POLICY_ARN"     --policy-document file:///tmp/pricepulse-deploy-policy.json     --set-as-default >/dev/null
else
  aws iam create-policy     --policy-name "$DEPLOY_POLICY"     --policy-document file:///tmp/pricepulse-deploy-policy.json >/dev/null
fi

aws iam attach-role-policy   --role-name "$DEPLOY_ROLE"   --policy-arn "$POLICY_ARN"

ensure_instance_role() {
  local instance_id="$1"
  local profile_arn
  profile_arn="$(aws ec2 describe-instances     --region "$AWS_REGION"     --instance-ids "$instance_id"     --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'     --output text)"

  if [[ -z "$profile_arn" || "$profile_arn" == "None" ]]; then
    local role_name="PricePulseEC2DeployRole-${instance_id}"
    local profile_name="PricePulseEC2DeployProfile-${instance_id}"

    echo "Creating IAM instance profile $profile_name for $instance_id" >&2

    cat >/tmp/pricepulse-ec2-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

    if ! aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
      aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document file:///tmp/pricepulse-ec2-trust.json \
        >/dev/null
    fi

    if ! aws iam get-instance-profile --instance-profile-name "$profile_name" >/dev/null 2>&1; then
      aws iam create-instance-profile --instance-profile-name "$profile_name" >/dev/null
    fi

    local attached_role
    attached_role="$(aws iam get-instance-profile \
      --instance-profile-name "$profile_name" \
      --query 'InstanceProfile.Roles[0].RoleName' \
      --output text)"
    if [[ -z "$attached_role" || "$attached_role" == "None" ]]; then
      aws iam add-role-to-instance-profile \
        --instance-profile-name "$profile_name" \
        --role-name "$role_name"
    fi

    local associated=false
    for attempt in {1..12}; do
      if aws ec2 associate-iam-instance-profile \
        --region "$AWS_REGION" \
        --instance-id "$instance_id" \
        --iam-instance-profile "Name=$profile_name" \
        >/dev/null 2>&1; then
        associated=true
        break
      fi
      echo "Waiting for IAM instance profile propagation (attempt $attempt/12)" >&2
      sleep 5
    done

    if [[ "$associated" != true ]]; then
      echo "ERROR: Could not associate IAM instance profile $profile_name with $instance_id." >&2
      return 1
    fi

    echo "$role_name"
    return
  fi

  local profile_name="${profile_arn##*/}"
  aws iam get-instance-profile     --instance-profile-name "$profile_name"     --query 'InstanceProfile.Roles[0].RoleName'     --output text
}

for INSTANCE_ID in "$BACKEND_INSTANCE_ID" "$FRONTEND_INSTANCE_ID"; do
  INSTANCE_ROLE="$(ensure_instance_role "$INSTANCE_ID")"
  echo "Configuring instance role $INSTANCE_ROLE for $INSTANCE_ID"

  aws iam attach-role-policy     --role-name "$INSTANCE_ROLE"     --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  aws iam attach-role-policy     --role-name "$INSTANCE_ROLE"     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
done

echo
echo "Bootstrap complete."
echo
echo "Create these GitHub repository variables:"
echo "AWS_REGION=$AWS_REGION"
echo "AWS_ACCOUNT_ID=$ACCOUNT_ID"
echo "AWS_DEPLOY_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/${DEPLOY_ROLE}"
echo "BACKEND_INSTANCE_ID=$BACKEND_INSTANCE_ID"
echo "FRONTEND_INSTANCE_ID=$FRONTEND_INSTANCE_ID"
echo "VITE_API_URL=$VITE_API_URL"
echo
echo "Before first deployment, create /opt/pricepulse/backend.env on the backend EC2 host."
