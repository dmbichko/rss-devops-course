variable "ec2_public_key" {
  description = "Name of the SSH key pair"
  default     = "K8s-ec2-key"
  type        = string
}

variable "ec2-instance-type" {
  description = "EC2 instance type"
  default     = "t3.micro"
  type        = string
}