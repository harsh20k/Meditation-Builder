variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "audio_bucket_arn" {
  type = string
}

variable "bedrock_tagging_queue_arn" {
  type = string
}

variable "like_notifications_topic_arn" {
  type = string
}

variable "dynamodb_stream_arn" {
  type = string
}

variable "cognito_user_pool_arn" {
  type = string
}

variable "handlers" {
  type = set(string)
}
