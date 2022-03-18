#!/bin/bash

# Testing AWS credentials
aws configure get region # Output us-west-1

# Test availability of aws-cli
hash aws 2>/dev/null
if [ $? -ne 0 ]; then
    echo >&2 "'aws' command line tool required, but not installed. Aborting.";
    exit 1;
fi;

# Test availability of the AWS AccessKey
if [ -z "$(aws configure get aws_access_key_id)" ]; then
    echo "AWS credentials not configured. Aborting.";
    exit 1;
fi;

REGION=$(terraform output -state ./orca_terraform/terraform.tfstate -raw region)
CLUSTER_NAME=$(terraform output -state ./orca_terraform/terraform.tfstate -raw cluster_name)
REGISTRY=$(terraform output -state ./orca_terraform/terraform.tfstate -raw ecr_url)

echo "Adding new context to kubeconfig"
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

echo "Logging in to ECR Registry"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY

echo "Building Docker image"
docker build ./orca_docker -t $REGISTRY:latest
docker push $REGISTRY:latest

echo "Installing Helm Chart"
helm upgrade --install --wait orca-app ./orca_chart

echo -n "AWS LB is: "
kubectl get service -l app.kubernetes.io/name=orca-app --output=jsonpath="{.items[*].status.loadBalancer.ingress[*].hostname}"

