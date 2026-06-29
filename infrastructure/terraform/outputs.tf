output "environment" {
  value = var.environment
}

output "api_invoke_url" {
  value = module.api.invoke_url
}

# Base URL for paths like /routines (stage "v1" + resource prefix "/v1").
output "api_base_url" {
  value = "${module.api.invoke_url}/v1"
}

output "api_cloudfront_domain" {
  value = module.cdn.api_distribution_domain_name
}

output "audio_cloudfront_domain" {
  value = module.cdn.audio_distribution_domain_name
}

output "cognito_user_pool_id" {
  value = module.auth.user_pool_id
}

output "cognito_app_client_id" {
  value = module.auth.app_client_id
}

output "dynamodb_table_name" {
  value = module.storage.dynamodb_table_name
}

output "redis_endpoint" {
  value = module.cache.redis_endpoint
}

output "typesense_private_ip" {
  value = module.search.typesense_private_ip
}

output "lambda_function_names" {
  value = { for k, fn in aws_lambda_function.handlers : k => fn.function_name }
}
