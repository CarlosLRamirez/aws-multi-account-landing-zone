# AWS Multi-Account Landing Zone Implementation

## Overview

This repo documents building an AWS Control Tower landing zone: the implementation walkthrough, the Terraform IaC, and the ADRs behind the design decisions. It's a personal portfolio and learning lab, structured like an enterprise environment on purpose — meant as a long-term foundation for future projects, not something to spin up and tear down.

This isn't a step-by-step tutorial. It covers what got built, why, and what I'd change.

## Outcome

- An AWS Organization under Control Tower 4.0
- `LogArchive` and `Aggregator account` (Control Tower-managed) under the Security OU
- A `Networking` account under the Infrastructure OU, provisioned via Account Factory with the full Control Tower baseline, hub VPC built in Terraform
- Empty OUs reserved for what's next: Sandbox, Workloads (Dev/Staging/Prod), Policy Staging
- Control Tower's 13 default preventive controls, plus 3 custom SCPs managed in Terraform:
  - Restrict EC2 instance types (Dev, Staging, Sandbox)
  - Deny Transit Gateway creation, org-wide, no exceptions
  - Require `Project`/`Environment` tags (Workloads)
- Group-based Identity Center access (`platform-admins` / `developers` / `readonly-auditors`), no individual IAM users, `breakglass` + MFA as the emergency fallback
- A Terraform codebase covering OUs, SCPs, account provisioning, and a reusable per-account VPC module pattern — all reached from one shared backend via cross-account provider aliases

Evidence — screenshots, `terraform plan`/`apply` output, SCP test results — is linked in the Appendix.

## Architecture

```text
Root
├── Security OU
│   ├── LogArchive            # Control Tower Managed
│   └── Aggregator account    # Control Tower Managed
├── Infrastructure OU
│   ├── Shared Services       #future
│   └── Networking
├── Sandbox OU                # Labs and experimentation
├── Workloads OU              # Operational Environments
│   ├── Dev OU
│   ├── Staging OU
│   └── Prod OU
├── Policy Staging OU
└── ClosedAccounts OU
```

## Key Design Decisions

- [ADR-001: OU Structure](docs/adr/ADR-001-OU-Structure.md)
- [ADR-002: Foundational Accounts](docs/adr/ADR-002-Foundational-Accounts.md)
- [ADR-003: Guardrail Strategy](docs/adr/ADR-003-Guardrail-Strategy.md)
- [ADR-004: Networking Strategy (VPC Peering over TGW)](docs/adr/ADR-004-Networking-Strategy.md)
- [ADR-005: IaC Strategy (Terraform)](docs/adr/ADR-005-IaC-Strategy.md)
- [IP Address Plan](docs/ip-address-plan.md) — CIDR allocation and per-VPC subnet layouts (companion to ADR-004)

## Implementation Walk-through

How this actually got built, in order.

### 1. Account foundation and Control Tower

- New AWS account as the management account, MFA on root.
- Temporary IAM admin user with MFA for the initial setup, billing access enabled, Budget + CloudWatch billing alarm set up before touching anything else.
- Ran the Control Tower wizard: it created `LogArchive` (CloudTrail) and `Aggregator account` (Config).
- Created the OUs the wizard doesn't: Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging (ADR-001).
- Registered Policy Staging with Control Tower.

### 2. Identity and access hardening

- Replaced the auto-generated Identity Center user with a group model: `platform-admins`, `developers`, `readonly-auditors`, mapped to `AdministratorAccess`, `ReadOnlyAccess`, and a custom `DeveloperAccess` (EC2/S3/Lambda, `iam:PassRole` restricted to trusted services).
- Created `carlos.ramirez` (admin + developer) and `carlosvsccnp` (developer only) to test both personas, deleted the auto-generated user, and customized the portal URL.
- Replaced the bootstrap IAM user with `breakglass` + `BreakGlassAdminRole`, MFA-gated. Verified the fallback flow end to end: Identity Center is the normal path, `breakglass` + MFA is the fallback, root is recovery-only.

### 3. Guardrails: designing and testing SCPs

- Spun up an `SCP-test` account under Policy Staging to try SCPs in isolation.
- Wrote and tested 3 SCPs manually: attach to Policy Staging, test positive and negative cases in `SCP-test`, detach (ADR-003). Kept the JSON under [`policies/`](policies/):
  - SCP #1 — [Restricted EC2 instance types](policies/scp-1-restricted-ec2-instance-types.json)
  - SCP #2 — [Deny Transit Gateway creation](policies/scp-2-deny-transit-gateway.json)
  - SCP #3 — [Require mandatory resource tags](policies/scp-3-require-mandatory-tags.json)

### 4. Introducing Terraform (ADR-005)

- Bootstrapped remote state: an S3 bucket, versioned and encrypted, using native S3 lockfile locking instead of a DynamoDB table.
- Wrote `.tf` for the existing OUs and SCPs ([`terraform/ous.tf`](terraform/ous.tf), [`terraform/scps.tf`](terraform/scps.tf)), imported them so nothing got recreated, confirmed `terraform plan` showed zero changes.
- Attached the 3 SCPs to their target OUs.
- Closed `SCP-test` once the automation was verified.

