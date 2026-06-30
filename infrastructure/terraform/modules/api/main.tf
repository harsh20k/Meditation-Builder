resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.name_prefix}-api"
  description = "Meditation Builder Community API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.name_prefix}-cognito"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.user_pool_arn]
}

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "routines" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "routines"
}

resource "aws_api_gateway_resource" "routine_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.routines.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "like" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.routine_id.id
  path_part   = "like"
}

resource "aws_api_gateway_resource" "import" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.routine_id.id
  path_part   = "import"
}

resource "aws_api_gateway_resource" "recommendations" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "recommendations"
}

resource "aws_api_gateway_resource" "search" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "search"
}

resource "aws_api_gateway_resource" "activity" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "activity"
}

resource "aws_api_gateway_resource" "uploads" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "uploads"
}

resource "aws_api_gateway_resource" "uploads_audio" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.uploads.id
  path_part   = "audio"
}

locals {
  routes = {
    get_routines = {
      resource_id = aws_api_gateway_resource.routines.id
      method      = "GET"
      auth        = false
    }
    post_routine = {
      resource_id = aws_api_gateway_resource.routines.id
      method      = "POST"
      auth        = false
    }
    get_routine = {
      resource_id = aws_api_gateway_resource.routine_id.id
      method      = "GET"
      auth        = false
    }
    delete_routine = {
      resource_id = aws_api_gateway_resource.routine_id.id
      method      = "DELETE"
      auth        = false
    }
    like_routine = {
      resource_id = aws_api_gateway_resource.like.id
      method      = "POST"
      auth        = false
    }
    unlike_routine = {
      resource_id = aws_api_gateway_resource.like.id
      method      = "DELETE"
      auth        = false
    }
    import_routine = {
      resource_id = aws_api_gateway_resource.import.id
      method      = "POST"
      auth        = false
    }
    get_recommendations = {
      resource_id = aws_api_gateway_resource.recommendations.id
      method      = "GET"
      auth        = false
    }
    search = {
      resource_id = aws_api_gateway_resource.search.id
      method      = "GET"
      auth        = false
    }
    post_activity = {
      resource_id = aws_api_gateway_resource.activity.id
      method      = "POST"
      auth        = false
    }
    presign_audio_upload = {
      resource_id = aws_api_gateway_resource.uploads_audio.id
      method      = "POST"
      auth        = false
    }
  }
}

resource "aws_api_gateway_method" "route" {
  for_each = local.routes

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value.resource_id
  http_method   = each.value.method
  authorization = each.value.auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = each.value.auth ? aws_api_gateway_authorizer.cognito.id : null
}

resource "aws_api_gateway_integration" "route" {
  for_each = local.routes

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.route[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns[each.key]
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = local.routes

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names[each.key]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Hash method auth/routing only — integration URIs change when Lambda versions publish
  # and must not force a replacement mid-apply (provider inconsistent plan bug).
  triggers = {
    redeployment = sha1(jsonencode({
      for k, m in aws_api_gateway_method.route : k => {
        authorization = m.authorization
        authorizer_id = m.authorizer_id
        http_method   = m.http_method
        resource_id   = m.resource_id
      }
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.route,
    aws_api_gateway_method.route,
  ]
}

resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "v1"

  xray_tracing_enabled = true

  depends_on = [aws_api_gateway_account.main]
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-apigw-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = false
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  depends_on = [aws_api_gateway_account.main]
}

resource "aws_api_gateway_usage_plan" "main" {
  name = "${var.name_prefix}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}
