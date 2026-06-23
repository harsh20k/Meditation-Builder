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
