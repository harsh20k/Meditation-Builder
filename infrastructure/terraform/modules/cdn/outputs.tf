output "api_distribution_id" {
  value = aws_cloudfront_distribution.api.id
}

output "api_distribution_domain_name" {
  value = aws_cloudfront_distribution.api.domain_name
}

output "audio_distribution_id" {
  value = aws_cloudfront_distribution.audio.id
}

output "audio_distribution_domain_name" {
  value = aws_cloudfront_distribution.audio.domain_name
}
