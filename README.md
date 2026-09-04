# AWS Multi-Account Landing Zone Implementation

## Overview

This repository documents the process of implementing an **AWS Control Tower Landing Zone**. It includes the implementation walkthrough, the Terraform Infrastructure as Code (IaC), and the architectural decision records (ADRs). This landing zone serves as a personal portfolio and learning lab, built to resemble an enterprise-grade structure following best practices for governance and security in multi-account, multi-stage cloud environments.

## Architecture

```text
Root
├── Security OU
│   ├── LogArchive            # Control Tower Managed
│   └── Aggregator account    # Control Tower Managed
├── Infrastructure OU
│   ├── Shared Services
│   └── Networking
├── Sandbox OU                # Labs and experimentation
├── Workloads OU              # Operational Environments
│   ├── Dev OU
│   ├── Staging OU
│   └── Prod OU
└── Policy Staging OU
    └── SCP-test              # Closed — SCP testing complete, guardrails attached to real OUs
```

## Key Design Decisions

- [ADR-001: OU Structure](docs/adr/ADR-001-OU-Structure.md)
- [ADR-002: Foundational Accounts](docs/adr/ADR-002-Foundational-Accounts.md)
- [ADR-003: Guardrail Strategy](docs/adr/ADR-003-Guardrail-Strategy.md)
- [ADR-004: Networking Strategy (VPC Peering over TGW)](docs/adr/ADR-004-Networking-Strategy.md)
- [ADR-005: IaC Strategy (Terraform)](docs/adr/ADR-005-IaC-Strategy.md)

## Implementation Walk-through

The decisions above (ADR-001 through ADR-005) were made before touching the console. What follows is how they got deployed.

### 1. Account foundation and Control Tower deployment

- Created a new AWS account to serve as the Management Account.
- Configured MFA on the root user.
- Created an IAM user with `AdministratorAccess` and MFA as a bootstrap admin for the initial setup.
- Enabled IAM billing access so the IAM user could view billing information.
- Set up a Budget, CloudWatch billing alarms, and a billing alarm as a cost safeguard.
- Ran the Control Tower wizard from the Management Account. The wizard created two managed accounts:
  - `LogArchive`: holds CloudTrail logs.
  - `Aggregator account`: handles Config aggregation.
  - Note: an `Audit` account was created during this process and later closed. It still appears in the Organization with status Closed; AWS automatically removes closed accounts 90 days after closure, so the plan is to let it drop off on its own.
- After Control Tower finished, received an IAM Identity Center invitation with an auto-generated user tied to the management account root email.
- Created the OUs not provisioned by the wizard, per ADR-001: Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging.
- Registered the Policy Staging OU with Control Tower to include it in the landing zone baseline.

### 2. Guardrails: designing and testing custom SCPs

- Used Account Factory to create the `SCP-test` account inside Policy Staging — an isolated account for testing SCPs before attaching them to their target OUs.
- Created and tested three custom SCPs manually in Policy Staging (attach to Policy Staging OU → test in the SCP-test account → detach), per ADR-003. Both positive and negative tests passed for all three. The exact policy documents are kept under [`policies/`](policies/) for reuse once this is automated with Terraform:
  - SCP #1 — [Restricted EC2 instance types](policies/scp-1-restricted-ec2-instance-types.json)
  - SCP #2 — [Deny Transit Gateway creation](policies/scp-2-deny-transit-gateway.json)
  - SCP #3 — [Require mandatory resource tags](policies/scp-3-require-mandatory-tags.json)

### 3. Introducing Terraform (ADR-005)

- Bootstrapped a remote state backend: an S3 bucket with versioning, blocked public access, SSE-S3 encryption, and native S3 lockfile locking (no DynamoDB table needed as of Terraform 1.10+).
- Codified the existing OU tree and the 3 SCP documents as `.tf` resources, then `terraform import`-ed each one so Terraform adopted what already existed without recreating it — [`terraform/ous.tf`](terraform/ous.tf), [`terraform/scps.tf`](terraform/scps.tf). `terraform plan` confirmed zero changes before Terraform was allowed to touch anything.
- Attached SCP #1, #2, and #3 to their real target OUs — the actual guardrail-activation step, kept deliberately separate from the import work. Deny Transit Gateway ended up with the widest scope (every OU except Security, no exception for the `Networking` account, per ADR-004); mandatory tags attaches to Workloads; restricted EC2 types attaches to Dev and Staging.
- Decommissioned the `SCP-test` account once the SCP automation was verified — closed directly via Organizations, the same pattern used for the earlier `Audit` account.

### 4. Identity and access hardening

- Replaced the auto-generated Identity Center user with a proper group-based access model:
  - Created three groups: `platform-admins`, `developers`, `readonly-auditors`.
  - Created three permission sets: `AdministratorAccess`, `ReadOnlyAccess`, and a custom `DeveloperAccess` scoped to EC2, S3, and Lambda with `iam:PassRole` restricted to trusted services only.
  - Assigned groups to accounts with the appropriate permission sets.
  - Created user `carlos.ramirez` (member of `platform-admins` and `developers`) and `carlosvsccnp` (member of `developers` only) to simulate different access personas.
  - Deleted the auto-generated user tied to the root email.
  - Customized the Identity Center portal URL to `https://mylz2027.awsapps.com/start`.
- Replaced the IAM bootstrap user with a hardened break-glass access model:
  - Created `BreakGlassAdminRole` with `AdministratorAccess` and a trust policy that requires MFA, scoped exclusively to the `breakglass` IAM user.
  - Created the `breakglass` IAM user with console access, MFA, and a single permission: `sts:AssumeRole` targeting `BreakGlassAdminRole`.
  - Deleted the original IAM bootstrap user.
  - Verified the fallback flow: `breakglass` login + MFA → Switch role → full admin access.

