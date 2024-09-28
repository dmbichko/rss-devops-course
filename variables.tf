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

variable "prefix" {
  default = "dev"
}

variable "project" {
  default = "rss-devops-course"
}

variable "contact" {
  default = "dmitrijbichko@gmail.com"
}