output "lambda_role_arns" {
  value = { for k, v in aws_iam_role.lambda : k => v.arn }
}

output "lambda_role_names" {
  value = { for k, v in aws_iam_role.lambda : k => v.name }
}
