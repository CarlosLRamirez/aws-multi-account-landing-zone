# OUs not managed by Control Tower (ADR-001, ADR-005). Security OU and its
# accounts stay out of this file entirely — Control Tower owns that lifecycle.
#
# These resources describe OUs that already exist (created manually). They
# are meant to be adopted via `terraform import`, not created fresh — the
# goal is a clean `terraform plan` with zero changes once imported.

# Root itself is never a Terraform resource — it's the fixed entry point of
# the Organization, not something Terraform creates or destroys. Its Id is
# hardcoded here only as the `parent_id` for top-level OUs.

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = "r-wfup"
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = "r-wfup"
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = "r-wfup"
}

# Dev/Staging/Prod reference workloads.id instead of hardcoding its OU Id, so
# Terraform understands the parent-child relationship (if Workloads ever had
# to be recreated, Terraform would know these three depend on it).
resource "aws_organizations_organizational_unit" "dev" {
  name      = "Dev"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "staging" {
  name      = "Staging"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "policy_staging" {
  name      = "Policy Staging"
  parent_id = "r-wfup"
}
