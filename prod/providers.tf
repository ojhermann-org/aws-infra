# No profile is set here — credentials are resolved from the environment.
# Locally: run `aws sso login --profile otto-prod` and set AWS_PROFILE=otto-prod.
# On the jump box: set AWS_PROFILE=otto-prod (uses cross-account role assumption).
provider "aws" {
  region = "us-east-1"
}
