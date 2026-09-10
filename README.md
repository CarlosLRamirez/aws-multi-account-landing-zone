# AWS Multi-Account Landing Zone Implementation

## Overview

This repository documents the process of implementing an **AWS Control Tower Landing Zone**. It includes the implementation walkthrough, the Terraform Infrastructure as Code (IaC), and the architectural decision records (ADRs). This landing zone serves as a personal portfolio and learning lab, built to resemble an enterprise-grade structure following best practices for governance and security in multi-account, multi-stage cloud environments. The idea is that it serves as the long-term foundation for real personal projects in the future, and not something to create and destroy.

Although a step-by-step implementation guide is planned, this document does not intend to be that; rather, it covers the general steps taken, the decision-making process, the overall architecture and the lessons learned.

## Outcome

This Landing Zone consists of:

- An AWS Organization under AWS Control Tower 4.0 management
- The `LogArchive` and `Aggregator` standard CT accounts under a `Security OU` (both Control Tower-managed)
- A `Networking` account under an `Infrastructure OU`, provisioned via Control Tower Account Factory (full CT baseline — CloudTrail, Config), with its hub VPC built via Terraform
- Additional empty OUs to allocate future accounts: Sandbox, Workloads (with Dev/Staging/Prod), and Policy Staging
- 13 preventive controls, deployed by default by Control Tower, governing the accounts under its management
- **3 additional custom SCPs**, managed and attached to specific OUs by Terraform:
  - Restricted EC2 instance types
  - Denied Transit Gateway creation (all OUs except Security, no per-account exceptions)
  - Mandatory resource tagging
- **A group-based Identity Center access model** (`platform-admins` / `developers` / `readonly-auditors`) replacing the auto-generated root-tied user — no individual IAM users, and role-based emergency access (`breakglass` + MFA) as fallback
- **A Terraform codebase** (`terraform/`) covering non-Control-Tower OUs, all 3 SCPs and their attachments, direct account provisioning, and a per-account VPC baseline pattern — reached via cross-account provider aliases from one shared state/backend
- **A documented, reusable pattern** (this README + ADR-004) for provisioning the next account and its standard network configuration
- The `Networking` account with its VPC configured (via Terraform), ready to serve as the hub for the future VPC peering connections needed from the workload accounts (Dev, Staging, Prod, and Sandbox)

The Appendix below links the supporting evidence (console screenshots, `terraform plan`/`apply` output, SCP verification).

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
- [IP Address Plan](docs/ip-address-plan.md) — living reference for CIDR allocation and per-VPC subnet layouts (companion to ADR-004)

## Implementation Walk-through

High-level implementation process based on the decisions made initially

### 1. Account foundation and Control Tower deployment

- Created a new AWS account to serve as the Management Account.
- Configured MFA on the root user.
- Created an temporary IAM user with `AdministratorAccess` and MFA as a bootstrap admin for the initial setup.
- Enabled IAM billing access so the IAM user could view billing information.
- Set up a Budget, CloudWatch billing alarms, and a billing alarm as a cost safeguard.
- Ran the Control Tower wizard from the Management Account. The wizard created two managed accounts:
  - `LogArchive`: holds CloudTrail logs.
  - `Aggregator account`: handles Config aggregation.
  - Note: An `Audit` account was created during firsts attempts to run of the wizard and was closed shortly after. It still appears in the Organization with status Closed; AWS automatically removes closed accounts 90 days after closure, so the plan is to let it drop off on its own. Discovered that Control Tower v4.0 no longer requires a separate `Audit` account.
- After Control Tower finished, received an IAM Identity Center invitation with an auto-generated user tied to the management account root email.
- Created the OUs not provisioned by the wizard, per ADR-001: Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging.
- Registered the Policy Staging OU with Control Tower to include it in the landing zone baseline.

### 2. Identity and access hardening

- Replaced the auto-generated Identity Center user with a proper group-based access model:
  - Created three groups: `platform-admins`, `developers`, `readonly-auditors`.
  - Created three permission sets: `AdministratorAccess`, `ReadOnlyAccess`, and a custom `DeveloperAccess` scoped to EC2, S3, and Lambda with `iam:PassRole` restricted to trusted services only.
  - Assigned groups to accounts with the appropriate permission sets.
  - Created user `admin-user` (member of `platform-admins` and `developers`) and `dev-user` (member of `developers` only) to simulate different access personas.
  - Deleted the auto-generated user tied to the root email.
  - Customized the Identity Center portal URL to `https://mylandingzone2026.awsapps.com/start`.
