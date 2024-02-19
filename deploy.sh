#!/bin/bash -ex
# Deploys services using the AWS credentials and region specified in AWS_PROFILE
# Check if all arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <AWS_PROFILE> <DOMAIN_NAME> <APP_SERVICE_NAME> <APP_VERSION>"
    exit 1
fi

AWS_PROFILE="$1"
export AWS_PROFILE
DOMAIN_NAME="$2"
APP_SERVICE_NAME="$3"
APP_VERSION="$4"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION=$(aws configure get region --profile $AWS_PROFILE)
AWS_ECR_REPO_NAME=$APP_SERVICE_NAME
IMAGE_NAME=$APP_SERVICE_NAME
AWS_ECR_REPO_BASE_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG=$APP_VERSION
IMAGE_TAG_URL="${AWS_ECR_REPO_BASE_URL}/$IMAGE_NAME:$IMAGE_TAG"
CHART_DIR="./helm"
NAMESPACE="default"
MAJOR_VERSION=$(echo $APP_VERSION | cut -d '.' -f1)
CERTIFICATE_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'].CertificateArn" --output text --profile $AWS_PROFILE)

# Authenticate Docker with Amazon ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Create repository if it does not exist

if ! aws ecr create-repository --repository-name $AWS_ECR_REPO_NAME; then
  echo "Repository $AWS_ECR_REPO_NAME already existed or could not be created for $IMAGE_TAG_URL"
fi

# Build and Push Docker Image
cd microservice
echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .
echo "Deleting Docker image from registry"
if ! aws ecr batch-delete-image --repository-name ${AWS_ECR_REPO_NAME} --image-ids imageTag=$IMAGE_TAG --profile $AWS_PROFILE; then
  echo "No docker image existed"
fi
echo "Tagging docker image"
docker tag $IMAGE_NAME $IMAGE_TAG_URL
echo "Pushing Docker image to registry"
docker push $IMAGE_TAG_URL
cd ../

# Deploy with Helm
echo "Deploying application with Helm"
helm upgrade --install "${APP_SERVICE_NAME}-${MAJOR_VERSION}" $CHART_DIR \
  --namespace $NAMESPACE \
  --create-namespace \
  --set awsAccount="$AWS_ACCOUNT_ID" \
  --set awsRegion="$AWS_REGION" \
  --set appServiceName="$APP_SERVICE_NAME" \
  --set appVersion="$APP_VERSION" \
  --set majorVersion="$MAJOR_VERSION" \
  --set certificateArn="$CERTIFICATE_ARN"
echo "Deployment complete"

