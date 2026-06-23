output "typesense_private_ip" {
  value = aws_instance.typesense.private_ip
}

output "typesense_instance_id" {
  value = aws_instance.typesense.id
}

output "typesense_api_key_ssm_path" {
  value = aws_ssm_parameter.typesense_api_key.name
}
