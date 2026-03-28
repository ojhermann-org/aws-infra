# No profile is set here — credentials are resolved from the environment.
# Locally: run `aws sso login --profile otto-management` and set AWS_PROFILE=otto-management.
# In CI: credentials are injected automatically via the GitHub Actions OIDC role.
provider "aws" {
  region = "us-east-1"
}
