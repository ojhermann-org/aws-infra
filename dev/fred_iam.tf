resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's intermediate CA thumbprint. AWS no longer validates this for
  # GitHub's OIDC provider specifically, but the argument is still required.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name       = "shared-oidc-github-dev"
    env        = "dev"
    service    = "shared"
    managed-by = "opentofu"
  }
}

data "aws_iam_policy_document" "fred_github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ojhermann-org/fred:environment:integration"]
    }
  }
}

resource "aws_iam_role" "fred_github_actions" {
  name               = "fred-github-actions"
  assume_role_policy = data.aws_iam_policy_document.fred_github_actions_assume_role.json

  tags = {
    Name       = "fred-github-actions"
    env        = "dev"
    service    = "api"
    managed-by = "opentofu"
  }
}

data "aws_iam_policy_document" "fred_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-1:916868258956:secret:fred/api-key*"]
  }
}

resource "aws_iam_role_policy" "fred_secrets" {
  name   = "fred-secrets"
  role   = aws_iam_role.fred_github_actions.name
  policy = data.aws_iam_policy_document.fred_secrets.json
}