## Rebuilding This From Scratch

The walk-through above narrates what actually happened, import steps and all. Rebuilding this landing zone from zero — a fresh reader, or myself on a future project — wouldn't need to repeat the manual detours; most of it collapses into a straight `terraform apply` once the ADRs are read. General sequence:

1. **Decide before deploying anything.** Read ADR-001 (OU structure) → ADR-002 (foundational accounts and parameters) → ADR-003 (guardrail strategy) → ADR-005 (IaC strategy) → ADR-004 (networking). These fix every parameter — OU names, retention periods, SCP scope, where the Terraform backend lives, the peering topology — before anything gets created.
2. **Bootstrap the management account.** New AWS account, MFA on root, a temporary IAM admin user with MFA, IAM billing access, and a Budget + CloudWatch billing alarm — in that order, before running anything else, per the cost-discipline reasoning in ADR-002/003/005.
3. **Run the Control Tower wizard** from the management account: a `LogArchive` account for CloudTrail, an `Aggregator account` for Config, one governed region, per the parameters in ADR-002.
4. **Harden Identity Center and IAM right away.** The wizard already enables Identity Center, so set up the `platform-admins` / `developers` / `readonly-auditors` groups, permission sets, and real users immediately — that becomes the primary access path. Only once that's working, delete the auto-generated root-email user and retire the temporary bootstrap IAM user into the `breakglass` + `BreakGlassAdminRole` model. Doing this before anything else means every step from here on is done through a hardened identity, not a throwaway admin user.
5. **Stand up Terraform.** Apply `terraform/bootstrap` first — it creates the remote-state S3 bucket and keeps its own state local, since it can't store its state in the bucket it's creating. Then `terraform init` the main project (`terraform/main.tf`), which points at that bucket and uses native S3 lockfile locking.
6. **Apply the rest of Terraform in one pass** — `ous.tf`, `scps.tf`, `accounts.tf`. A from-scratch org has none of this yet, so there's no import dance like this repo went through: one `terraform apply` creates every remaining OU (Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging), the 3 SCPs and their attachments, and the `Networking` account. Two things still stay outside Terraform even here: registering an OU with Control Tower's landing zone baseline (Policy Staging needs this) is a Control Tower action, not something the AWS provider manages; and if a disposable account is needed to validate SCPs before trusting the attachment, it can be created the same way as `Networking` (`aws_organizations_account`) instead of through Account Factory — Control Tower enrollment doesn't matter for an account whose only job is sitting under an OU an SCP gets attached to.
7. **Networking** (ADR-004 — still open in this repo). Decide the CIDR allocation plan, build the hub VPC in the `Networking` account, and peer it to each workload VPC as those get created. Not yet automated here; this is the next Terraform module to write.

## Cost Discipline

[Budget strategy and thresholds; CloudWatch billing alarms; cost considerations and rejected alternatives]

## Prerequisites

[AWS account access requirements, IAM permissions needed, tools/CLI versions expected for anyone reviewing or replicating this setup]

## Repository Structure

```text
├── docs
│   └── adr              # Architectural Decision Records
├── policies              # SCP JSON documents (tested, ready for Terraform reuse)
├── README.md            # this file
└── terraform
    ├── bootstrap         # one-time, local-state config that creates the remote state bucket
    ├── main.tf           # provider + S3 backend
    ├── ous.tf            # non-Control-Tower OUs
    ├── scps.tf           # the 3 custom SCPs and their OU attachments
    └── accounts.tf       # accounts provisioned directly through Organizations (e.g. Networking)
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
- [x] Improve the Control Tower's administrative access model
  - [x] **IAM Identity Center — define groups and permission set model**
    - Created Identity Center groups: `platform-admins`, `developers`, `readonly-auditors`
    - Created permission sets: `AdministratorAccess` (AWS managed), `ReadOnlyAccess` (AWS managed), `DeveloperAccess` (custom, scoped to EC2/S3/Lambda with `iam:PassRole` restricted to `lambda.amazonaws.com` and `ec2.amazonaws.com`)
    - Assigned permission sets to groups per account (Sandbox/Dev/Staging/Prod pending account creation):

      | Group             | management          | SCP-test            | Sandbox             | Dev                 | Staging             | Prod                |
      | ----------------- | ------------------- | ------------------- | ------------------- | ------------------- | ------------------- | ------------------- |
      | platform-admins   | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess |
      | developers        | ReadOnlyAccess      | —                   | DeveloperAccess     | DeveloperAccess     | ReadOnlyAccess      | ReadOnlyAccess      |
      | readonly-auditors | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      | ReadOnlyAccess      |

  - [x] **IAM Identity Center — replace auto-created user with real users**
    - Created user `carlos.ramirez` (primary admin) → member of `platform-admins` + `developers`
    - Created user `carlosvsccnp` (developer persona) → member of `developers` only
    - Verified: `carlos.ramirez` sees management + SCP-test with correct permission sets; `carlosvsccnp` sees management with `ReadOnlyAccess` only
    - Deleted the auto-created user `carloslrm+ct26-mgmt@gmail.com` tied to the root email
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

[Insights and lessons accumulated during implementation: what surprised you, what would you do differently, trade-offs discovered in practice, etc.]

## Appendix / Evidence

[Links to docs/evidence/ for verification: console screenshots, terraform plan outputs, AWS Config recordings, etc.]
