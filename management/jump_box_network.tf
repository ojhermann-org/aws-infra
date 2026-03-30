resource "aws_vpc" "management" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = "shared-vpc-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_subnet" "management_public" {
  vpc_id            = aws_vpc.management.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name       = "shared-subnet-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_internet_gateway" "management" {
  vpc_id = aws_vpc.management.id

  tags = {
    Name       = "shared-igw-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_route_table" "management_public" {
  vpc_id = aws_vpc.management.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.management.id
  }

  tags = {
    Name       = "shared-rtb-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

resource "aws_route_table_association" "management_public" {
  subnet_id      = aws_subnet.management_public.id
  route_table_id = aws_route_table.management_public.id
}

# No inbound rules — access is via SSM only, which does not require open ports.
# Outbound HTTPS is required for the instance to reach SSM endpoints.
resource "aws_security_group" "jump_box" {
  name        = "shared-sg-jump-box-management"
  description = "Jump box: no inbound; outbound HTTPS for SSM"
  vpc_id      = aws_vpc.management.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to SSM endpoints"
  }

  tags = {
    Name       = "shared-sg-jump-box-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}
