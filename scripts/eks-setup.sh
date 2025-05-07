#!/bin/bash
set -e

# Configuration variables
CLUSTER_NAME="campaign-manager-cluster"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODE_COUNT=2
ECR_REPOSITORY_NAME="campaign-manager"

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null
then
    echo "eksctl could not be found, installing..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found, installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "AWS CLI could not be found, please install it first"
    exit 1
fi

# Create EKS cluster
echo "Creating EKS cluster $CLUSTER_NAME in region $REGION..."
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --node-type $NODE_TYPE \
    --nodes $NODE_COUNT \
    --nodes-min 1 \
    --nodes-max 3 \
    --with-oidc \
    --managed

# Create ECR repository if it doesn't exist
echo "Checking if ECR repository $ECR_REPOSITORY_NAME exists..."
if ! aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $REGION &> /dev/null; then
    echo "Creating ECR repository $ECR_REPOSITORY_NAME..."
    aws ecr create-repository --repository-name $ECR_REPOSITORY_NAME --region $REGION
else
    echo "ECR repository $ECR_REPOSITORY_NAME already exists"
fi

# Create IAM service account for DynamoDB access
echo "Creating IAM service account for DynamoDB access..."
eksctl create iamserviceaccount \
    --name dynamodb-access \
    --namespace campaign-manager \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
    --approve \
    --region $REGION

echo "EKS cluster setup complete!"
echo "To access your cluster, run: aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"

# Output important information
echo "============================================================"
echo "Cluster name: $CLUSTER_NAME"
echo "Region: $REGION"
echo "ECR Repository: $ECR_REPOSITORY_NAME"
echo "To push your Docker image, use: $(aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com)"
echo "============================================================"