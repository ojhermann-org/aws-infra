data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jump_box" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.management_public.id
  vpc_security_group_ids = [aws_security_group.jump_box.id]
  iam_instance_profile   = aws_iam_instance_profile.jump_box.name
  # trivy:ignore:AVD-AWS-0009 - public IP is for outbound SSM connectivity only;
  # the security group has no inbound rules so the instance is unreachable from the internet.
  associate_public_ip_address = true

  # Install Nix via Determinate Systems installer (daemon mode, flakes enabled by default).
  # Home Manager is applied separately by the user via ojhermann-org/home-manager.
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm
  EOT
  )

  # IMDSv2 required — prevents SSRF-based metadata credential theft.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  # Prevent spurious instance replacement when a newer AL2023 AMI is released.
  # To intentionally upgrade the AMI: remove this ignore, run apply, then restore it.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name       = "shared-jump-box-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}
