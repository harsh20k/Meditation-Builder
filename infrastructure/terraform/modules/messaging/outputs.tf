output "bedrock_tagging_queue_arn" {
  value = aws_sqs_queue.bedrock_tagging.arn
}

output "bedrock_tagging_queue_url" {
  value = aws_sqs_queue.bedrock_tagging.url
}

output "like_notifications_topic_arn" {
  value = aws_sns_topic.like_notifications.arn
}
