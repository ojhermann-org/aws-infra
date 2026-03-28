terraform {
  backend "s3" {
    bucket         = "ojhermann-tofu-state"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ojhermann-tofu-locks"
    encrypt        = true
  }
}
