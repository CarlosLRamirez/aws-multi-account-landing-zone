# ADR-003: Guardrail Strategy (Control Tower Controls vs. Custom SCPs)

## Status

Proposed

## Context

Control Tower enabled **13 mandatory preventive controls** on the Security OU by default (verified via `list-enabled-controls`). All of them protect resources provisioned by Control Tower itself, like CloudTrail configuration, Config recording, Log Archive S3 bucket encryption/logging, and the supporting roles, Lambda functions, and SNS/CloudWatch resources that make the landing zone's own guardrails work:


| No. | Control | Protects |
|---|---|---|
| 1 | Enable AWS Config in all available regions | Config recorder can't be selectively disabled in a region |
| 2 | Disallow configuration changes to AWS Config | Config recorder itself can't be reconfigured or disabled |
| 3 | Disallow changes to AWS Config Rules set up by Control Tower | Compliance rules CT deployed can't be weakened or deleted |
| 4 | Disallow modifications to AWS Config recorder S3 buckets managed by CT | Where Config data lands can't be altered |
| 5 | Disallow modifications to S3 buckets managed by CT | CloudTrail/Config log buckets broadly protected |
| 6 | Disallow changes to CloudWatch set up by Control Tower | CT's compliance-monitoring alarms and dashboards protected |
| 7 | Disallow changes to CloudWatch Logs Log Groups | Log groups holding the audit trail can't be tampered with |
| 8 | Disallow changes to Amazon SNS set up by Control Tower | CT's alert notification topics protected |
| 9 | Disallow changes to Amazon SNS subscriptions set up by Control Tower | Who receives those alerts can't be silently changed |
| 10 | Disallow changes to Amazon SNS subscriptions and topics managed by CT | Broader variant covering both topics and subscriptions together |
| 11 | Disallow changes to Lambda functions set up by Control Tower | Automation behind CT's guardrails can't be altered |
| 12 | Disallow changes to IAM roles set up by AWS Control Tower and AWS CloudFormation | Service roles CT depends on to function are protected |
| 13 | Deny access to AWS based on the requested Region (`AWS-GR_REGION_DENY`) | Blocks API calls outside the landing zone's governed regions |


None of these govern actual user workloads deployed *on top of* the landing zone, we need to implement custom SCPs for that purpose.

This landing zone is a personal lab and portfolio project, built to resemble a real enterprise environment rather than to host one. The SCPs proposed here reflect that: enterprise-grade governance criteria, kept intentionally minimal, and constrained to policies that cost $0 or effectively $0 to run.


## Decision

Implement three custom SCPs via Terraform (`aws_organizations_policy`+ `aws_organizations_policy_attachment` resources), each targeting a specific OU based on where the risk it addresses actually applies.

A fourth candidate — a region-restriction SCP — was considered and rejected: Control Tower's own mandatory control (`AWS-GR_REGION_DENY`,
control #13 in this landing zone's baseline, see ADR-002) already
enforces a region allowlist based on which regions are governed.
A custom SCP attempting to widen that allowlist would have no effect
— SCPs only add restriction, they can't override a mandatory deny —
so the only real way to permit a new region (e.g. for a future DR
lab) is to add it as a governed region in Control Tower itself, not
to author a parallel SCP. See "Alternatives Considered" for the full
reasoning.

### 1. Restricted EC2 instance types (cost guardrail)

**Applies to:** Sandbox OU, Dev OU.

**Denies:** `ec2:RunInstances` unless the requested instance type is
in an approved list of low-cost types (e.g. `t3.micro`, `t3.small`,
`t2.micro`).

**Why:** prevents an accidental expensive instance launch (a
mistyped instance type, a copy-pasted example from documentation
using a GPU or large memory-optimized instance) in low-stakes
environments where there's no legitimate reason to need that
capacity. Deliberately not applied to Prod OU — a production
workload may have a real reason to need a larger instance type, and
that decision belongs in that environment's own review process, not
a blanket org-wide restriction.

### 2. Deny Transit Gateway creation

**Applies to:** Sandbox OU, Dev OU.

**Denies:** `ec2:CreateTransitGateway`,
`ec2:CreateTransitGatewayVpcAttachment`.

**Why:** operationalizes the decision already made in ADR-004 (VPC
Peering over Transit Gateway at current scale) by making it
structurally enforced rather than a decision that only lives in a
document nobody re-checks. Transit Gateway carries meaningful
per-hour and per-GB costs; blocking its creation in low-stakes OUs
prevents it from being spun up experimentally and forgotten.
Intentionally not applied to Infrastructure OU or Prod, since
Transit Gateway may become the correct choice there as this
landing zone grows past the account count where VPC Peering's
full-mesh topology stops scaling — see ADR-004's "Alternatives
Considered."

### 3. Require mandatory resource tags

**Applies to:** all OUs except Security OU (Control Tower-managed
accounts don't need project-level tagging).

**Denies:** `ec2:RunInstances`, `rds:CreateDBInstance`,
`s3:CreateBucket` unless the request includes `Project` and
`Environment` tags.

**Why:** this is the one SCP here driven by an actual future need,
not just risk prevention — this landing zone is intended to host
multiple future projects (per its long-term purpose, not just this
portfolio exercise). Without enforced tagging from day one, cost
allocation and resource ownership across projects becomes
unrecoverable after the fact. Cheaper to enforce structurally now,
before any real workload exists, than to retrofit tagging discipline
onto existing resources later.




## Consequences

**Positive:** closes the actual gap left by Control Tower's default controls — workloads get baseline protection instead of relying on discipline alone. Root-level policies (deny root, deny leave-org) apply automatically to every future account added under any OU, with no per-account setup.

**Negative:** these 3 SCPs need to be written, tested in Policy Staging OU, and maintained in Terraform — unlike Control Tower's controls, they don't get updated by AWS automatically if best practices change.

## Alternatives Considered

- **Wait and add SCPs only when a real workload account exists.** Rejected — the org-wide policies (deny root, deny leave-org) cost nothing to have in place early and protect every account created from that point forward, including this project's own accounts.
- **Recreate everything Control Tower's 13 controls already do, as custom SCPs, for full visibility in Terraform.** Rejected — redundant and risks drifting from CT-managed policies over time; the platform already owns and maintains that layer.
