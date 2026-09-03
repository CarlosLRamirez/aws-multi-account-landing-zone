# Bootstrap: creates the S3 bucket that will hold the Terraform state for the
# rest of the landing zone. This config's OWN state stays local (no backend
# block below) — it can't store its own state in the bucket it's creating.
# Run once, rarely touched again.

terraform {
  # >= 1.10 required: the main project's backend block will use the S3
  # backend's native lockfile locking (use_lockfile), which needs 1.10+.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # SSO profile with AdministratorAccess on the management account
  # (189053741492), via IAM Identity Center. See ~/.aws/config.
  profile = "mgmt-admin"
}

# Used below to build the bucket name dynamically instead of hardcoding the
# management account ID in a file that lives in a public repo.
data "aws_caller_identity" "current" {}

# The state bucket itself. Bucket names are globally unique across all of
# AWS, so the account ID suffix avoids collisions with other AWS customers.
resource "aws_s3_bucket" "terraform_state" {
  bucket = "mylz2027-terraform-state-${data.aws_caller_identity.current.account_id}"
}

# Versioning: if a future `apply` writes a corrupted or unwanted state file,
# the previous version of the object can be restored from the bucket.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Blocks all public access at the bucket level, regardless of any bucket
# policy or ACL. State can contain sensitive values (ARNs, account IDs,
# resource IDs), so this must never be reachable from the internet.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption at rest. AES256 (SSE-S3) is AWS-managed and free, matching the
# same cost-conscious choice already made for Config/CloudTrail in ADR-002
# (no customer-managed KMS key, since there's no compliance driver for one).
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
