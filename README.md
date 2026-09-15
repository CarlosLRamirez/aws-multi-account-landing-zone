# AWS Multi-Account Landing Zone Implementation

## Overview

This repo documents building an AWS Control Tower landing zone: the implementation walkthrough, the Terraform IaC, and the ADRs behind the design decisions. It's a personal portfolio and learning lab, structured like an enterprise environment on purpose — meant as a long-term foundation for future projects, not something to spin up and tear down.

This isn't a step-by-step tutorial. It covers what got built, why, and what I'd change.

## Outcome

- An AWS Organization under Control Tower 4.0
- `LogArchive` and `Aggregator account` (Control Tower-managed) under the Security OU
- A `Networking` account under the Infrastructure OU, provisioned via Account Factory with the full Control Tower baseline, hub VPC built in Terraform
- `MyWebApp-dev` — the first Workload account (Dev), also provisioned via Account Factory — with its own `vpc-baseline` instantiation and a live VPC Peering connection to the `Networking` hub
- Empty OUs reserved for what's next: Sandbox, Staging, Prod
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
│   ├── Shared Services       # future
│   └── Networking
├── Sandbox OU                # Labs and experimentation
├── Workloads OU              # Operational Environments
│   ├── Dev OU
│   │   └── MyWebApp-dev      # first workload account, peered to Networking
│   ├── Staging OU
│   └── Prod OU
├── Policy Staging OU
│   └── SCP-test              # parked here, active but unused (see Guardrails)
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

### 6. First workload account and VPC Peering

