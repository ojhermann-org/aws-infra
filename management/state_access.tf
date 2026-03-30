# Grants member accounts cross-account access to the shared state bucket and
# DynamoDB lock table. Required so that dev/, stage/, and prod/ can be
# initialized and applied using their respective AWS profiles.

locals {
  member_account_ids = [
    aws_organizations_account.dev.id,
    aws_organizations_account.stage.id,
    aws_organizations_account.prod.id,
  ]
}

data "aws_iam_policy_document" "state_bucket_cross_account" {
  statement {
    sid     = "MemberAccountStateAccess"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    principals {
      type        = "AWS"
      identifiers = [for id in local.member_account_ids : "arn:aws:iam::${id}:root"]
    }
    resources = [
      "arn:aws:s3:::ojhermann-tofu-state",
      "arn:aws:s3:::ojhermann-tofu-state/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "state_cross_account" {
  bucket = "ojhermann-tofu-state"
  policy = data.aws_iam_policy_document.state_bucket_cross_account.json
}