- Replaced the IAM bootstrap user with a hardened break-glass access model:
  - Created `BreakGlassAdminRole` with `AdministratorAccess` and a trust policy that requires MFA, scoped exclusively to the `breakglass` IAM user.
  - Created the `breakglass` IAM user with console access, MFA, and a single permission: `sts:AssumeRole` targeting `BreakGlassAdminRole`.
  - Deleted the original IAM bootstrap user.
  - Verified the fallback flow: `breakglass` login + MFA → Switch role → full admin access.

### 3. Guardrails: designing and testing custom SCPs

- Used Account Factory to create the `SCP-test` account inside Policy Staging — an isolated account for testing SCPs before attaching them to their target OUs — and added it to the existing `platform-admins` group with its respective permission sets.
- Created and tested three custom SCPs manually in Policy Staging (attach to Policy Staging OU → test in the SCP-test account → detach), per ADR-003. Both positive and negative tests passed for all three. The exact policy documents are kept under [`policies/`](policies/) for reuse once this is automated with Terraform:
  - SCP #1 — [Restricted EC2 instance types](policies/scp-1-restricted-ec2-instance-types.json)
  - SCP #2 — [Deny Transit Gateway creation](policies/scp-2-deny-transit-gateway.json)
  - SCP #3 — [Require mandatory resource tags](policies/scp-3-require-mandatory-tags.json)

### 4. Introducing Terraform (ADR-005)

- Bootstrapped a remote state backend: an S3 bucket with versioning, blocked public access, SSE-S3 encryption, and native S3 lockfile locking (no DynamoDB table needed as of Terraform 1.10+).
- Codified the existing OU tree and the 3 SCP documents as `.tf` resources, then `terraform import`-ed each one so Terraform adopted what already existed without recreating it — [`terraform/ous.tf`](terraform/ous.tf), [`terraform/scps.tf`](terraform/scps.tf). `terraform plan` confirmed zero changes before Terraform was allowed to touch anything.
- Attached SCP #1, #2, and #3 to their respective target OUs, per the scope decided in ADR-003.
- Decommissioned the `SCP-test` account once the SCP automation was verified — closed via console directly on Organizations, the same pattern used for the earlier `Audit` account.

### 5. Networking foundation (ADR-004)

- Created the `Networking` account under Infrastructure OU directly via Terraform (`aws_organizations_account`) instead of Account Factory, to avoid Control Tower baseline cost while the account only held a VPC — the exception path documented in ADR-004, not the default.
- Decided the CIDR allocation plan: a hierarchical scheme reserving growth space per environment, not a flat `/20` per account — full table in [`docs/ip-address-plan.md`](docs/ip-address-plan.md).
- Built the hub VPC in [`terraform/networking.tf`](terraform/networking.tf) — not the `vpc-baseline` module, since this account isn't a workload account: private + "public (future)" subnets across 3 AZs, no Internet Gateway attached yet.
- Wrote two reusable modules as the standard templates for future accounts, neither instantiated yet since those accounts don't exist: [`terraform/modules/vpc-baseline`](terraform/modules/vpc-baseline) (3 AZs, Public/App/Data tiers, one IGW, no NAT Gateway yet) for Dev/Staging/Prod, and [`terraform/modules/vpc-sandbox`](terraform/modules/vpc-sandbox) (2 AZs, smaller `/23` footprint) for Sandbox.
- **Revisited the account's provisioning path** (see ADR-004's "Control Tower Enrollment" section): decided the cost saved by skipping the Control Tower baseline wasn't worth the governance gap it left — no CloudTrail/Config coverage, none of the 13 mandatory preventive SCPs. Since the account still held only a VPC with no peering connections and no workloads, closed it and reprovisioned it via Account Factory instead, so it's Control Tower-managed from birth rather than retrofitted later. This required registering the `Infrastructure` OU with Control Tower first (Account Factory only targets registered OUs) and separately associating the Account Factory Service Catalog portfolio with the admin SSO role — Service Catalog portfolio access is a distinct layer from IAM policy, so `AdministratorAccess` alone wasn't enough to launch it. The hub VPC was rebuilt in the new account, same design, new account ID.
- Still open: the actual VPC Peering connections between the hub and each future workload VPC.

