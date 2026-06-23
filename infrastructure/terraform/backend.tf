terraform {
  backend "s3" {
    bucket         = "mb-terraform-state"
    key            = "meditation-builder/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mb-terraform-locks"
    encrypt        = true
  }
}
