variable "region" {
  type    = string
  default = "us-east-1"
}

/*variable "ec2_public_key" {
  description = "Name of the SSH key pair"
  default     = "K8s-ec2-key"
  type        = string
}*/

variable "bastion-ssh-key" {
  description = "Public key for bastion host"
  type        = string
}
variable "ec2-ssh-key" {
  description = "Public key for other instances"
  type        = string
}

variable "ec2-instance-type" {
  description = "EC2 instance type"
  default     = "t3.micro"
  type        = string
}

variable "your_ip" {
  type        = string
  description = "Your IP address"
  default     = "0.0.0.0/0"
}

# VPC variables defined as below
# VPC Name
variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "vpc-K8s"
}

# VPC CIDR Block
variable "cidr" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

# VPC Public Subnets
variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

# VPC Private Subnets
variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "terraform-state-s3-bucket" {
  type    = string
  default = "rss-devops-course-dmbichko-terraform-state"
}

variable "terraform-state-dynamodb" {
  type    = string
  default = "rss-devops-course-dmbichko-terraform-state-dynamodb"
}

variable "DynamoDBAccessPolicyName" {
  type    = string
  default = "DynamoDBAccessPolicy"
}

variable "aws_account_id" {
  type = string
}

variable "terraform_github_actions_IODC_provider_name" {
  type    = string
  default = "GitHub Actions OIDC Provider"
}

variable "terraform_github_actions_role_name" {
  type    = string
  default = "GithubActionsRole"
}

variable "prefix" {
  default = "dev"
}

variable "project" {
  default = "rss-devops-course"
}

variable "contact" {
  default = "dmitrijbichko@gmail.com"
}