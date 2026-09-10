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

# Attachments — the actual guardrail-activation step, kept separate from the
# resources above (see ADR-003 for the narrowed target-OU decision).
#
# Mandatory tags attaches once at Workloads: SCPs inherit down the OU tree,
# so Dev/Staging/Prod get it without a separate attachment each. Restrict EC2
# types attaches directly to Dev, Staging, and Sandbox — Prod is deliberately
# excluded (ADR-003).
#
# Deny TGW is the one exception: it attaches to every OU except Security
# (Infrastructure, Sandbox, Workloads, Policy Staging) with no carve-out for
# the Networking account, per ADR-004 — the whole point is no silent
# exception for the one account that looks like the natural place to build
# a Transit Gateway.

resource "aws_organizations_policy_attachment" "deny_transit_gateway_infrastructure" {
  policy_id = aws_organizations_policy.deny_transit_gateway.id
  target_id = aws_organizations_organizational_unit.infrastructure.id
}

resource "aws_organizations_policy_attachment" "deny_transit_gateway_sandbox" {
  policy_id = aws_organizations_policy.deny_transit_gateway.id
  target_id = aws_organizations_organizational_unit.sandbox.id
}

resource "aws_organizations_policy_attachment" "deny_transit_gateway_workloads" {
  policy_id = aws_organizations_policy.deny_transit_gateway.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "deny_transit_gateway_policy_staging" {
  policy_id = aws_organizations_policy.deny_transit_gateway.id
  target_id = aws_organizations_organizational_unit.policy_staging.id
}

resource "aws_organizations_policy_attachment" "require_mandatory_tags_workloads" {
  policy_id = aws_organizations_policy.require_mandatory_tags.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "restrict_ec2_types_dev" {
  policy_id = aws_organizations_policy.restrict_ec2_types.id
  target_id = aws_organizations_organizational_unit.dev.id
}

resource "aws_organizations_policy_attachment" "restrict_ec2_types_staging" {
  policy_id = aws_organizations_policy.restrict_ec2_types.id
  target_id = aws_organizations_organizational_unit.staging.id
}

resource "aws_organizations_policy_attachment" "restrict_ec2_types_sandbox" {
  policy_id = aws_organizations_policy.restrict_ec2_types.id
  target_id = aws_organizations_organizational_unit.sandbox.id
}
