output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}

output "typesense_security_group_id" {
  value = aws_security_group.typesense.id
}
