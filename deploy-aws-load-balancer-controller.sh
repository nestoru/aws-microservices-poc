#!/bin/bash -e

# Check if AWS CLI, kubectl, and Helm are installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI could not be found. Please install it."
    exit
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Please install it."
    exit
fi

if ! command -v helm &> /dev/null; then
    echo "Helm could not be found. Please install it."
    exit
fi

# Check if the cluster name argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster_name>"
    exit 1
fi

CLUSTER_NAME="$1"

# Set AWS Region from current configuration
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "AWS region is not configured. Please run 'aws configure'."
    exit 1
fi

# Get OIDC provider URL
OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER=$(echo $OIDC_URL | sed -e "s/^https:\/\///")

# Create IAM policy for the AWS Load Balancer Controller
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

if [ -z "$POLICY_ARN" ]; then
    echo "Creating IAM policy: $POLICY_NAME"
    POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://iam_policy.json --query 'Policy.Arn' --output text)
else
    echo "IAM policy already exists: $POLICY_NAME"
fi

# Create IAM role and attach the policy
eksctl create iamserviceaccount \
  --region="$AWS_REGION" \
  --name=aws-load-balancer-controller \
  --namespace=kube-system \
  --cluster="$CLUSTER_NAME" \
  --attach-policy-arn="$POLICY_ARN" \
  --approve \
  --override-existing-serviceaccounts

# Add the EKS chart repo and update Helm repos
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install or upgrade the AWS Load Balancer Controller Helm chart
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

echo "AWS Load Balancer Controller deployment is complete."

