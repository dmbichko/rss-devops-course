#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function for error handling
handle_error() {
    echo "An error occurred on line $LINENO: $1"
    exit 1
}

# Set up error handling
trap 'handle_error "$BASH_COMMAND"' ERR

# Enable logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting Jenkins installation process..."

# Create a dedicated namespace for Jenkins
# This provides isolation for Jenkins resources
kubectl create namespace jenkins || echo "Namespace jenkins already exists"
# Apply service account configuration
# This sets up the necessary RBAC permissions for Jenkins
echo "Applying service account configuration..."
kubectl apply -f jenkins-sa.yaml
# Apply service account configuration
# This sets up the necessary RBAC permissions for Jenkins
echo "Applying service account configuration..."
kubectl apply -f jenkins-sa.yaml
# Add the official Jenkins Helm repository
echo "Adding Jenkins Helm repository..."
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
# Retrieve Jenkins admin password from AWS Parameter Store
# This is more secure than hardcoding the password
echo "Retrieving Jenkins admin password from Parameter Store..."
JENKINS_PASS=$(aws ssm get-parameter \
    --name "/jenkins/admin/password" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text) || handle_error "Failed to retrieve password from Parameter Store"
# Create Kubernetes secret for Jenkins admin credentials
# Using --dry-run=client to validate the configuration
# Using kubectl apply to create or update the secret
echo "Creating Jenkins admin secret..."
kubectl create secret generic jenkins-admin-secret \
    --namespace jenkins \
    --from-literal=jenkins-admin-user=admin \
    --from-literal=jenkins-admin-password="$JENKINS_PASS" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Secret created successfully"

# Define the Helm chart to use
chart=jenkinsci/jenkins

# Install Jenkins using Helm
# -n specifies the namespace
# -f specifies the values file
echo "Installing Jenkins using Helm..."
helm install jenkins -n jenkins -f jenkins-values.yaml $chart

# Wait for Jenkins pods to be ready
echo "Waiting for Jenkins pods to become ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=jenkins -n jenkins --timeout=300s || handle_error "Jenkins pods failed to become ready"

# Display all resources in Jenkins namespace
echo "Displaying all resources in Jenkins namespace..."
kubectl get all -n jenkins

# Show detailed information about the Jenkins pod
echo "Displaying detailed pod information..."
kubectl describe pod jenkins-0 -n jenkins

echo "Jenkins installation completed successfully"
