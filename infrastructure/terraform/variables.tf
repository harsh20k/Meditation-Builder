variable "environment" {
  description = "Deployment environment (staging or production)."
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "mb"
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
  default     = ""
}

variable "apple_services_id" {
  description = "Apple Services ID for Sign in with Apple."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_team_id" {
  description = "Apple Developer Team ID."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple Sign in with Apple key ID."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_private_key" {
  description = "Apple Sign in with Apple private key (p8 contents)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_domain_prefix" {
  description = "Cognito hosted UI domain prefix."
  type        = string
  default     = "meditation-builder"
}

variable "typesense_api_key" {
  description = "Typesense API key (stored in SSM at deploy time)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_lambda_provisioned_concurrency" {
  description = "Enable provisioned concurrency on hot-path Lambdas. Disable on small accounts where reserved capacity would drop unreserved concurrency below AWS minimum (10)."
  type        = bool
  default     = false
}
