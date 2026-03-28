data "aws_ssoadmin_instances" "main" {}

data "aws_ssoadmin_permission_set" "administrator" {
  instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name         = "AdministratorAccess"
}

data "aws_identitystore_group" "admins" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "admins"
    }
  }
}

resource "aws_ssoadmin_account_assignment" "dev_admins" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.administrator.arn
  principal_id       = data.aws_identitystore_group.admins.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.dev.id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "stage_admins" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.administrator.arn
  principal_id       = data.aws_identitystore_group.admins.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.stage.id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "prod_admins" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.administrator.arn
  principal_id       = data.aws_identitystore_group.admins.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.prod.id
  target_type        = "AWS_ACCOUNT"
}