- Registering `Workloads`/`Dev` with Control Tower required registering the parent `Workloads` OU first — registration doesn't cascade to children automatically.
- `MyWebApp-dev` provisioned via Account Factory into `Workloads/Dev` — the first account to actually use the `vpc-baseline` module and the CIDR pool reserved for Dev (`10.0.64.0/20`).
- First real VPC Peering connection built: `MyWebApp-dev` ↔ `Networking` hub, cross-account (explicit accepter on the spoke side, routes added on both sides once the connection confirmed `Active`).
- Building it surfaced a real bug in `vpc-baseline`: an inline `route { }` block on the public route table was fighting with the externally-added peering route — Terraform kept trying to delete the peering route on every plan. Fixed by converting it to a standalone `aws_route` resource (see [ADR-004](docs/adr/ADR-004-Networking-Strategy.md#first-peering-connection-2026-09-14) for the detail).
- Identity Center access assigned (`platform-admins`, `developers` — this closed a pending item, `developers`' `DeveloperAccess` on a Dev account had no target until now — and `readonly-auditors`).
- Reopened `SCP-test` (closed since 2026-09-03) to capture the SCP #1/#2/#3 verification evidence that was still outstanding, using `--dry-run` calls so nothing was actually created. Left it parked, active, in `Policy Staging` afterward instead of closing it again.

## Provisioning a New Workload Account

The steps above cover bootstrapping this once. This is the repeatable flow for adding another account later — `MyWebApp-dev` (above) is the worked example; the same steps apply for Staging/Prod or a second project's Dev environment:

1. **Create the account** via Account Factory (standard path, full CT baseline) or directly via Terraform (`aws_organizations_account`, the exception — only if it deliberately shouldn't carry that baseline yet). Place it under the OU matching its environment tier — check the OU itself (and its parent) is registered with Control Tower first. SCPs at the OU level apply automatically.
2. **Pick its CIDR** from the pool reserved for that environment ([`docs/ip-address-plan.md`](docs/ip-address-plan.md) reserves 8 slots per tier). Mark the slot as used.
3. **Add a provider alias** in `main.tf` — `AWSControlTowerExecution` if it went through Account Factory, `OrganizationAccountAccessRole` if it didn't — same pattern as the `networking` alias.
4. **Instantiate `vpc-baseline`** pointed at the new alias and its CIDR.
5. **Peer it to the `Networking` hub.** Explicit accepter on the spoke side (cross-account peering doesn't auto-accept), routes on both sides gated on the connection being `Active` — see `terraform/peering-networking-mywebapp-dev.tf` for the pattern to copy.
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

### Foundation

- [x] Management account created, root MFA, temporary bootstrap IAM user
- [x] Budget + CloudWatch billing alarm
- [x] ADR-001 (OU structure) documented
- [x] Control Tower wizard run; missing OUs created (Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging); Policy Staging registered with Control Tower
- [x] ADR-002 (foundational accounts) documented

### Identity & access

- [x] Identity Center groups (`platform-admins`, `developers`, `readonly-auditors`) and permission sets (`AdministratorAccess`, `ReadOnlyAccess`, custom `DeveloperAccess`)
- [x] Real users created, auto-generated user deleted, portal URL customized
- [x] `breakglass` + `BreakGlassAdminRole` (MFA-gated) replacing the bootstrap IAM user

### Guardrails

- [x] ADR-003 (guardrail strategy) documented
- [x] `SCP-test` account created and used to test all 3 SCPs manually (positive + negative), then decommissioned
- [x] ADR-005 (IaC strategy) documented — state backend in the management account for now
- [x] Terraform bootstrap (remote state bucket, native lockfile locking)
- [x] Existing OUs and SCPs codified and imported into Terraform state, `plan` confirms zero drift
- [x] All 3 SCPs attached via Terraform: EC2 type restriction (Dev, Staging, Sandbox), deny Transit Gateway (org-wide except Security), mandatory tags (Workloads)

### Networking

- [x] ADR-004 (networking strategy) documented — VPC Peering hub-and-spoke via `Networking`, no Transit Gateway exception
- [x] `Networking` account provisioned via Account Factory, full Control Tower baseline
- [x] Hierarchical CIDR plan ([`docs/ip-address-plan.md`](docs/ip-address-plan.md))
- [x] Reusable VPC modules written (`vpc-baseline`, `vpc-sandbox`)
- [x] Cross-account provider alias (`AWSControlTowerExecution`) for `Networking`
- [x] Hub VPC applied (private + public-future subnets, no IGW)
- [x] Identity Center access assigned to `Networking`

### Workloads

- [x] `Workloads`/`Dev` registered with Control Tower
- [x] `MyWebApp-dev` provisioned via Account Factory — first Workload account, first `vpc-baseline` instantiation, CIDR `10.0.64.0/20`
- [x] First VPC Peering connection built: `MyWebApp-dev` ↔ `Networking` hub, `Active`
- [x] `vpc-baseline` module bug fixed (inline route vs. externally-managed peering route conflict)
- [x] Identity Center access assigned to `MyWebApp-dev` (`platform-admins`, `developers`, `readonly-auditors`)
- [x] SCP #1/#2/#3 verification evidence captured (denied + allowed for each) via a reopened `SCP-test`

### Open

- [ ] Invite the existing Route 53 account into the org, under Infrastructure OU
- [ ] Create `Shared Services` under Infrastructure OU
- [ ] Create Staging/Prod accounts, instantiate `vpc-baseline` for each, peer to `Networking`
- [ ] Put real resources (EC2, ALB) behind `MyWebApp-dev` — Security Groups, target groups, etc. are out of this repo's scope (see [Provisioning a New Workload Account](#provisioning-a-new-workload-account))

## What I Learned

- The AWS Config cost surprise from the failed first attempt had a specific cause (the Config Recorder counting global IAM resources once per active region) — understanding that turned "cost discipline" into concrete guardrails instead of a vague intention.
- Environment-first OUs (Dev/Staging/Prod instead of per-project) only pay off once a second project actually shows up — see the CIDR gap that exposed in [Provisioning a New Workload Account](#provisioning-a-new-workload-account). The design was right; the first CIDR plan hadn't accounted for it.
- Control Tower's wizard asks for a Config Aggregator and a CloudTrail admin as two separate roles, not one "Audit" account — combined with a session timeout, that's how a planned 2-account setup became 3. Worth documenting as it happened (ADR-002) rather than editing history to match the plan.
- Testing SCPs manually before attaching them changed the final scope in both directions — some got narrower after testing, one got broader (Transit Gateway denial, applied everywhere with no exception, including `Networking` itself). The scope that looked obvious before testing wasn't the scope that survived it.
- Control Tower OU registration doesn't cascade: registering a child OU (`Dev`) required registering its parent (`Workloads`) first, even though `Workloads` already existed.
- Mixing an inline `route { }` block with a separately-managed `aws_route` on the same route table is a real Terraform footgun, not a theoretical one — it silently destroyed a live peering route on the first `plan` after adding it. `ec2:RunInstances --dry-run` turned out to be a good way to re-verify SCPs without creating (or having to tear down) real resources.

## Appendix / Evidence

Supporting evidence lives under [`docs/evidence/`](docs/evidence/) — checked off as it's captured, not retroactively.

- [x] Console screenshot: [final Organizations OU/account tree](docs/evidence/lz2026-OUs-accounts-final.png) (superseding the earlier [pre-workloads snapshot](docs/evidence/lz2026-OUs-accounts.png))
- [x] Identity Center: [groups](docs/evidence/identity-center-groups.png), [permission sets](docs/evidence/identity-center-permission-sets.png) ([Administrator](docs/evidence/permission-set-administrator-access.png), [ReadOnly](docs/evidence/permission-set-readonly-access.png), [Developer](docs/evidence/permission-set-developer-access.png) + its [inline policy](docs/evidence/developer-access-inline-policy.png)), account assignments ([management](docs/evidence/identity-center-account-assignment-management.png), [Networking](docs/evidence/identity-center-account-assignment-networking.png), [MyWebApp-dev](docs/evidence/identity-center-account-assignment-mywebapp-dev.png), [SCP-test, reopened](docs/evidence/identity-center-account-assignment-scp-test-reopened.png)), and the portal as seen by [an admin](docs/evidence/identity-center-portal-admin-view.png) vs. [a developer](docs/evidence/identity-center-portal-developer-view.png)
- [x] SCP #2 (deny Transit Gateway): [console screenshot of the policy as created](docs/evidence/scp2-created-deny-transit-gateway.png)
- [x] SCP #1, #2, and #3 verification evidence (a denied and an allowed API call for each): [`scp-verification-tests.md`](docs/evidence/scp-verification-tests.md), plus the [attach](docs/evidence/policies-attached-on-SCP-test.json)/[detach](docs/evidence/policies-attached-on-SCP-test-final.json) confirmation for the temporary test attachment
- [x] SCP definitions and OU attachments via CLI: [`list-policies`](docs/evidence/aws-organizations-list-scps.json), targets for [EC2 type restriction](docs/evidence/aws-organizations-targets-scp-restrict-ec2-instance-types.json), [deny Transit Gateway](docs/evidence/aws-organizations-targets-scp-deny-transit-gateway.json), [mandatory tags](docs/evidence/aws-organizations-targets-scp-require-mandatory-tags.json)
- [x] [`terraform plan`](./docs/evidence/terraform-plan.md) / [`terraform apply`](./docs/evidence/terraform-apply.md) output for each major milestone
- [x] CloudWatch billing alarm and Budget configuration, via CLI: [`describe-alarms`](docs/evidence/aws-cloudwatch-alarms.json) / [`describe-budgets`](docs/evidence/aws-budgets-describe.json)
- [x] Org structure snapshot via CLI: [`list-accounts`](docs/evidence/aws-organization-list-accounts.json) / [`list-organizational-units-for-parent`](docs/evidence/aws-organization-list-ous-root.json) (root level)
- [x] `MyWebApp-dev` provisioning: [Account Factory confirmation](docs/evidence/mywebapp-dev-account-factory.png), [`Workloads`/`Dev` OU registration](docs/evidence/ct-workloads-dev-ou-registered.png)
- [x] VPC peering evidence: [`describe-vpc-peering-connections`](docs/evidence/aws-describe-vpc-peering-networking-hub.json), console screenshots from [the hub](docs/evidence/vpc-peering-active-networking-hub.png) and [the spoke](docs/evidence/vpc-peering-active-mywebapp-dev.png)

---

> **Phase 1: Foundation — complete. Phase 2: Workloads — first account live.**
> Everything above reflects what's built and verified as of this writing. `MyWebApp-dev` is up, peered, and guardrail-verified — the repeatable pattern for the next one. Open items — inviting the Route 53 account, standing up `Shared Services`, and provisioning Staging/Prod — are tracked in [Status & Progress](#status--progress).
