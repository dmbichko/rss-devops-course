variable "region" {
  type    = string
  default = "us-east-1"
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
  type    = string
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