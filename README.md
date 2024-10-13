Terraform Infrastructure Setup for GitHub Actions
This repository contains Terraform code to provision AWS infrastructure for managing Terraform state and deploying resources via GitHub Actions. The key components include:

S3 Bucket and DynamoDB: For storing Terraform state files.
IAM Role (GithubActionsRole): Configured with required permissions and trust policies to allow GitHub Actions to manage AWS resources.
GitHub Actions OIDC Provider: Allows your GitHub Actions workflows to access resources in Amazon Web Services (AWS), without needing to store the AWS credentials as long-lived GitHub secrets.
GitHub Actions Workflow: Automates the Terraform init, fmt, plan, and apply processes.

Getting Started
Review and customize the Terraform variables in variables.tf.
Run the GitHub Actions workflow to automatically apply the Terraform configuration.

## 📂 Repository Structure

```sh
└── rss-devops-course/
    ├── .github
    │   └── workflows
    ├── acl.tf
    ├── aim.tf    
    ├── backend.tf
    ├── dynamodb.tf
    ├── dynamodb_policy.tf
    ├── ec2.tf
    ├── locals.tf
    ├── OIDCProvider.tf
    ├── providers.tf
    ├── output.tf
    ├── README.md
    ├── s3.tf
    ├── sg.tf   
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    └── variables.tf
    ├── vpc.tf
```

---
# TASK2
# AWS Infrastructure with Terraform and GitHub Actions

This project sets up and manages AWS infrastructure using Terraform, with deployments automated through GitHub Actions.

## Project Overview

This project creates and manages the following AWS resources:
- VPC with public and private subnets in 2 different Availability zones
- Internet Gateway for VPC and 2 NAT Gateways for each Availability zone 
- EC2 instances (including a bastion host)
- Security Groups and Network ACLs
- S3 bucket for Terraform state
- IAM roles and policies for GitHub Actions

## Prerequisites

- AWS Account
- GitHub Account
- Terraform installed locally (for manual runs)

## Setup

1. Fork this repository
2. Set up the following secrets in your GitHub repository:
   - AWS_ACCOUNT_ID
   - BASTION_SSH_KEY (public key)
   - EC2_SSH_KEY (public key)

3. Update the `variables.tf` file with your specific values

## How to Use

1. **S3 bucket and DynamoDB table:**
  Backend must remain commented until the Bucket and the DynamoDB table are created.  After the creation you can uncomment it,run "terraform init" and then "terraform apply" 
 If you decide use local backend after creation s3 bucket and dynamodb  you should use this command  terraform init -migrate-state

### GitHub Actions

The project uses GitHub Actions for automated deployments. The workflow is triggered on pushes to the main branch.

To manually trigger a deployment:
1. Go to the "Actions" tab in your GitHub repository
2. Select the "Terraform" workflow
3. Click "Run workflow"

### Manual Terraform Commands

If you need to run Terraform commands manually:

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY"

# Apply changes
terraform apply -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY"

# Destroy infrastructure (use with caution!)
terraform destroy -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY"