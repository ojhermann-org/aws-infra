resource "aws_s3_bucket" "state" {
  bucket = "ojhermann-tofu-state-dev"

  tags = {
    Name       = "ojhermann-tofu-state-dev"
    env        = "dev"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "ojhermann-tofu-locks-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name       = "ojhermann-tofu-locks-dev"
    env        = "dev"
    service    = "shared"
    managed-by = "opentofu"
  }
}
