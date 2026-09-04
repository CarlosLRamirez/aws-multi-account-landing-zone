# No defaults for account emails on purpose — real personal email addresses
# don't belong hardcoded in version-controlled .tf files. Supply real values
# via terraform.tfvars (gitignored); see terraform.tfvars.example.

variable "networking_account_email" {
  description = "Email for the Networking account. Must be an email never used on any other AWS account."
  type        = string
}
