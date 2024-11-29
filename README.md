### AWS Infrastructure with Terraform and K3s Deployment Using GitHub Actions

This project provisions AWS infrastructure and deploys a lightweight Kubernetes cluster (K3s) using Terraform and GitHub Actions. The automated workflow includes setting up EC2 instances, a bastion host, a K3s server, and worker nodes, as well as deploying a sample workload to the cluster.

###Project Overview

The repository is structured to manage the following AWS resources:
- VPC with public and private subnets across two Availability Zones.
- Internet Gateway and NAT Gateways for secure access.
- EC2 instances, including:
	- A bastion host for secure SSH access.
	- K3s server and worker nodes to run the Kubernetes cluster.
- Security Groups and Network ACLs for secure communication.
- S3 bucket and DynamoDB table for storing Terraform state.
- IAM roles and policies for GitHub Actions and EC2 instances.

#### 📂 Repository Structure

```sh
📂 rss-devops-course/
├── .github/
│   └── workflows/           # GitHub Actions workflows
├── acl.tf                   # Network ACLs
├── aim.tf                   # IAM roles and policies
├── backend.tf               # S3 and DynamoDB backend configuration
├── dynamodb.tf              # DynamoDB table for state locking
├── dynamodb_policy.tf       # IAM policy for DynamoDB access
├── ec2.tf                   # EC2 instance definitions (Bastion, K3s Server, Workers)
├── locals.tf                # Local variables and common tags
├── OIDCProvider.tf          # GitHub OIDC provider configuration
├── providers.tf             # Provider configuration (AWS)
├── output.tf                # Output configuration
├── README.md                # Project documentation (this file)
├── s3.tf                    # S3 bucket for Terraform state
├── sg.tf                    # Security groups for EC2 instances
├── terraform.tfstate        # Terraform state file (generated)
├── terraform.tfstate.backup # Terraform state backup
└── variables.tf             # Variables file
```

#### Prerequisites

- AWS Account
- GitHub Account
- Terraform installed locally (for manual runs)

### Key Components

### 1.Terraform State Management

- S3 Bucket and DynamoDB: Terraform state files are stored in an S3 bucket with state locking managed by a DynamoDB table.
- IAM Role (GitHubActionsRole): Provides the necessary permissions for GitHub Actions to manage AWS resources via OIDC authentication.
- GitHub Actions OIDC Provider: Enables secure access to AWS without storing long-lived credentials in GitHub secrets.

### 2. K3s Cluster Deployment

- K3s Server and Workers: Deployed using EC2 instances. The server and worker nodes are configured with user_data scripts for automated K3s installation and registration.
- Server User Data: Automates K3s server installation.

```bash
#!/bin/bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}
```
- Worker User Data: Workers wait for the K3s server to be ready before joining the cluster and registering themselves.

```bash
#!/bin/bash
until nc -z ${aws_instance.ec2-k3s_server.private_ip} 6443; do
  echo "Waiting for K3s server to be ready..."
  sleep 5
done
curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.ec2-k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
```
- Once the K3s cluster is up, you can copy the /etc/rancher/k3s/k3s.yaml file from the bastion host to your local machine to interact with the cluster using kubectl.

#### Getting Started

#### 1.Terraform Setup
1. Fork this repository and clone it locally.
2. Review and customize the Terraform variables in the variables.tf file.
3. Ensure the S3 bucket and DynamoDB table are created before uncommenting the backend configuration in backend.tf.
4. Initialize and apply the Terraform configuration:

```bash
terraform init
terraform apply -var="aws_account_id=YOUR_ACCOUNT_ID" \
                -var="bastion-ssh-key=YOUR_BASTION_KEY" \
                -var="ec2-ssh-key=YOUR_EC2_KEY" \
                -var="k3s_token=YOUR_K3S_TOKEN"
```

#### 2. GitHub Actions Workflow
To automate the deployment process:

1.Set the following secrets in your GitHub repository:

- AWS_ACCOUNT_ID
- BASTION_SSH_KEY (public key)
- EC2_SSH_KEY (public key)
- K3S_TOKEN

2.Push any changes to the main branch, and the workflow will automatically trigger.

To manually trigger a deployment:

1. Go to the Actions tab in your repository.
2. Select the Terraform workflow and click Run workflow.

### Cluster Deployment and Verification

### 1. K3s Cluster Deployment
The K3s server is deployed using the following user data script:

```bash
#!/bin/bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}
```

The worker nodes automatically join the cluster after verifying the server's availability:

```bash
#!/bin/bash
until nc -z ${aws_instance.ec2-k3s_server.private_ip} 6443; do
  echo "Waiting for K3s server to be ready..."
  sleep 5
done
curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.ec2-k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
```

### 2. Cluster Verification
After deployment, verify the cluster by SSH into the bastion host and copy /etc/rancher/k3s/k3s.yaml from K3s server to the bastion host as ~/.kube/config. Then replace the value of the server field with the IP of the K3s server.
You will then be able to run the following command:

```bash
kubectl get nodes
```

This should list all K3s server and worker nodes in the cluster.

### 3. Workload Deployment
To test the cluster, deploy a sample workload:

```bash
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
```



### Manual Terraform Commands

If you need to run Terraform commands manually:

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY" -var="k3s_token=${{env.K3S_TOKEN}}"

# Apply changes
terraform apply -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY" -var="k3s_token=${{env.K3S_TOKEN}}"

# Destroy infrastructure (use with caution!)
terraform destroy -var="aws_account_id=YOUR_ACCOUNT_ID" -var="bastion-ssh-key=YOUR_BASTION_KEY" -var="ec2-ssh-key=YOUR_EC2_KEY" -var="k3s_token=${{env.K3S_TOKEN}}"
