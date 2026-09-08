# No default on purpose — the account ID isn't secret, but this keeps the
# pattern consistent with how terraform.tfvars already holds real values
# (see terraform.tfvars.example).

variable "networking_account_id" {
  description = "Account ID of the Networking account, provisioned via Control Tower Account Factory (not Terraform — see accounts.tf). Used by the `networking` provider alias in main.tf to assume AWSControlTowerExecution in that account."
  type        = string
}
