Terraform Infrastructure Setup for GitHub Actions
This repository contains Terraform code to provision AWS infrastructure for managing Terraform state and deploying resources via GitHub Actions. The key components include:

S3 Bucket and DynamoDB: For storing Terraform state files.
IAM Role (GithubActionsRole): Configured with required permissions and trust policies to allow GitHub Actions to manage AWS resources.
GitHub Actions OIDC Provider: Allows your GitHub Actions workflows to access resources in Amazon Web Services (AWS), without needing to store the AWS credentials as long-lived GitHub secrets.
GitHub Actions Workflow: Automates the Terraform init, fmt, plan, and apply processes.

Getting Started
Review and customize the Terraform variables in variables.tf.
Run the GitHub Actions workflow to automatically apply the Terraform configuration.