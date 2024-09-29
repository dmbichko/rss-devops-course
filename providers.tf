terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.12"
    }
  }
}

provider "aws" {
  region = var.region
}
