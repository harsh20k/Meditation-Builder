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

resource "aws_iam_role" "typesense" {
  name = "${var.name_prefix}-typesense-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.name_prefix}-typesense-role"
  }
}

resource "aws_iam_role_policy" "typesense" {
  name = "${var.name_prefix}-typesense-policy"
  role = aws_iam_role.typesense.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = aws_ssm_parameter.typesense_api_key.arn
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${var.typesense_backup_bucket_name}",
          "arn:aws:s3:::${var.typesense_backup_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "typesense_ssm" {
  role       = aws_iam_role.typesense.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "typesense" {
  name = "${var.name_prefix}-typesense-profile"
  role = aws_iam_role.typesense.name
}

resource "aws_instance" "typesense" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t4g.nano"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.typesense_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.typesense.name

  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl", {
    api_key_ssm_path = aws_ssm_parameter.typesense_api_key.name
    backup_bucket    = var.typesense_backup_bucket_name
    aws_region       = data.aws_region.current.name
  }))

  user_data_replace_on_change = true

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
