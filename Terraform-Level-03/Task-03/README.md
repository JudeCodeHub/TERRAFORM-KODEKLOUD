# Create Convention-Based IAM Resources Using Terraform

## Task Description

The Nautilus DevOps team is adopting strict naming conventions for IAM resources managed with Terraform. This task creates an IAM user and an IAM role whose names are derived from project and team inputs using lowercase, hyphenated naming.

## Requirements

- Create an IAM user named using the format `project-team-user`.
- Create an IAM role named using the format `project-team-role`.
- Convert project and team inputs to lowercase.
- Replace unsupported characters with hyphens and normalize repeated hyphens.
- Configure the IAM role trust policy so EC2 can assume it through STS.
- Apply these tags to both IAM resources:
  - `Project`: `nautilus`
  - `Team`: `dev-team`
  - `ManagedBy`: `Terraform`
  - `Env`: `dev`
- Apply the additional `RoleType: EC2` tag to the IAM role.
- Define locals in `main.tf` for sanitized names, the resource prefix, and reusable common tags.
- Define variables in `variables.tf`:
  - `KKE_PROJECT`: Project name; must be non-empty.
  - `KKE_TEAM`: Team name; may contain only letters, digits, dashes, or underscores.
  - `KKE_ENVIRONMENT`: Environment name.
- Assign input values in `terraform.tfvars`.
- Define these outputs in `outputs.tf`:
  - `kke_user_name`: Name of the created IAM user.
  - `kke_role_name`: Name of the created IAM role.
  - `kke_tags_applied`: Tags applied to the IAM user.
- The Terraform working directory is `/home/bob/terraform`.

## Expected Resource Names

With the provided values:

```text
Project:     nautilus
Team:        dev-team
Environment: dev
IAM user:    nautilus-dev-team-user
IAM role:    nautilus-dev-team-role
```

## Terraform Files

### `variables.tf`

Declare and validate the task inputs:

```hcl
variable "KKE_PROJECT" {
	description = "Project name"
	type        = string

	validation {
		condition     = length(trimspace(var.KKE_PROJECT)) > 0
		error_message = "KKE_PROJECT must not be empty."
	}
}

variable "KKE_TEAM" {
	description = "Team name"
	type        = string

	validation {
		condition     = can(regex("^[A-Za-z0-9_-]+$", var.KKE_TEAM))
		error_message = "KKE_TEAM can contain only letters, digits, dashes, or underscores."
	}
}

variable "KKE_ENVIRONMENT" {
	description = "Environment name"
	type        = string
}
```

### `terraform.tfvars`

Use the required task values:

```hcl
KKE_PROJECT     = "nautilus"
KKE_TEAM        = "dev-team"
KKE_ENVIRONMENT = "dev"
```

### `main.tf`

Use locals to sanitize the inputs, build a reusable name prefix, and define common tags. The IAM role uses an EC2 assume role policy and receives the additional `RoleType` tag:

```hcl
locals {
	project_name = trim(
		replace(
			replace(lower(var.KKE_PROJECT), "/[^a-z0-9-]+/", "-"),
			"/-+/",
			"-"
		),
		"-"
	)

	team_name = trim(
		replace(
			replace(lower(var.KKE_TEAM), "_", "-"),
			"/-+/",
			"-"
		),
		"-"
	)

	resource_prefix = "${local.project_name}-${local.team_name}"

	common_tags = {
		Project  = var.KKE_PROJECT
		Team     = var.KKE_TEAM
		ManagedBy = "Terraform"
		Env      = var.KKE_ENVIRONMENT
	}
}

resource "aws_iam_user" "nautilus_user" {
	name = "${local.resource_prefix}-user"
	tags = local.common_tags
}

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
```

### `outputs.tf`

Expose the created resource names and the IAM user tags:

```hcl
output "kke_user_name" {
	description = "Name of the created IAM user"
	value       = aws_iam_user.nautilus_user.name
}

output "kke_role_name" {
	description = "Name of the created IAM role"
	value       = aws_iam_role.nautilus_role.name
}

output "kke_tags_applied" {
	description = "Tags applied to the IAM user"
	value       = aws_iam_user.nautilus_user.tags
}
```

## Validation and Verification

Run the following commands from the Terraform working directory:

```bash
cd /home/bob/terraform
terraform init
terraform validate
terraform plan
```

Before submitting the task, confirm that the plan reports:

```text
No changes. Your infrastructure matches the configuration.
```

Review the outputs and verify the IAM resources and tags:

```bash
terraform output
aws iam get-user --user-name nautilus-dev-team-user
aws iam get-role --role-name nautilus-dev-team-role
aws iam list-user-tags --user-name nautilus-dev-team-user
aws iam list-role-tags --role-name nautilus-dev-team-role
```
