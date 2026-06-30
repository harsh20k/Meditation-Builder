provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "meditation-builder"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  name_prefix = local.name_prefix
  aws_region  = var.aws_region
}

module "auth" {
  source = "./modules/auth"

  name_prefix           = local.name_prefix
  environment           = var.environment
  apple_services_id     = var.apple_services_id
  apple_team_id         = var.apple_team_id
  apple_key_id          = var.apple_key_id
  apple_private_key     = var.apple_private_key
  cognito_domain_prefix = var.cognito_domain_prefix
}

module "storage" {
  source = "./modules/storage"

  name_prefix = local.name_prefix
  environment = var.environment
}

module "cache" {
  source = "./modules/cache"

  name_prefix             = local.name_prefix
  private_subnet_ids      = module.networking.private_subnet_ids
  redis_security_group_id = module.networking.redis_security_group_id
}

module "search" {
  source = "./modules/search"

  name_prefix                  = local.name_prefix
  environment                  = var.environment
  private_subnet_id            = module.networking.private_subnet_ids[0]
  typesense_security_group_id  = module.networking.typesense_security_group_id
  typesense_backup_bucket_name = module.storage.typesense_backup_bucket_name
  typesense_api_key            = var.typesense_api_key
}

module "messaging" {
  source = "./modules/messaging"

  name_prefix = local.name_prefix
}

module "iam" {
  source = "./modules/iam"

  name_prefix                  = local.name_prefix
  environment                  = var.environment
  dynamodb_table_arn           = module.storage.dynamodb_table_arn
  audio_bucket_arn             = module.storage.audio_bucket_arn
  bedrock_tagging_queue_arn    = module.messaging.bedrock_tagging_queue_arn
  like_notifications_topic_arn = module.messaging.like_notifications_topic_arn
  dynamodb_stream_arn          = module.storage.dynamodb_stream_arn
  cognito_user_pool_arn        = module.auth.user_pool_arn
  handlers                     = keys(local.lambda_handlers)
}

module "api" {
  source = "./modules/api"

  name_prefix          = local.name_prefix
  user_pool_arn        = module.auth.user_pool_arn
  lambda_invoke_arns   = local.api_lambda_invoke_arns
  lambda_function_names = local.api_lambda_function_names
}

module "cdn" {
  source = "./modules/cdn"

  name_prefix                       = local.name_prefix
  api_gateway_domain_name           = module.api.stage_domain_name
  audio_bucket_name                 = module.storage.audio_bucket_name
  audio_bucket_regional_domain_name = "${module.storage.audio_bucket_name}.s3.${var.aws_region}.amazonaws.com"
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix                = local.name_prefix
  environment                = var.environment
  alarm_email                = var.alarm_email
  lambda_function_names      = [for fn in aws_lambda_function.handlers : fn.function_name]
  dynamodb_table_name        = module.storage.dynamodb_table_name
  api_gateway_name           = module.api.rest_api_name
  redis_cluster_id           = module.cache.redis_cluster_id
  bedrock_tagging_queue_name = module.messaging.bedrock_tagging_queue_name
  bedrock_tagging_dlq_name   = module.messaging.bedrock_tagging_dlq_name
  typesense_instance_id      = module.search.typesense_instance_id
}