## Rebuilding This From Scratch

The walk-through above narrates what actually happened, import steps and all. Rebuilding this landing zone from zero — a fresh reader, or myself on a future project — wouldn't need to repeat the manual detours; most of it collapses into a straight `terraform apply` once the ADRs are read. General sequence:

1. **Decide before deploying anything.** Read ADR-001 (OU structure) → ADR-002 (foundational accounts and parameters) → ADR-003 (guardrail strategy) → ADR-005 (IaC strategy) → ADR-004 (networking). These fix every parameter — OU names, retention periods, SCP scope, where the Terraform backend lives, the peering topology — before anything gets created.
2. **Bootstrap the management account.** New AWS account, MFA on root, a temporary IAM admin user with MFA, IAM billing access, and a Budget + CloudWatch billing alarm — in that order, before running anything else, per the cost-discipline reasoning in ADR-002/003/005.
3. **Run the Control Tower wizard** from the management account: a `LogArchive` account for CloudTrail, an `Aggregator account` for Config, one governed region, per the parameters in ADR-002.
4. **Harden Identity Center and IAM right away.** The wizard already enables Identity Center, so set up the `platform-admins` / `developers` / `readonly-auditors` groups, permission sets, and real users immediately — that becomes the primary access path. Only once that's working, delete the auto-generated root-email user and retire the temporary bootstrap IAM user into the `breakglass` + `BreakGlassAdminRole` model. Doing this before anything else means every step from here on is done through a hardened identity, not a throwaway admin user.
5. **Stand up Terraform.** Apply `terraform/bootstrap` first — it creates the remote-state S3 bucket and keeps its own state local, since it can't store its state in the bucket it's creating. Then `terraform init` the main project (`terraform/main.tf`), which points at that bucket and uses native S3 lockfile locking.
6. **Apply the rest of Terraform in one pass** — `ous.tf`, `scps.tf`, `accounts.tf`. A from-scratch org has none of this yet, so there's no import dance like this repo went through: one `terraform apply` creates every remaining OU (Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging), the 3 SCPs and their attachments, and the `Networking` account. Two things still stay outside Terraform even here: registering an OU with Control Tower's landing zone baseline (Policy Staging needs this) is a Control Tower action, not something the AWS provider manages; and if a disposable account is needed to validate SCPs before trusting the attachment, it can be created the same way as `Networking` (`aws_organizations_account`) instead of through Account Factory — Control Tower enrollment doesn't matter for an account whose only job is sitting under an OU an SCP gets attached to.
7. **Networking** (ADR-004, CIDR detail in [`docs/ip-address-plan.md`](docs/ip-address-plan.md)). Three distinct VPC designs, each reached via a per-account provider alias rather than a separate Terraform backend per account. Workload accounts (Dev/Staging/Prod) use [`terraform/modules/vpc-baseline`](terraform/modules/vpc-baseline) (3 AZs, Public/App/Data tiers, no NAT Gateway yet); Sandbox uses the smaller [`terraform/modules/vpc-sandbox`](terraform/modules/vpc-sandbox) (2 AZs, `/23`). Neither is instantiated yet — those accounts don't exist. The `Networking` account is not a workload account, so it uses neither module: [`terraform/networking.tf`](terraform/networking.tf) builds its hub VPC directly, with private + "public (future)" subnets and no Internet Gateway attached yet — its job is centralizing VPC Peering (and later a Site-to-Site VPN to on-premises), not hosting internet-facing resources. Still open: the actual VPC Peering connections between the hub and each workload VPC.

## Provisioning a New Workload Account

The steps above cover bootstrapping this Landing Zone once. This is the recurring flow for adding one more account under it later — for example, a `MyAppDev` account for a new project's Dev environment:

