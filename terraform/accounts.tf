# Accounts provisioned directly through Organizations rather than through
# Control Tower's Account Factory. Per ADR-005, this is Terraform's scope for
# account provisioning going forward: non-Control-Tower-managed accounts.
#
# A plain Organizations account created this way has no Control Tower
# baseline attached (no CloudTrail/Config guardrails, no automatic Identity
# Center assignment) until it's separately enrolled via Account Factory —
# which is a deliberate, later decision, not something this resource does.
# That also means it costs effectively $0 the moment it's created: no Config
# Recorder running yet, unlike an Account-Factory-enrolled account.

resource "aws_organizations_account" "networking" {
  name      = "Networking"
  email     = var.networking_account_email
  parent_id = aws_organizations_organizational_unit.infrastructure.id

  # Lets `terraform destroy` actually close the account instead of just
  # dropping it from Organizations management and leaving it to orphan.
  close_on_deletion = true
}
