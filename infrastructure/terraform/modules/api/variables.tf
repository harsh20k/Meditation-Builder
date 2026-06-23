variable "name_prefix" {
  type = string
}

variable "user_pool_arn" {
  type = string
}

variable "lambda_invoke_arns" {
  type = map(string)
}

variable "lambda_function_names" {
  type = map(string)
}
