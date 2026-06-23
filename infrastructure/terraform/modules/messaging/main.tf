resource "aws_sqs_queue" "bedrock_tagging_dlq" {
  name = "${var.name_prefix}-bedrock-tagging-dlq"

  tags = {
    Name = "${var.name_prefix}-bedrock-tagging-dlq"
  }
}

resource "aws_sqs_queue" "bedrock_tagging" {
  name = "${var.name_prefix}-bedrock-tagging"

  visibility_timeout_seconds = 120
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bedrock_tagging_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.name_prefix}-bedrock-tagging"
  }
}

resource "aws_sns_topic" "like_notifications" {
  name = "${var.name_prefix}-like-notifications"

  tags = {
    Name = "${var.name_prefix}-like-notifications"
  }
}