### 5. Networking foundation (ADR-004)

- `Networking` account under the Infrastructure OU, provisioned via Account Factory — full Control Tower baseline (CloudTrail, Config, the 13 preventive controls) from day one.
- Hierarchical CIDR plan, one growth pool per environment — full table in [`docs/ip-address-plan.md`](docs/ip-address-plan.md).
- Hub VPC built directly in [`terraform/networking.tf`](terraform/networking.tf) — private + "public (future)" subnets across 3 AZs, no Internet Gateway yet.
- Two reusable modules written for later: [`terraform/modules/vpc-baseline`](terraform/modules/vpc-baseline) (Dev/Staging/Prod) and [`terraform/modules/vpc-sandbox`](terraform/modules/vpc-sandbox). Neither instantiated yet — those accounts don't exist.
- A `ClosedAccounts` OU holds a few closed, inert accounts (an early wizard artifact, a decommissioned test account, one earlier attempt at this account) so they're not left scattered around — Control Tower won't register an OU that contains a closed account.
- Still open: the actual VPC Peering connections to the workload VPCs.

## Provisioning a New Workload Account

The steps above cover bootstrapping this once. This is the repeatable flow for adding another account later — say, a `MyAppDev` account for a new project's Dev environment:

1. **Create the account** via Account Factory (standard path, full CT baseline) or directly via Terraform (`aws_organizations_account`, the exception — only if it deliberately shouldn't carry that baseline yet). Place it under the OU matching its environment tier; SCPs at the OU level apply automatically.
2. **Pick its CIDR** from the pool reserved for that environment ([`docs/ip-address-plan.md`](docs/ip-address-plan.md) reserves 8 slots per tier). Mark the slot as used.
3. **Add a provider alias** in `main.tf` — `AWSControlTowerExecution` if it went through Account Factory, `OrganizationAccountAccessRole` if it didn't — same pattern as the `networking` alias.
4. **Instantiate `vpc-baseline`** pointed at the new alias and its CIDR.
5. **Peer it to the `Networking` hub.** Still an open item as of this writing, so there's no existing peering to copy from yet — it'll be the first one.
6. **Assign Identity Center access.** Not automatic — creating the account doesn't grant anyone access to it.

## Cost Discipline

The previous attempt at this project got torn down over an unexpected AWS Config bill (pre-3.0 Control Tower's Config Recorder counting global IAM resources once per active region). That's the reason cost discipline runs through every decision here:

- Budget + CloudWatch billing alarm, set up before the Control Tower wizard ran, not after. Threshold: $10/month — anything above that on a lab with no real traffic means something's misconfigured.
- SCP #1 restricts EC2 instance types, so a typo or a copy-pasted example can't launch something expensive.
- VPC Peering over Transit Gateway — TGW's per-attachment-hour and per-GB cost has nothing to justify it at this account count.
- No NAT Gateway anywhere yet — a real hourly charge, deferred until a workload actually needs outbound access.
- SCP #2 backs that up by blocking Transit Gateway creation org-wide.
- The Terraform state backend lives in the management account for now instead of a dedicated one — one less account's baseline cost to carry.
- `SCP-test` was closed the moment it stopped being useful instead of left running "just in case."

Tracking is just the Budget email alert for now — enough at this account count; a fixed review cadence is worth adding once there's more to watch.

## Production Readiness Disclaimer

This is a personal lab, not a client-facing environment, and that shows in a few deliberate gaps. A production landing zone would need:

- **NAT Gateway / real HA for private workloads.** There's no outbound path from private subnets at all right now.
- **WAF, Shield, edge protection.** Nothing here is internet-facing yet.
- **GuardDuty, Security Hub, active threat detection.** Control Tower's default controls protect its own infrastructure, not the org's workloads.
- **CI/CD for the Terraform in this repo.** Every `apply` runs by hand from my machine. Production would gate changes through PRs, run `plan` in CI, and apply through a scoped OIDC identity.
- **Multi-region and separated duties.** Everything runs in one region, and I personally hold admin on every account.
- **A populated `Shared Services` account.** Reserved in the OU structure, nothing provisioned there yet.
- **External IdP federation.** Identity Center users are native, not synced from a corporate directory.
- **Broader mandatory tagging.** SCP #3 only covers EC2/RDS/S3.
- **IPAM-managed CIDR.** The plan is a hand-maintained table, not enforced by AWS IPAM.

None of this is unfamiliar — it's just not justified yet by what this environment needs to prove. This list is the starting point for what changes if it ever hosts something real.

## Status & Progress

#### Foundation

- [x] Management account created, root MFA, temporary bootstrap IAM user
- [x] Budget + CloudWatch billing alarm
- [x] ADR-001 (OU structure) documented
- [x] Control Tower wizard run; missing OUs created (Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging); Policy Staging registered with Control Tower
- [x] ADR-002 (foundational accounts) documented

#### Identity & access

- [x] Identity Center groups (`platform-admins`, `developers`, `readonly-auditors`) and permission sets (`AdministratorAccess`, `ReadOnlyAccess`, custom `DeveloperAccess`)
- [x] Real users created, auto-generated user deleted, portal URL customized
- [x] `breakglass` + `BreakGlassAdminRole` (MFA-gated) replacing the bootstrap IAM user

#### Guardrails

- [x] ADR-003 (guardrail strategy) documented
- [x] `SCP-test` account created and used to test all 3 SCPs manually (positive + negative), then decommissioned
- [x] ADR-005 (IaC strategy) documented — state backend in the management account for now
- [x] Terraform bootstrap (remote state bucket, native lockfile locking)
- [x] Existing OUs and SCPs codified and imported into Terraform state, `plan` confirms zero drift
- [x] All 3 SCPs attached via Terraform: EC2 type restriction (Dev, Staging, Sandbox), deny Transit Gateway (org-wide except Security), mandatory tags (Workloads)

#### Networking

- [x] ADR-004 (networking strategy) documented — VPC Peering hub-and-spoke via `Networking`, no Transit Gateway exception
- [x] `Networking` account provisioned via Account Factory, full Control Tower baseline
- [x] Hierarchical CIDR plan ([`docs/ip-address-plan.md`](docs/ip-address-plan.md))
- [x] Reusable VPC modules written (`vpc-baseline`, `vpc-sandbox`) — not instantiated yet
- [x] Cross-account provider alias (`AWSControlTowerExecution`) for `Networking`
- [x] Hub VPC applied (private + public-future subnets, no IGW)
- [x] Identity Center access assigned to `Networking`

#### Open

- [ ] Invite the existing Route 53 account into the org, under Infrastructure OU
- [ ] Create `Shared Services` under Infrastructure OU
- [ ] Create Dev/Staging/Prod accounts, instantiate `vpc-baseline` for each
- [ ] Build the VPC Peering connections between `Networking` and each workload VPC

## What I Learned

- The AWS Config cost surprise from the failed first attempt had a specific cause (the Config Recorder counting global IAM resources once per active region) — understanding that turned "cost discipline" into concrete guardrails instead of a vague intention.
- Environment-first OUs (Dev/Staging/Prod instead of per-project) only pay off once a second project actually shows up — see the CIDR gap that exposed in [Provisioning a New Workload Account](#provisioning-a-new-workload-account). The design was right; the first CIDR plan hadn't accounted for it.
- Control Tower's wizard asks for a Config Aggregator and a CloudTrail admin as two separate roles, not one "Audit" account — combined with a session timeout, that's how a planned 2-account setup became 3. Worth documenting as it happened (ADR-002) rather than editing history to match the plan.
- Testing SCPs manually before attaching them changed the final scope in both directions — some got narrower after testing, one got broader (Transit Gateway denial, applied everywhere with no exception, including `Networking` itself). The scope that looked obvious before testing wasn't the scope that survived it.

## Appendix / Evidence

Supporting evidence lives under [`docs/evidence/`](docs/evidence/) — checked off as it's captured, not retroactively.

- [x] Console screenshot: [final Organizations OU/account tree](docs/evidence/lz2026-OUs-accounts.png)
- [x] Identity Center: [groups](docs/evidence/identity-center-groups.png), [permission sets](docs/evidence/identity-center-permission-sets.png) ([Administrator](docs/evidence/permission-set-administrator-access.png), [ReadOnly](docs/evidence/permission-set-readonly-access.png), [Developer](docs/evidence/permission-set-developer-access.png) + its [inline policy](docs/evidence/developer-access-inline-policy.png)), account assignments ([management](docs/evidence/identity-center-account-assignment-management.png), [SCP-test](docs/evidence/identity-center-account-assignment-scp-test.png)), and the portal as seen by [an admin](docs/evidence/identity-center-portal-admin-view.png) vs. [a developer](docs/evidence/identity-center-portal-developer-view.png)
- [x] SCP #2 (deny Transit Gateway) lifecycle: [created](docs/evidence/scp2-created-deny-transit-gateway.png), plus screen recordings of the [creation](docs/evidence/scp2-create-recording.mov), the [negative test](docs/evidence/scp2-negative-test-recording.mov) (denied), and the [detach](docs/evidence/scp2-detach-recording.mov)
- [ ] SCP #1 and #3 verification evidence (a denied and an allowed API call for each)
- [ ] `terraform plan` / `terraform apply` output for each major milestone
- [ ] Console screenshots: CloudWatch billing alarm and Budget configuration
- [ ] `aws organizations list-accounts` / `list-organizational-units-for-parent` snapshot of the final structure
- [ ] VPC peering evidence once the first workload VPC exists

---

> **Status: v1.0 — documentation complete.**
> Everything above reflects what's built and verified as of this writing. Open items — inviting the Route 53 account, standing up `Shared Services`, provisioning Dev/Staging/Prod, and building the VPC Peering connections — are tracked in [Status & Progress](#status--progress).
