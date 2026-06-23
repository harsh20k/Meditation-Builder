resource "null_resource" "lambda_packages" {
  triggers = {
    package_script = filesha256("${path.module}/../lambdas/package.sh")
    shared_hash = sha256(join("", [
      for f in fileset("${path.module}/../lambdas/shared", "*.py") :
      filesha256("${path.module}/../lambdas/shared/${f}")
    ]))
    handlers_hash = sha256(join("", [
      for f in fileset("${path.module}/../lambdas/handlers", "*.py") :
      filesha256("${path.module}/../lambdas/handlers/${f}")
    ]))
    requirements = filesha256("${path.module}/../lambdas/shared/requirements.txt")
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/../lambdas/package.sh"
    working_dir = path.module
  }
}

resource "aws_lambda_function" "handlers" {
  for_each = local.lambda_handlers

  function_name = "${local.name_prefix}-${replace(each.key, "_", "-")}"
  role          = module.iam.lambda_role_arns[each.key]
  handler       = "handlers/${each.key}.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename         = "${path.module}/../lambdas/dist/${each.key}.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/dist/${each.key}.zip")

  publish = true

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = module.networking.private_subnet_ids
    security_group_ids = [module.networking.lambda_security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT                   = var.environment
      DYNAMODB_TABLE                = module.storage.dynamodb_table_name
      REDIS_ENDPOINT                = module.cache.redis_endpoint
      REDIS_PORT                    = tostring(module.cache.redis_port)
      TYPESENSE_HOST                = module.search.typesense_private_ip
      TYPESENSE_PORT                = "8108"
      TYPESENSE_API_KEY_SSM         = module.search.typesense_api_key_ssm_path
      AUDIO_BUCKET                  = module.storage.audio_bucket_name
      BEDROCK_QUEUE_URL             = module.messaging.bedrock_tagging_queue_url
      LIKE_NOTIFICATIONS_TOPIC_ARN  = module.messaging.like_notifications_topic_arn
    }
  }

  depends_on = [
    null_resource.lambda_packages,
    module.iam,
    module.networking,
    module.cache,
    module.search,
    module.messaging,
  ]
}

resource "aws_lambda_provisioned_concurrency_config" "handlers" {
  for_each = {
    for k, v in local.lambda_handlers : k => v if v.provisioned > 0
  }

  function_name                     = aws_lambda_function.handlers[each.key].function_name
  provisioned_concurrent_executions = each.value.provisioned
  qualifier                         = aws_lambda_function.handlers[each.key].version
}

resource "aws_lambda_event_source_mapping" "bedrock_tagger" {
  event_source_arn = module.messaging.bedrock_tagging_queue_arn
  function_name    = aws_lambda_function.handlers["bedrock_tagger"].arn
  batch_size       = 5
}

resource "aws_lambda_event_source_mapping" "typesense_indexer" {
  event_source_arn  = module.storage.dynamodb_stream_arn
  function_name     = aws_lambda_function.handlers["typesense_indexer"].arn
  starting_position = "LATEST"
  batch_size        = 10

  filter_criteria {
    filter {
      pattern = jsonencode({
        dynamodb = {
          NewImage = {
            EntityType = { S = ["Routine"] }
          }
        }
      })
    }
  }
}

resource "aws_cloudwatch_event_rule" "like_flush" {
  name                = "${local.name_prefix}-like-flush"
  description         = "Flush Redis like counters every minute (EventBridge minimum interval)"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "like_flush" {
  rule      = aws_cloudwatch_event_rule.like_flush.name
  target_id = "like-flush"
  arn       = aws_lambda_function.handlers["like_flush"].arn
}

resource "aws_lambda_permission" "like_flush_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handlers["like_flush"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.like_flush.arn
}
