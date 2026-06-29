variable "aws_region" {
  description = "AWS region for the Terraform state bucket and lock table. Must match infrastructure/terraform (us-east-1)."
  type        = string
  default     = "us-east-1"
}
