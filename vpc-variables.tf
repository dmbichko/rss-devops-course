# AWS Region
variable "region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-east-1"
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