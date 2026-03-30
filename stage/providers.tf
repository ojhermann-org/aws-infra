# No profile is set here — credentials are resolved from the environment.
# Locally: run `aws sso login --profile otto-stage` and set AWS_PROFILE=otto-stage.
# On the jump box: set AWS_PROFILE=otto-stage (uses cross-account role assumption).
provider "aws" {
  region = "us-east-1"
}