1. **Create the account.** Two paths, per ADR-005's scope split:
   - Via **Account Factory** (Control Tower console) if it should get the standard CT baseline (CloudTrail/Config, eligible for Identity Center assignment right away) — the normal path for a real project account.
   - Via Terraform (`aws_organizations_account`, the pattern `terraform/accounts.tf` is kept ready for) only if it deliberately shouldn't carry that baseline cost yet — the exception, not the default. `Networking` took this path originally, then moved to Account Factory once the governance gap outweighed the cost saved (see ADR-004's "Control Tower Enrollment" section) — a preview of the trade-off this path always carries.

   Place it under the OU matching its environment tier (Dev/Staging/Prod), per ADR-001's environment-first structure. SCPs attached at the OU level apply automatically — no per-account SCP work needed.

2. **Pick its CIDR.** The allocation table in [`docs/ip-address-plan.md`](docs/ip-address-plan.md) reserves a pool of 8 slots per environment tier (Dev, Staging, Prod each get 8× `/20`; Sandbox gets 8× `/23`) specifically so a second account sharing a tier (e.g. `MyAppDev` alongside the existing Dev account) takes the next unused slot in that pool rather than requiring a new CIDR block to be carved out. Mark the slot as in-use in that document when it's assigned.
3. **Give Terraform a way in.** Add a provider alias in `main.tf` for the new account — `AWSControlTowerExecution` if it went through Account Factory, `OrganizationAccountAccessRole` if it didn't — same pattern as the `networking` alias.
4. **Instantiate the VPC module.** A `module "myapp_dev_vpc" { source = "./modules/vpc-baseline" ... }` block, pointed at the new provider alias and its assigned CIDR.
5. **Peer it to the hub.** Add the VPC Peering connection and route table entries between this VPC and the `Networking` hub (ADR-004). This part of ADR-004 is still open as of this writing, so there's no existing instantiation to copy yet — it'll be the first one.
6. **Assign Identity Center access.** Not automatic (see note above) — add the account to the relevant groups' assignments (at minimum `platform-admins` → `AdministratorAccess`), via console or Terraform depending on whether Identity Center itself has been migrated into Terraform by then.

## Cost Discipline

