resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/ssm/jump-box-sessions"
  retention_in_days = 90

  tags = {
    Name       = "shared-lg-ssm-sessions-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}

# Overrides SSM Session Manager defaults for all sessions on this account.
# Sets CloudWatch logging and runs sessions as ec2-user (who has the nix environment).
resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences: CloudWatch logging, run as ec2-user"
    sessionType   = "Standard_Stream"
    inputs = {
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = false
      cloudWatchStreamingEnabled  = true
      runAsEnabled                = true
      runAsDefaultUser            = "ec2-user"
    }
  })

  tags = {
    Name       = "shared-ssm-session-prefs-management"
    env        = "management"
    service    = "shared"
    managed-by = "opentofu"
  }
}
