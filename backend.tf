# Using local backend
/*terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}*/

/*# Backend must remain commented until the Bucket
 and the DynamoDB table are created. 
 After the creation you can uncomment it,
 run "terraform init" and then "terraform apply" */

terraform {
  backend "s3" {
    bucket         = "rss-devops-course-dmbichko-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "rss-devops-course-dmbichko-terraform-state-dynamodb"
  }
}