variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "apple_services_id" {
  type      = string
  sensitive = true
}

variable "apple_team_id" {
  type      = string
  sensitive = true
}

variable "apple_key_id" {
  type      = string
  sensitive = true
}

variable "apple_private_key" {
  type      = string
  sensitive = true
}

variable "cognito_domain_prefix" {
  type = string
}
