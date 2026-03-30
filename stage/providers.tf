# Credentials are resolved from the environment (AWS_PROFILE=otto-management).
# The provider assumes shared-jump-box-role in the stage account so that all
# resource operations target stage while the backend (S3 + DynamoDB) uses
# management account credentials. This enables full state locking and works
# for any management account principal, not just the EC2 instance profile.
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::039914330850:role/shared-jump-box-role"
  }
}
