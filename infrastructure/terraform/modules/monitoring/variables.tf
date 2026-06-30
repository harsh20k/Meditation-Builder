variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "alarm_email" {
  type = string
}

variable "lambda_function_names" {
  type = list(string)
}

variable "dynamodb_table_name" {
  type = string
}

variable "api_gateway_name" {
  type = string
}

variable "redis_cluster_id" {
  type = string
}

variable "bedrock_tagging_queue_name" {
  type = string
}

variable "bedrock_tagging_dlq_name" {
  type = string
}

variable "typesense_instance_id" {
  type = string
}

variable "bedrock_model_id" {
  type    = string
  default = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
}
