# The 3 custom SCPs from ADR-003. Excludes the `aws-guardrails-*` policies —
# those are Control Tower's own preventive controls on the Security OU and
# stay out of Terraform entirely (ADR-005).
#
# These describe policies that already exist and were already tested
# manually in Policy Staging, meant to be adopted via `terraform import`.
#
# Deliberately no aws_organizations_policy_attachment resources yet: in AWS
# right now these 3 policies exist detached (tested, then detached from
# Policy Staging). Attaching them to their real target OUs is a genuine
# behavior change — activating the guardrail org-wide — so that's a separate,
# explicit step, not bundled into "adopt what already exists."

# content = file(...) instead of inline JSON so the already-tested documents
# under policies/ stay the single source of truth — Terraform reads them
# directly rather than duplicating the policy text here.

resource "aws_organizations_policy" "restrict_ec2_types" {
  name        = "scp-restrict-ec2-instance-types"
  description = "Deny EC2 instance types outside the approved low-cost allowlist"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-1-restricted-ec2-instance-types.json")
}

resource "aws_organizations_policy" "deny_transit_gateway" {
  name        = "scp-deny-transit-gateway"
  description = "Deny Transit Gateway creation"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-2-deny-transit-gateway.json")
}

resource "aws_organizations_policy" "require_mandatory_tags" {
  name        = "scp-require-mandatory-tags"
  description = "Deny EC2/RDS/S3 creation without Project and Environment tags"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/../policies/scp-3-require-mandatory-tags.json")
}
