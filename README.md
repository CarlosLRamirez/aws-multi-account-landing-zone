# AWS Multi-Account Landing Zone Implementation

## Overview

This repository contains the Infrastructure as Code (IaC) and architectural decision records (ADRs) for deploying an **AWS Control Tower Landing Zone**. It establishes a multi-account governance framework tailored for both experimental lab environments and production-grade multi-stage workloads.

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

- [ADR-001: OU-Structure](ADR-001-OU-Structure.md)
- [ADR-002: Foundational Accounts](ADR-002-Foundational-Accounts.md)
- [ADR-003: Guardrails-Strategy](ADR-003-Guardrail-Strategy.md)

## Implementation Walk-through

- Created a brand new AWS account from scratch to serve as the Management Account.
- Configured MFA on the root user.
- Created an IAM user with `AdministratorAccess` and configured MFA on it.
- Enabled IAM billing access so the IAM user could view billing information.
- Created a Budget, enabled CloudWatch billing alarms, and set up a CloudWatch alarm as a backup safeguard.
- Ran the Control Tower wizard from the Management Account using the newly created IAM user.
- Hit several issues getting the wizard to complete, but got there in the end. In the process, two new accounts were created:
  - `LogArchive`: holds CloudTrail logs.
  - `Aggregator account`: handles Config aggregation.
  - I also created an `Audit` account, which I later closed. It's still part of the Organization but shows as Closed and isn't managed by Control Tower. I could remove it from the Organization, but that requires meeting certain requirements to convert it to standalone first. Since it's already closed, I'm planning to wait 90 days to see if it disappears on its own.
- After Control Tower finished deploying, I received an IAM Identity Center invitation, with the username matching the management account's email and an access URL.
- Created the OUs that were missing and that the Control Tower wizard didn't create: Infrastructure, Workloads, Dev, Staging, Prod, Policy Staging.
- Registered the Policy Staging OU with Control Tower so it's included in the landing zone baseline, along with any accounts under it.
- Used Control Tower's Account Factory to create a new `SCP-test` account inside the Policy Staging OU, which I'll use to test SCPs in an isolated environment before deploying them to their target OU.




## Cost Discipline

[Budget strategy and thresholds; CloudWatch billing alarms; cost considerations and rejected alternatives]

## Prerequisites

[AWS account access requirements, IAM permissions needed, tools/CLI versions expected for anyone reviewing or replicating this setup]

## Repository Structure

```text
├── docs
│   └── adr
├── README.md            # this file
└── terraform
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
- [ ] Create & test SCP #2 (Deny Transit Gateway creation) manually in Policy Staging
- [ ] Create & test SCP #3 (Require mandatory resource tags) manually in Policy Staging
- [ ] Automate with Terraform: Policy Staging test account provisioning
- [ ] Automate with Terraform: SCP #1, #2, #3 (attach to their target OUs per ADR-003)
- [ ] Decide: keep Policy Staging test account persistent, or destroy after automation
- [x] Improve the Control Tower's administrative access model
  - [x] **IAM Identity Center — define groups and permission set model**
    - Created Identity Center groups: `platform-admins`, `developers`, `readonly-auditors`
    - Created permission sets: `AdministratorAccess` (AWS managed), `ReadOnlyAccess` (AWS managed), `DeveloperAccess` (custom, scoped to EC2/S3/Lambda with `iam:PassRole` restricted to `lambda.amazonaws.com` and `ec2.amazonaws.com`)
    - Assigned permission sets to groups per account (Sandbox/Dev/Staging/Prod pending account creation):

      | Group | management | SCP-test | Sandbox | Dev | Staging | Prod |
      |---|---|---|---|---|---|---|
      | platform-admins | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess |
      | developers | ReadOnlyAccess | — | DeveloperAccess | DeveloperAccess | ReadOnlyAccess | ReadOnlyAccess |
      | readonly-auditors | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess |

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
