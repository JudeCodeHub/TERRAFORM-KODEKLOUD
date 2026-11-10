
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
