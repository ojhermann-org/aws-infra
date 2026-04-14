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
    # Create otto user (matches home-manager config) with passwordless sudo.
    # AL2023 wheel requires a password; a sudoers.d entry is needed for NOPASSWD.
    useradd -m -s /bin/bash otto
    echo 'otto ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/otto
    chmod 440 /etc/sudoers.d/otto
    # Authorise the local SSH public key so `ssh jump-box` (via SSM proxy) works.
    mkdir -p /home/otto/.ssh
    chmod 700 /home/otto/.ssh
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII5hpaZcGtfgHIvJ66KhRwVJmT7KDolQBoF1hBoslsg8 ojhermann@gmail.com' > /home/otto/.ssh/authorized_keys
    chmod 600 /home/otto/.ssh/authorized_keys
    chown -R otto:otto /home/otto/.ssh
    # Remove skeleton dotfiles so Home Manager can manage them without conflict.
    rm -f /home/otto/.bash_profile /home/otto/.bashrc
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm
    # Apply Home Manager as otto in a login shell so nix is on PATH via
    # /etc/profile.d/nix.sh. This fully configures the user environment on first boot.
    sudo -u otto bash -lc \
      'nix run home-manager/master -- switch --flake github:ojhermann-org/home-manager#otto@x86_64-linux --refresh'
    # Raise the stack hard limit for the otto user to 60 MB (61440 KB).
    # The default AL2023 hard ceiling (10 MB) is too low for some tooling (e.g. Nix).
    # PAM limits cover login shells and su sessions; the systemd drop-ins cover
    # services launched by systemd (including user@.service sessions), which PAM
    # limits do not reach.
    mkdir -p /etc/security/limits.d
    cat > /etc/security/limits.d/90-otto-stack.conf <<'EOF'
otto hard stack 61440
otto soft stack 61440
EOF
    mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d
    cat > /etc/systemd/system.conf.d/stack.conf <<'EOF'
[Manager]
DefaultLimitSTACK=62914560
EOF
    cat > /etc/systemd/user.conf.d/stack.conf <<'EOF'
[Manager]
DefaultLimitSTACK=62914560
EOF
    systemctl daemon-reexec
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
