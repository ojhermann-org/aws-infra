resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's intermediate CA thumbprint. AWS no longer validates this for
  # GitHub's OIDC provider specifically, but the argument is still required.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name       = "shared-oidc-github-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
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

    # StringLike + wildcard covers PRs, branches, and tags from this repo.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ojhermann-org/aws-infra:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_plan" {
  name               = "github-actions-plan"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name       = "github-actions-plan"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_plan_readonly" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
