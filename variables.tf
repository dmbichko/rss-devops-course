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