# Allows the management account jump box to assume this role.
data "aws_iam_policy_document" "jump_box_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::324621155013:role/shared-jump-box-management"]
    }
  }
}

resource "aws_iam_role" "jump_box" {
  name               = "shared-jump-box-role"
  assume_role_policy = data.aws_iam_policy_document.jump_box_trust.json

  tags = {
    Name       = "shared-jump-box-role"
    env        = "dev"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_iam_role_policy_attachment" "jump_box_admin" {
  role       = aws_iam_role.jump_box.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
