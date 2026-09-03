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
