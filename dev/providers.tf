# No profile is set here — credentials are resolved from the environment.
# Locally: run `aws sso login --profile otto-dev` and set AWS_PROFILE=otto-dev.
# On the jump box: set AWS_PROFILE=otto-dev (uses cross-account role assumption).
provider "aws" {
  region = "us-east-1"
}
