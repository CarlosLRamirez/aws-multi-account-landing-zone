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
    └── SCP-test              # Test SCP before going production
```

## Key Design Decisions

- [ADR-001: OU Structure](docs/adr/ADR-001-OU-Structure.md)
- [ADR-002: Foundational Accounts](docs/adr/ADR-002-Foundational-Accounts.md)
- [ADR-003: Guardrail Strategy](docs/adr/ADR-003-Guardrail-Strategy.md)

## Implementation Walk-through

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
- Created the OUs not provisioned by the wizard: Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging.
- Registered the Policy Staging OU with Control Tower to include it in the landing zone baseline.
- Used Account Factory to create the `SCP-test` account inside Policy Staging — an isolated account for testing SCPs before attaching them to their target OUs.
- Created and tested three custom SCPs manually in Policy Staging (attach to Policy Staging OU → test in the SCP-test account → detach), per ADR-003. Both positive and negative tests passed for all three. The exact policy documents are kept under [`policies/`](policies/) for reuse once this is automated with Terraform:
  - SCP #1 — [Restricted EC2 instance types](policies/scp-1-restricted-ec2-instance-types.json)
  - SCP #2 — [Deny Transit Gateway creation](policies/scp-2-deny-transit-gateway.json)
  - SCP #3 — [Require mandatory resource tags](policies/scp-3-require-mandatory-tags.json)
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
└── terraform             # not yet started
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
- [ ] Automate with Terraform: Policy Staging test account provisioning
- [ ] Automate with Terraform: SCP #1, #2, #3 (attach to their target OUs per ADR-003)
- [ ] Decide: keep Policy Staging test account persistent, or destroy after automation
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

    ```
    Normal:    Identity Center → group membership → permission set → temporary credentials
    Fallback:  breakglass IAM user + MFA → Switch role → BreakGlassAdminRole → temporary credentials
    Recovery:  Root user → root-only and account-recovery operations only
    ```

## What I Learned

[Insights and lessons accumulated during implementation: what surprised you, what would you do differently, trade-offs discovered in practice, etc.]

## Appendix / Evidence

[Links to docs/evidence/ for verification: console screenshots, terraform plan outputs, AWS Config recordings, etc.]
