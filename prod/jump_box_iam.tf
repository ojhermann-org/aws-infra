# Allows any principal in the management account with sts:AssumeRole permission
# to assume this role. This covers both the EC2 jump box instance profile and
# management account SSO users running tofu locally.
data "aws_iam_policy_document" "jump_box_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::324621155013:root"]
    }
  }
}

resource "aws_iam_role" "jump_box" {
  name               = "shared-jump-box-role"
  assume_role_policy = data.aws_iam_policy_document.jump_box_trust.json

  tags = {
    Name       = "shared-jump-box-role"
    env        = "prod"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_iam_role_policy_attachment" "jump_box_admin" {
  role       = aws_iam_role.jump_box.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
