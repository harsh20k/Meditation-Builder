output "rest_api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "rest_api_name" {
  value = aws_api_gateway_rest_api.main.name
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.main.execution_arn
}

output "invoke_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "stage_domain_name" {
  value = "${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

data "aws_region" "current" {}
