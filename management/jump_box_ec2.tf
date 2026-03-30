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
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.management_public.id
  vpc_security_group_ids = [aws_security_group.jump_box.id]
  iam_instance_profile   = aws_iam_instance_profile.jump_box.name
  # trivy:ignore:AVD-AWS-0009 - public IP is for outbound SSM connectivity only;
  # the security group has no inbound rules so the instance is unreachable from the internet.
  associate_public_ip_address = true
  user_data_replace_on_change = true

  # Install Nix via Determinate Systems installer (daemon mode, flakes enabled by default).
  # The installer creates /etc/profile.d/nix.sh which sources nix-daemon.sh at login,
  # so nix is on PATH for all login shells without any .bashrc modifications.
  # An `otto` user is created to match the home-manager configuration; Home Manager is
  # applied as otto so the user environment is fully configured on first boot.
  # A 2 GiB swapfile is created to guard against OOM during Nix builds.
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    # Create otto user (matches home-manager config) with sudo access.
    useradd -m -s /bin/bash otto
    usermod -aG wheel otto
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm
    # Apply Home Manager as otto in a login shell so nix is on PATH via
    # /etc/profile.d/nix.sh. This fully configures the user environment on first boot.
    sudo -u otto bash -lc \
      'nix run home-manager/master -- switch --flake github:ojhermann-org/home-manager#otto@x86_64-linux --refresh'
    # Create a 2 GiB swapfile as a safety net for memory spikes during Nix builds.
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
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
    volume_size           = 30
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
