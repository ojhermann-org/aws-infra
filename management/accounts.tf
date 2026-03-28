# AWS Organizations accounts cannot be deleted once created — removing a
# resource from state closes the account, which is irreversible. Handle
# with care.

resource "aws_organizations_account" "dev" {
  name      = "ojhermann-dev"
  email     = "amazon.finally422+dev@passmail.net"
  parent_id = aws_organizations_organizational_unit.sdlc.id

  tags = {
    Name       = "ojhermann-dev"
    env        = "dev"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_organizations_account" "stage" {
  name      = "ojhermann-stage"
  email     = "amazon.finally422+stage@passmail.net"
  parent_id = aws_organizations_organizational_unit.sdlc.id

  tags = {
    Name       = "ojhermann-stage"
    env        = "stage"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_organizations_account" "prod" {
  name      = "ojhermann-prod"
  email     = "amazon.finally422+prod@passmail.net"
  parent_id = aws_organizations_organizational_unit.prod.id

  tags = {
    Name       = "ojhermann-prod"
    env        = "prod"
    service    = "shared"
    managed-by = "opentofu"
  }
}
