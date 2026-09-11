---
title: IaC Strategy (Terraform)
status: draft
date: 2026-08-30
---

# ADR-005: IaC Strategy (Terraform)

## Status

Proposed

## Context

Everything built so far — OUs, the three custom SCPs, the SCP-test account, the Identity Center access model, the break-glass IAM setup — was done manually through the console, by design: understand each mechanism first, then automate it. That phase is complete. The next phase is codifying the parts of the landing zone that aren't owned by Control Tower into Terraform.

Two things need deciding before writing the first resource:

1. **Where the Terraform remote state lives.** The conventional enterprise pattern is a dedicated Shared Services/tooling account holding the state bucket, isolated from the management account and from workload accounts. That account doesn't exist yet in this landing zone — "Shared Services" is currently just a name reserved under the Infrastructure OU in the design (ADR-001), with no account actually provisioned.
2. **What Terraform is allowed to manage.** Control Tower owns the lifecycle of its own accounts (LogArchive, Aggregator account) and the 13 preventive controls it deployed on the Security OU (ADR-003). Bringing those into Terraform state would fight a service that already manages them declaratively, and risks drift or accidental breakage of the landing zone's own guardrails.

## Decision

### Scope: what Terraform manages vs. what it doesn't

Terraform manages:

- Non-Control-Tower-managed OUs and their structure.
- The three custom SCP documents and their OU attachments (ADR-003).
- Provisioning of future non-Control-Tower-managed accounts.

Terraform does **not** manage:

- LogArchive, Aggregator account, or any Control Tower-provisioned resource (Config recorders, CloudTrail, the 13 preventive controls, their supporting IAM roles/Lambdas/SNS topics).
- Anything Control Tower owns is treated as read-only/observed from Terraform's perspective — never authored in state.

### Existing manual resources: import, don't recreate

The OU tree, the three SCP policy documents, and the SCP-test account already exist and are actively enforcing guardrails. Instead of writing Terraform resources and letting `apply` create duplicates (or fail), the plan is:

1. Write `.tf` resources that describe these exactly as they exist today.
2. Use `terraform import` to bring them into state without modifying anything live.
3. Confirm with `terraform plan` that the result is a clean "no changes" — proof Terraform now matches reality before it's allowed to change anything.

### State backend: S3 with native locking, hosted in the management account (for now)

The remote state bucket will be created in the **management account**, not in a new dedicated Shared Services account. Locking uses the S3 backend's native lockfile support (`use_lockfile`, available since Terraform 1.10) instead of a separate DynamoDB table — one less resource to create and maintain, at no cost to correctness.

**Why:** standing up a Shared Services account today, just to host a state bucket, would immediately add a recurring AWS Config baseline cost to a brand-new account with no actual tenant workload to justify it yet — on top of whatever one-time cost the account creation itself triggers. For a self-funded personal lab where cost discipline is a first-class constraint (see project context), that's not a good trade for what is otherwise a cosmetic architectural improvement. Hosting the backend in the management account costs nothing extra and unblocks starting Terraform today.

This is treated as a **deliberate, temporary decision**, not the target end-state. The migration path is: once a Shared Services account exists for a real reason (e.g., centralized networking, shared tooling), migrate the state backend there via `terraform init -migrate-state`.

### Repo structure

Kept intentionally flat for now: a single root Terraform configuration under `terraform/`. No environment-per-directory or module split until there's an actual second consumer of a module — splitting now would be designing for a future that doesn't exist yet.

### Cross-account resource management: provider aliases

One Terraform state manages resources across multiple AWS accounts (management, `Networking`, and future workload accounts) — no per-account backend. Reaching into a member account uses a **per-account AWS provider alias** that assumes a role in that account:

- Accounts created directly via `aws_organizations_account` (not through Account Factory) only get the default `OrganizationAccountAccessRole` that AWS Organizations grants automatically.
- Accounts provisioned via Account Factory (the current `Networking` account, and later Dev/Staging/Prod) get Control Tower's `AWSControlTowerExecution` role instead, so their provider alias assumes that role.

The `networking` provider alias in `terraform/main.tf` is the first instance of this pattern — see ADR-004 for how it's used to manage the `Networking` account's VPC.

### Boundary with future project repos

This repo's Terraform stops at the landing zone: accounts, guardrails, and each workload account's baseline VPC (ADR-004). A future application project (e.g. a 3-tier web app deployed into the Dev account) gets **its own repository and its own Terraform state**, not a folder added here — see the "one state per lifecycle" reasoning above; an application changes far more often than the landing zone it runs on.

That project's Terraform should **not** authenticate using `AWSControlTowerExecution`. That role is effectively full admin, meant for Control Tower's own account governance, not for routine `terraform apply` runs from an application pipeline. Instead, create a dedicated, scoped IAM role in the target account for that project — granted only the permissions it actually needs — and have its provider assume that role instead. This keeps least-privilege intact as more projects land in accounts this landing zone provisions.

## Consequences

**Positive:**

- Terraform work can start immediately, at zero incremental AWS cost.
- Every existing guardrail (OUs, SCPs, SCP-test account) can be brought under Terraform management with zero downtime and zero risk to what's already enforced, via import.
- Clear, explicit boundary between what Terraform owns and what Control Tower owns avoids drift fights with the platform.

**Negative / accepted trade-offs:**

- The state file for the whole landing zone's custom guardrails lives in the management account rather than an isolated tooling account. This doesn't introduce new exposure beyond what management-account access already implies (SCPs don't even apply to the management account per existing security notes), but it is architecturally not the ideal end-state.
- Requires a documented, deliberate migration step later. Left unaddressed indefinitely, "temporary" backend placement becomes its own form of drift from stated intent — this ADR is the record that it was a conscious choice with a planned exit, not an oversight.

## Alternatives Considered

- **Create a Shared Services account first, host the backend there from day one.** Rejected for now — architecturally cleaner, but adds a recurring cost (new account's AWS Config baseline) before there's a real tenant workload to justify that account's existence.
- **Local state only (no remote backend).** Rejected — no locking, no durable shared source of truth, and doesn't reflect the practices this landing zone is meant to demonstrate as portfolio evidence.
