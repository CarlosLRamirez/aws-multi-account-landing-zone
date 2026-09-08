# Main landing zone project. Unlike terraform/bootstrap/ (local state, one-time
# use), this config's state lives remotely in the bucket the bootstrap created,
# so it can eventually be shared safely across machines/sessions with locking.
#
# Scope (see ADR-005): OUs not managed by Control Tower, the 3 custom SCPs and
# their attachments, and future non-Control-Tower-managed account provisioning.
# Anything Control Tower owns (LogArchive, Aggregator account, the Security OU's
# 13 preventive controls) stays out of this state — read-only/observed, never
# authored here.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # bucket/key/region can't use variables or data sources here — backend
  # blocks are resolved before any provider or data source, so this has to
  # be literal. Bucket name comes from the bootstrap's `state_bucket_name`
  # output.
  backend "s3" {
    bucket       = "mylz2027-terraform-state-189053741492"
    key          = "landing-zone/terraform.tfstate"
    region       = "us-east-1"
    profile      = "mgmt-admin"
    use_lockfile = true
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "mgmt-admin"
}

# Cross-account providers, one alias per member account that needs resources
# created directly in it (ADR-004/ADR-005: assume-role from the management
# account's own state, rather than a separate Terraform root/backend per
# account — one apply can reach every account this project manages).
#
# Networking was created via `aws_organizations_account` (accounts.tf), not
# Account Factory, so it only has the default `OrganizationAccountAccessRole`
# that Organizations grants the management account on every member account it
# creates — not Control Tower's `AWSControlTowerExecution` role. Accounts
# created later via Account Factory (Dev/Staging/Prod) will need their own
# alias using that CT role instead.
provider "aws" {
  alias  = "networking"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::${aws_organizations_account.networking.id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-mgmt-networking"
  }

  profile = "mgmt-admin"
}

