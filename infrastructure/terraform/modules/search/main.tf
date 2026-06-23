data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
}

resource "aws_ssm_parameter" "typesense_api_key" {
  name  = "/mb/${var.environment}/typesense/api-key"
  type  = "SecureString"
  value = var.typesense_api_key != "" ? var.typesense_api_key : "changeme-typesense-key"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_instance" "typesense" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t4g.nano"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.typesense_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl", {
    api_key_ssm_path = aws_ssm_parameter.typesense_api_key.name
    backup_bucket    = var.typesense_backup_bucket_name
    aws_region       = data.aws_region.current.name
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-typesense"
  }
}

data "aws_region" "current" {}
