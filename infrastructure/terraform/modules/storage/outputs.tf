output "dynamodb_table_name" {
  value = aws_dynamodb_table.community.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.community.arn
}

output "dynamodb_stream_arn" {
  value = aws_dynamodb_table.community.stream_arn
}

output "audio_bucket_name" {
  value = aws_s3_bucket.audio.id
}

output "audio_bucket_arn" {
  value = aws_s3_bucket.audio.arn
}

output "typesense_backup_bucket_name" {
  value = aws_s3_bucket.typesense_backups.id
}

output "typesense_backup_bucket_arn" {
  value = aws_s3_bucket.typesense_backups.arn
}
