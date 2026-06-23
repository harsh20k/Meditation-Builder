resource "aws_dynamodb_table" "community" {
  name         = "${var.name_prefix}-community"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "publishedAt"
    type = "S"
  }

  attribute {
    name = "GSI2PK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1-public-by-date"
    hash_key        = "GSI1PK"
    range_key       = "publishedAt"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "routineId",
      "name",
      "authorName",
      "durationSeconds",
      "tags",
      "likeCount",
      "importCount",
    ]
  }

  global_secondary_index {
    name            = "GSI2-author-routines"
    hash_key        = "GSI2PK"
    range_key       = "publishedAt"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = "${var.name_prefix}-community"
  }
}

resource "aws_s3_bucket" "audio" {
  bucket = "${var.name_prefix}-audio-assets"

  tags = {
    Name = "${var.name_prefix}-audio-assets"
  }
}

resource "aws_s3_bucket_versioning" "audio" {
  bucket = aws_s3_bucket.audio.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audio" {
  bucket = aws_s3_bucket.audio.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audio" {
  bucket = aws_s3_bucket.audio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "audio" {
  bucket = aws_s3_bucket.audio.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket" "typesense_backups" {
  bucket = "${var.name_prefix}-typesense-backups"

  tags = {
    Name = "${var.name_prefix}-typesense-backups"
  }
}

resource "aws_s3_bucket_versioning" "typesense_backups" {
  bucket = aws_s3_bucket.typesense_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "typesense_backups" {
  bucket = aws_s3_bucket.typesense_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "typesense_backups" {
  bucket = aws_s3_bucket.typesense_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
