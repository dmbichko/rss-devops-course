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
    ├── backend.tf
    ├── dynamodb.tf
    ├── dynamodb_policy.tf
    ├── IAM.tf
    ├── locals.tf
    ├── OIDCProvider.tf
    ├── providers.tf
    ├── README.md
    ├── s3.tf
    ├── screenshots
    │   ├── root-user-MFA.JPG
    │   ├── rss-user-MFA.JPG
    │   ├── success_jobs.jpg
    │   ├── success_jobs_PR.jpg
    │   └── version.jpg
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    └── variables.tf
```

---

## How to Use

1. **S3 bucket and DynamoDB table:**
  Backend must remain commented until the Bucket and the DynamoDB table are created.  After the creation you can uncomment it,run "terraform init" and then "terraform apply" 
 If you decide use local backend after creation s3 bucket and dynamodb  you should use this command  terraform init -migrate-state
2. **Initialize Terraform:**  
   Create basic tf file in S3.
   ```terraform init```
3. **Plan and Apply Changes:**  
   Review changes by running:
   ```terraform plan```  
   Apply changes by running:
   ```terraform apply```
