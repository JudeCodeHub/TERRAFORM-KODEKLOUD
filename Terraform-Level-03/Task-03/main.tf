 
locals {
  # Sanitize project name
  project_name = trim(
    replace(
      replace(lower(var.KKE_PROJECT), "/[^a-z0-9-]+/", "-"),
      "/-+/",
      "-"
    ),
    "-"
  )

  # Sanitize team name
  team_name = trim(
    replace(
      replace(lower(var.KKE_TEAM), "_", "-"),
      "/-+/",
      "-"
    ),
    "-"
  )

  # Common resource name prefix
  resource_prefix = "${local.project_name}-${local.team_name}"

  # Common tags for IAM resources
  common_tags = {
    Project  = var.KKE_PROJECT
    Team     = var.KKE_TEAM
    ManagedBy = "Terraform"
    Env      = var.KKE_ENVIRONMENT
  }
}

# IAM User
resource "aws_iam_user" "nautilus_user" {
  name = "${local.resource_prefix}-user"

  tags = local.common_tags
}

# IAM Role
resource "aws_iam_role" "nautilus_role" {
  name = "${local.resource_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      RoleType = "EC2"
    }
  )
}
