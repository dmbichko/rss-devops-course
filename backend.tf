# Using local backend
/*terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}*/

/*# Backend must remain commented until the Bucket
 and the DynamoDB table are created. 
 After the creation you can uncomment it,
 run "terraform init" and then "terraform apply" 
 If you decide use local backend after creation s3 bucket
 and dynamodb  you should use this command 
 terraform init -migrate-state*/

terraform {
  backend "s3" {
    bucket         = "rss-devops-course-dmbichko-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "rss-devops-course-dmbichko-terraform-state-dynamodb"
  }
}