data "aws_iam_policy_document" "jump_box_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jump_box" {
  name               = "shared-jump-box-management"
  assume_role_policy = data.aws_iam_policy_document.jump_box_assume_role.json

  tags = {
    Name       = "shared-jump-box-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

# Enables SSM Session Manager — replaces SSH, no open ports required.
resource "aws_iam_role_policy_attachment" "jump_box_ssm" {
  role       = aws_iam_role.jump_box.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Full admin on the management account, matching the current SSO permission set.
resource "aws_iam_role_policy_attachment" "jump_box_admin" {
  role       = aws_iam_role.jump_box.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Explicit cross-account assume-role permissions for each member account.
# AdministratorAccess technically covers sts:AssumeRole, but this makes the
# intended cross-account access surface explicit and easy to audit.
data "aws_iam_policy_document" "jump_box_cross_account" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::${aws_organizations_account.dev.id}:role/shared-jump-box-role",
      "arn:aws:iam::${aws_organizations_account.stage.id}:role/shared-jump-box-role",
      "arn:aws:iam::${aws_organizations_account.prod.id}:role/shared-jump-box-role",
    ]
  }
}

resource "aws_iam_role_policy" "jump_box_cross_account" {
  name   = "cross-account-assume-role"
  role   = aws_iam_role.jump_box.name
  policy = data.aws_iam_policy_document.jump_box_cross_account.json
}

# Allows the SSM agent to stream session output to CloudWatch Logs.
data "aws_iam_policy_document" "jump_box_ssm_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.ssm_sessions.arn}:*"]
  }
}

resource "aws_iam_role_policy" "jump_box_ssm_logs" {
  name   = "ssm-session-logs"
  role   = aws_iam_role.jump_box.name
  policy = data.aws_iam_policy_document.jump_box_ssm_logs.json
}

resource "aws_iam_instance_profile" "jump_box" {
  name = "shared-jump-box-management"
  role = aws_iam_role.jump_box.name

  tags = {
    Name       = "shared-jump-box-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}
