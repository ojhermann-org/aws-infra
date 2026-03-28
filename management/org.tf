data "aws_organizations_organization" "current" {}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.current.roots[0].id

  tags = {
    Name       = "shared-workloads-ou"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_organizations_organizational_unit" "sdlc" {
  name      = "SDLC"
  parent_id = aws_organizations_organizational_unit.workloads.id

  tags = {
    Name       = "shared-sdlc-ou"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id

  tags = {
    Name       = "shared-prod-ou"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}
