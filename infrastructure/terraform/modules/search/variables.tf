variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "typesense_security_group_id" {
  type = string
}

variable "typesense_backup_bucket_name" {
  type = string
}

variable "typesense_api_key" {
  type      = string
  sensitive = true
}
