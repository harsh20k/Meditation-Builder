output "bedrock_tagging_queue_arn" {
  value = aws_sqs_queue.bedrock_tagging.arn
}

output "bedrock_tagging_queue_url" {
  value = aws_sqs_queue.bedrock_tagging.url
}

output "bedrock_tagging_queue_name" {
  value = aws_sqs_queue.bedrock_tagging.name
}

output "bedrock_tagging_dlq_name" {
  value = aws_sqs_queue.bedrock_tagging_dlq.name
}

output "like_notifications_topic_arn" {
  value = aws_sns_topic.like_notifications.arn
}