Cost discipline is a first-class design constraint here, not an afterthought — the previous attempt at this project was torn down entirely because of an unexpected AWS Config bill (pre-3.0 Control Tower's Config Recorder recording global resources like IAM users/roles once per active region). Every ADR in this repo threads that lesson through:

**Guardrails in place before anything else was built:**

- A Billing Budget and a CloudWatch billing alarm were created _before_ running the Control Tower wizard, not after — see step 2 of [Rebuilding This From Scratch](#rebuilding-this-from-scratch). Threshold: under $10/month — this landing zone has no production traffic, so any spend above that is a signal something's misconfigured, not normal usage.
- SCP #1 (restricted EC2 instance types, ADR-003) exists specifically to stop an accidental expensive instance launch — a typo or a copy-pasted doc example landing on a GPU/memory-optimized type in an environment that never needed one.

**Decisions made specifically to avoid cost, not just to keep things simple:**

- VPC Peering over Transit Gateway (ADR-004) — TGW has a real per-attachment-hour and per-GB cost that has nothing to justify it yet at this account count.
- No NAT Gateway in any VPC yet (ADR-004) — a real hourly charge deferred until a workload actually lives in a private subnet and needs outbound access.
- SCP #2 denies Transit Gateway creation org-wide (ADR-003/004) — turns "don't accidentally spin one up" from a policy into an enforced guardrail.
- The `Networking` account was created directly through Organizations (`terraform/accounts.tf`), not Account Factory — it carries no Control Tower baseline (Config Recorder, CloudTrail) cost until it's deliberately enrolled later.
- The Terraform state backend lives in the management account for now rather than a dedicated account (ADR-005) — one fewer account's baseline cost to carry, revisited later if this repo needs stronger state isolation.
- Throwaway accounts were closed the moment they stopped being useful: `SCP-test` was decommissioned right after SCP automation was verified, rather than left running "just in case."

**What I actually track:** the Budget alert is wired to notify by email — there's no separate weekly Cost Explorer ritual yet. At this account count and spend level, an alert-driven check is enough; a fixed review cadence becomes worth adding once there's more than a handful of accounts and workloads to watch.

## Production Readiness Disclaimer

This is a personal portfolio and learning lab, not a commercial or client-facing environment — I don't (yet) earn anything from it, and that shapes several decisions below on purpose. A "real" enterprise, production-ready landing zone built for an organization with actual revenue at stake would need more than what's here. Specifically:

- **No NAT Gateway / no real HA for private workloads.** Private subnets have no outbound path at all right now (see Cost Discipline). Production would need at least one NAT Gateway per AZ, accepted as a real recurring cost.
- **No WAF, Shield, or edge protection.** Nothing here is internet-facing yet, so there's nothing to protect. Any production web workload in front of an ALB/CloudFront would need this from day one.
- **No GuardDuty, Security Hub, or centralized threat detection beyond Control Tower's default preventive controls.** Control Tower's 13 mandatory controls (ADR-003) protect its own infrastructure; they don't substitute for active threat detection across the org.
- **No CI/CD pipeline for the Terraform in this repo.** Every `terraform apply` is run by hand, from my own machine, with my own credentials. A production IaC workflow would gate changes through pull requests, run `plan` in CI, and apply through a scoped service identity (OIDC), not a personal admin session.
- **Single region, single approver.** Everything runs in one governed region (ADR-002), and I personally hold `platform-admins` → `AdministratorAccess` on every account. A real org would separate duties across teams and plan for multi-region DR.
- **`Shared Services` account is reserved but empty.** ADR-001 planned for it; nothing runs there yet.
- **Identity Center isn't federated with an external IdP.** Users are Identity Center-native, not SSO'd in from a corporate directory (Okta, Entra ID, etc.) — fine for one person, not for a team.
- **Mandatory tagging is narrow.** SCP #3 (ADR-003) only enforces `Project`/`Environment` tags on EC2, RDS, and S3 — a real cost-allocation policy would need to cover a much wider service surface.
- **CIDR plan is hand-allocated, not IPAM-managed.** The hierarchical scheme in [`docs/ip-address-plan.md`](docs/ip-address-plan.md) pre-reserves growth pools per environment, but it's still a markdown table maintained by hand. A real enterprise at larger account counts would use AWS IPAM to manage and enforce allocation instead.

None of these are things I don't know how to do — they're things I deliberately didn't do yet, because the cost or the complexity isn't justified by what this environment actually needs to prove right now. If/when this hosts something that matters, this list is the starting point for what changes.

## Repository Structure

```text
├── docs
│   ├── adr                    # Architectural Decision Records
│   ├── ip-address-plan.md     # living CIDR allocation reference (companion to ADR-004)
│   └── evidence               # screenshots / CLI output backing the Appendix section
├── policies              # SCP JSON documents (tested, ready for Terraform reuse)
├── README.md             # this file
└── terraform
    ├── bootstrap             # one-time, local-state config that creates the remote state bucket
    ├── main.tf               # provider + S3 backend + per-account provider aliases
    ├── variables.tf          # input variables (e.g. account emails) — no real values committed
    ├── terraform.tfvars.example  # template for terraform.tfvars (gitignored, holds real values)
    ├── ous.tf                # non-Control-Tower OUs
    ├── scps.tf               # the 3 custom SCPs and their OU attachments
    ├── accounts.tf           # accounts provisioned directly through Organizations (e.g. Networking)
    ├── networking.tf         # Networking hub VPC — private + public-future subnets, no IGW attached yet (ADR-004)
    └── modules
        ├── vpc-baseline      # workload VPC module (3 AZs, Public/App/Data tiers, IGW, no NAT Gateway yet)
        └── vpc-sandbox       # Sandbox VPC module (2 AZs, smaller /23 footprint)
```

## Status & Progress

- [x] Fresh AWS Account created
- [x] Root account secured with Multi-Factor Authentication (MFA)
- [x] IAM user created with `AdministratorAccess`and MFA configured
- [x] Programmatic credentials and local AWS CLI profile configured
- [x] IAM user and role access to Billing information
- [x] Billing Budgets & CloudWatch billing alarm
- [x] ADR-001-OU-Structure Documented
- [x] AWS Control Tower Wizard run
- [x] Create the missing OUs according to ADR-001
  - Infrastructure OU
  - Workloads OU
    - Dev OU
    - Staging OU
    - Prod OU
  - Policy Staging OU
- [x] ADR-002-Foundational Account and Parameters Documented
- [x] ADR-003-Guardrail-Strategy Documented
- [x] Create Policy Staging test account via Account Factory (manual, persistent staging account)
- [x] Create & test SCP #1 (Restricted EC2 instance types) manually in Policy Staging
- [x] Create & test SCP #2 (Deny Transit Gateway creation) manually in Policy Staging
- [x] Create & test SCP #3 (Require mandatory resource tags) manually in Policy Staging
- [x] ADR-005-IaC-Strategy Documented — state backend hosted in the management account for now (cost-driven, temporary; see ADR-005 for the migration path)
- [x] **Terraform: bootstrap the remote state backend**
  - [x] S3 bucket for state (versioned, public access blocked, native S3 lockfile locking — no DynamoDB table needed as of Terraform 1.10+)
  - [x] Bootstrap kept as an isolated, one-time-use Terraform config with local state (can't store its own state in the bucket it creates)
- [x] **Terraform: base project structure** (`terraform/` — provider, backend block pointing at the bootstrap bucket)
- [x] **Terraform: codify existing resources without recreating them**
  - [x] Write `.tf` resources matching the current OU tree (7 OUs) and the 3 SCP documents — [`terraform/ous.tf`](terraform/ous.tf), [`terraform/scps.tf`](terraform/scps.tf)
  - [x] `terraform import` each one so Terraform adopts them without touching what's already live
  - [x] `terraform plan` shows zero changes — confirmed the code matches reality before Terraform is allowed to change anything
- [x] **Terraform: attach SCP #1, #2, #3 to their target OUs**
  - Deny Transit Gateway and Require mandatory tags attached to Workloads OU (inherited by Dev, Staging, Prod)
  - Restrict EC2 instance types attached to Dev OU and Staging OU
  - Attachment scope narrowed from the original ADR-003 proposal (Sandbox dropped, tags no longer org-wide) — see ADR-003 for the updated rationale
  - `terraform plan` confirms zero drift post-apply
- [x] Decommission the Policy Staging test account (decided: destroy, not keep persistent) — closed via AWS Organizations once SCP automation was verified
- [x] ADR-004-Networking-Strategy Documented — VPC Peering hub-and-spoke via a `Networking` account, no exception to the deny-Transit-Gateway SCP even for that account
- [x] **Terraform: provision the `Networking` account** ([`terraform/accounts.tf`](terraform/accounts.tf)) — created directly through Organizations, not Account Factory, so no Control Tower baseline cost until/unless it's separately enrolled
- [x] Broaden the deny-Transit-Gateway SCP to every OU except Security (Infrastructure, Sandbox, Workloads, Policy Staging) — no exception for the `Networking` account, per ADR-004
- [x] Decide the CIDR allocation plan (ADR-004) — originally one non-overlapping `/20` per account; revised 2026-09-07 into a hierarchical scheme with per-environment growth pools — full table in [`docs/ip-address-plan.md`](docs/ip-address-plan.md)
- [x] **Terraform: reusable VPC modules for future accounts** — [`terraform/modules/vpc-baseline`](terraform/modules/vpc-baseline) (3 AZs, Public/App/Data tiers, one IGW, no NAT Gateway yet) for Dev/Staging/Prod, and [`terraform/modules/vpc-sandbox`](terraform/modules/vpc-sandbox) (2 AZs, smaller `/23` footprint) for Sandbox. Neither instantiated yet — those accounts don't exist. Not used for `Networking` itself, see below
- [x] **Terraform: cross-account provider alias** — `networking` alias in [`terraform/main.tf`](terraform/main.tf) assumes `OrganizationAccountAccessRole` in the `Networking` account, so one shared backend/state can still create resources there instead of a separate backend per account
- [x] **Terraform: apply the `Networking` account's hub VPC** ([`terraform/networking.tf`](terraform/networking.tf)) — private + "public (future)" subnets, no IGW attached yet (this account isn't a workload account, so it deliberately doesn't use either VPC module — see ADR-004). Applied 2026-09-04 on the original `/20` (`vpc-0c903fd7b3e108d8e`); rebuilt 2026-09-07 on the revised `/21` (`vpc-01790eeee360b1fc5`); rebuilt again 2026-09-07 in a brand-new Account-Factory-provisioned account (`vpc-021f251e55eebe1cf`) — no peering existed yet at any point, so each destroy+recreate broke nothing live
- [x] **`Networking` account recreated as Control Tower-managed (2026-09-07)** — closed the original Terraform-created account (`204957733187`, no CT baseline) and reprovisioned it via Account Factory (`623609441070`), so it's born with the full baseline (CloudTrail, Config, `AWSControlTowerExecution`) instead of retrofitting enrollment later and inheriting an audit gap. See ADR-004's "Control Tower Enrollment" section for the reasoning and the one-time setup this required (registering the Infrastructure OU with Control Tower, and associating the Account Factory Service Catalog portfolio with the admin SSO role)
- [x] Rename the `Networking` account — Account Factory had named it `NetworkingAccount`; renamed to `Networking` via that account's Billing → Account settings (Organizations doesn't support renaming an account directly)
- [x] Assign Identity Center access to the `Networking` account — `platform-admins` → `AdministratorAccess`, done manually via console like the other accounts (see note above; not automatic just because the account exists)
- [ ] Invite the existing Route 53 (DNS) account into the org, under Infrastructure OU — the hosted zone itself doesn't move, only the account joins
- [ ] Create the `Shared Services` account under Infrastructure OU (planned in ADR-001, still empty)
- [ ] Create Dev/Staging/Prod accounts via Account Factory, then instantiate `vpc-baseline` for each via their own `AWSControlTowerExecution`-based provider alias
- [ ] Build the actual VPC Peering connections between the `Networking` hub and each workload VPC, per ADR-004
- [x] Improve the Control Tower's administrative access model
  - [x] **IAM Identity Center — define groups and permission set model**
    - Created Identity Center groups: `platform-admins`, `developers`, `readonly-auditors`
    - Created permission sets: `AdministratorAccess` (AWS managed), `ReadOnlyAccess` (AWS managed), `DeveloperAccess` (custom, scoped to EC2/S3/Lambda with `iam:PassRole` restricted to `lambda.amazonaws.com` and `ec2.amazonaws.com`)
    - Assigned permission sets to groups per account (Sandbox/Dev/Staging/Prod pending account creation; `SCP-test` has since been decommissioned — table reflects the assignment as it existed during SCP testing):

      | Group             | management          | SCP-test            | Sandbox             | Dev                 | Staging             | Prod                |
      | ----------------- | ------------------- | ------------------- | ------------------- | ------------------- | ------------------- | ------------------- |
      | platform-admins   | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess |
      | developers        | ReadOnlyAccess      | —                   | DeveloperAccess     | DeveloperAccess     | ReadOnlyAccess      | ReadOnlyAccess      |
      | readonly-auditors | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      |

    Note: this assignment is never automatic. Creating an account — through Account Factory or directly via `aws_organizations_account` (e.g. `Networking`, see below) — doesn't grant Identity Center users or groups any access to it. Each account needs an explicit group + permission set assignment before it shows up in anyone's Identity Center portal; until then it's only reachable by assuming its cross-account role directly (e.g. `OrganizationAccountAccessRole`).

  - [x] **IAM Identity Center — replace auto-created user with real users**
    - Created user `carlos.ramirez` (primary admin) → member of `platform-admins` + `developers`
    - Created user `carlosvsccnp` (developer persona) → member of `developers` only
    - Verified: `carlos.ramirez` sees management + SCP-test with correct permission sets; `carlosvsccnp` sees management with `ReadOnlyAccess` only
    - Deleted the auto-created user tied to the management account's root email
    - Customized the Identity Center access portal URL to `https://mylz2027.awsapps.com/start`
  - [x] **IAM Identity Center — clean up stale permission set assignments**
    - `AWSOrganizationFullAccess` on SCP-test belongs to the `AWSControlTowerAdmins` group, created and managed by Control Tower — do not remove
    - `AWSServiceCatalogEndUserAccess` on management belongs to the `AWSAccountFactory` group, also Control Tower-managed — do not remove
    - No stale assignments found; all non-Control Tower assignments are group-based and intentional
  - [x] **Management account — harden the IAM bootstrap user**
    - Created `BreakGlassAdminRole` IAM role with `AdministratorAccess` and a trust policy requiring MFA, scoped exclusively to the `breakglass` IAM user
    - Created IAM user `breakglass` (replaces the original `carlos.ramirez` IAM bootstrap user) with console access, MFA, and a single inline policy: `sts:AssumeRole` targeting `BreakGlassAdminRole` only
    - Deleted the original `carlos.ramirez` IAM bootstrap user
    - Verified the fallback flow: `breakglass` login + MFA → Switch role → `BreakGlassAdminRole` → full admin access
    - Note: Switch Role in the console does not prompt for MFA again — MFA was already verified at login, so `aws:MultiFactorAuthPresent: true` is already set on the session when the trust policy is evaluated
  - [x] **Document the intended access hierarchy**

    ```text
    Normal:    Identity Center → group membership → permission set → temporary credentials
    Fallback:  breakglass IAM user + MFA → Switch role → BreakGlassAdminRole → temporary credentials
    Recovery:  Root user → root-only and account-recovery operations only
    ```

## What I Learned

- The AWS Config cost surprise from the first failed attempt wasn't a vague "watch your bill" lesson — it had a specific root cause (pre-3.0 Control Tower's Config Recorder recording global IAM resources once per active region). Understanding the _mechanism_ before rebuilding, not just avoiding it, is what let this attempt turn "cost discipline" into concrete guardrails instead of a good intention.
- Environment-first OU design (Dev/Staging/Prod rather than per-project) only pays off once you actually add a second project — see the CIDR allocation gap this exposed in [Provisioning a New Workload Account](#provisioning-a-new-workload-account). The design was right; the first version of the CIDR plan hadn't fully thought through what "environment-first" implies for multiple projects sharing one tier.
- Control Tower's actual wizard behavior didn't match the plan: it asks for a Config Aggregator account and a CloudTrail admin account as two separate roles, not one generic "Audit" account. Combined with a session token expiring mid-wizard, that turned a planned 2-account setup into 3 accounts with different names than intended (`LogArchive` + `Aggregator account`, plus a closed, inert `Audit` account left over from the failed attempt). The lesson wasn't to avoid the deviation — it was to document it as it actually happened (ADR-002) instead of quietly editing history to match the original plan.
- If I started this over today, I'd write ADR-004's CIDR allocation as "one `/20` per environment-per-project" from the start, instead of "one `/20` per environment," since the gap only became visible once a second project was hypothetically added — cheaper to design for it up front than to patch the table later.
- Narrowing vs. broadening SCP scope after manual testing (ADR-003) felt different in practice than on paper: it's tempting to attach a guardrail everywhere "to be safe," but testing surfaced concrete reasons to narrow two of the three SCPs (dropping Sandbox from the EC2-type restriction, scoping mandatory tags to Workloads only) while broadening the third (Transit Gateway denial, specifically to remove a tempting exception for the `Networking` account). The scope that looked obvious before testing wasn't the scope that survived it.

## Appendix / Evidence

Supporting evidence lives under [`docs/evidence/`](docs/evidence/). This is a living list — items get checked off as evidence is captured, not retroactively marked done.

- [x] Console screenshot: [final Organizations OU/account tree](docs/evidence/lz2026-OUs-accounts.png)
- [ ] `terraform plan` / `terraform apply` output — at least one clean run per major milestone (bootstrap, SCP attachment, `Networking` account creation)
- [ ] Console screenshots: IAM Identity Center portal (groups + permission set assignments), CloudWatch billing alarm and Budget configuration
- [ ] SCP verification evidence: a denied API call (positive test) and an allowed one (negative test) for each of the 3 SCPs, from the Policy Staging testing round
- [ ] `aws organizations list-accounts` / `list-organizational-units-for-parent` output as a point-in-time snapshot of the final structure
- [ ] Once the `Networking` hub VPC and first workload VPC exist: a screenshot or `describe-vpc-peering-connections` output showing the peering actually working

---

> **Status: v1.0 — documentation complete.**
> Everything described below reflects what's actually built and verified as of this writing. The landing zone itself keeps growing on top of this foundation — see the open items at the end of [Status & Progress](#status--progress) for what's next (inviting the existing Route 53 account, standing up `Shared Services`, provisioning Dev/Staging/Prod, and building the VPC Peering connections).
