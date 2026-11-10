
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
