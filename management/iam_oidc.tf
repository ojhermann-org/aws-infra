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

data "aws_iam_policy_document" "github_actions_apply_assume_role" {
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

    # Restricted to main branch only — apply must never run from a PR branch.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ojhermann-org/aws-infra:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_apply" {
  name               = "github-actions-apply"
  assume_role_policy = data.aws_iam_policy_document.github_actions_apply_assume_role.json

  tags = {
    Name       = "github-actions-apply"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_apply_admin" {
  role       = aws_iam_role.github_actions_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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

# Allows the plan role to assume shared-jump-box-role in each member account
# so that tofu plan can run against dev, stage, and prod in CI.
data "aws_iam_policy_document" "github_actions_plan_assume_member_roles" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::${aws_organizations_account.dev.id}:role/shared-jump-box-role",
      "arn:aws:iam::${aws_organizations_account.stage.id}:role/shared-jump-box-role",
      "arn:aws:iam::${aws_organizations_account.prod.id}:role/shared-jump-box-role",
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_plan_assume_member_roles" {
  name   = "assume-member-account-roles"
  role   = aws_iam_role.github_actions_plan.name
  policy = data.aws_iam_policy_document.github_actions_plan_assume_member_roles.json
}
