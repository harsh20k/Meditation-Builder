terraform {
  backend "s3" {
    key     = "meditation-builder/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # bucket and dynamodb_table are account-specific — set at init:
    #   terraform init -backend-config=backend.hcl
  }
}
