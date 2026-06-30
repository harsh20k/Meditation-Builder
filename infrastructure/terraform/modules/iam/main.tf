data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bedrock_model_arns = [
    "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
    "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/amazon.titan-embed-text-v2:0",
    "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0",
  ]
}

resource "aws_iam_role" "lambda" {
  for_each = var.handlers

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  for_each = var.handlers

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  for_each = var.handlers

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  for_each = var.handlers

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = toset([
    "get_routines", "post_routine", "get_routine", "delete_routine",
    "like_routine", "unlike_routine", "import_routine", "get_recommendations",
    "post_activity", "bedrock_tagger", "typesense_indexer", "like_flush",
  ])

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-dynamodb"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
        "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:BatchGetItem",
        "dynamodb:TransactWriteItems", "dynamodb:Scan",
      ]
      Resource = [
        var.dynamodb_table_arn,
        "${var.dynamodb_table_arn}/index/*",
      ]
    }]
  })
}

resource "aws_iam_role_policy" "lambda_s3" {
  for_each = toset(["post_routine", "delete_routine", "import_routine", "presign_audio_upload"])

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-s3"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:HeadObject"]
      Resource = "${var.audio_bucket_arn}/*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_sqs_send" {
  name = "${var.name_prefix}-post-routine-sqs"
  role = aws_iam_role.lambda["post_routine"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = var.bedrock_tagging_queue_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_sqs_consume" {
  name = "${var.name_prefix}-bedrock-tagger-sqs"
  role = aws_iam_role.lambda["bedrock_tagger"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = var.bedrock_tagging_queue_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_sns_publish" {
  name = "${var.name_prefix}-like-routine-sns"
  role = aws_iam_role.lambda["like_routine"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = var.like_notifications_topic_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_bedrock" {
  for_each = toset(["bedrock_tagger", "get_recommendations"])

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-bedrock"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = local.bedrock_model_arns
    }]
  })
}

resource "aws_iam_role_policy" "lambda_cloudfront" {
  for_each = toset(["post_routine", "delete_routine"])

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-cloudfront"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudfront:CreateInvalidation"]
      Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_stream" {
  name = "${var.name_prefix}-typesense-indexer-stream"
  role = aws_iam_role.lambda["typesense_indexer"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetRecords", "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream", "dynamodb:ListStreams",
      ]
      Resource = var.dynamodb_stream_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ssm" {
  for_each = toset(["search", "typesense_indexer", "get_recommendations", "delete_routine", "bedrock_tagger", "post_routine", "import_routine"])

  name = "${var.name_prefix}-${replace(each.key, "_", "-")}-ssm"
  role = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/mb/${var.environment}/*"
    }]
  })
}
