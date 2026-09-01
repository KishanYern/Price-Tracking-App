# AWS CI/CD setup

PricePulse uses GitHub Actions, Amazon ECR, GitHub OIDC, and AWS Systems Manager Run Command.

## Repository variables

Configure these under **Settings → Secrets and variables → Actions → Variables**:

- `AWS_REGION=us-east-1`
- `AWS_ACCOUNT_ID=587788487276`
- `AWS_DEPLOY_ROLE_ARN=arn:aws:iam::587788487276:role/PricePulseGitHubDeployRole`
- `BACKEND_INSTANCE_ID=i-0be4fdd9a00c0dcd9`
- `FRONTEND_INSTANCE_ID=i-07b66902e39f0a847`
- `VITE_API_URL=/api`

The frontend nginx container proxies `/api/` to the backend private address, so browser traffic never targets the VPC-private IP directly.

## AWS resources

Run `scripts/bootstrap-aws-cicd.sh` with an AWS CLI identity allowed to manage IAM, ECR, EC2 instance profiles, and SSM. The script creates or updates:

- ECR repositories `pricepulse-backend` and `pricepulse-frontend`
- GitHub's AWS OIDC provider
- `PricePulseGitHubDeployRole` and its deployment policy
- SSM and ECR read permissions for both EC2 instances
- A minimal EC2 instance profile when an instance does not already have one

The backend runtime configuration must exist at `/opt/pricepulse/backend.env` with root ownership and mode `600`. Do not commit that file or its values.

## Deployment flow

On pull requests, the workflow runs backend and frontend tests. On pushes to `main`, it also builds commit-tagged Docker images, pushes them to ECR, and deploys them through SSM. The frontend keeps the existing Let's Encrypt mounts and serves `pricepulselab.com` over HTTPS.
