locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  lambda_handlers = {
    get_routines        = { route = "GET /routines", provisioned = 1 }
    post_routine        = { route = "POST /routines", provisioned = 0 }
    get_routine         = { route = "GET /routines/{id}", provisioned = 1 }
    delete_routine      = { route = "DELETE /routines/{id}", provisioned = 0 }
    like_routine        = { route = "POST /routines/{id}/like", provisioned = 0 }
    unlike_routine      = { route = "DELETE /routines/{id}/like", provisioned = 0 }
    import_routine      = { route = "POST /routines/{id}/import", provisioned = 0 }
    get_recommendations = { route = "GET /recommendations", provisioned = 0 }
    search              = { route = "GET /search", provisioned = 0 }
    post_activity       = { route = "POST /activity", provisioned = 0 }
    bedrock_tagger      = { route = "SQS", provisioned = 0 }
    typesense_indexer   = { route = "DynamoDB Stream", provisioned = 0 }
    like_flush          = { route = "EventBridge", provisioned = 0 }
  }

  optional_auth_handlers = ["get_routines", "get_routine", "search"]

  api_route_handlers = [
    "get_routines", "post_routine", "get_routine", "delete_routine",
    "like_routine", "unlike_routine", "import_routine", "get_recommendations",
    "search", "post_activity",
  ]

  api_lambda_invoke_arns = {
    for k in local.api_route_handlers : k => aws_lambda_function.handlers[k].invoke_arn
  }

  api_lambda_function_names = {
    for k in local.api_route_handlers : k => aws_lambda_function.handlers[k].function_name
  }
}
