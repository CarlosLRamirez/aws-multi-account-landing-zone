---
title: Networking Strategy
status: draft
date: 2026-09-03
---

# ADR-004: Networking Strategy (VPC Peering over Transit Gateway)

## Status

Proposed

## Context

This Landing Zone serves several purposes: first, as an environment for learning, experimentation, and project work for my professional portfolio; and second, to provide a solid foundation to deploy personal projects and learning labs, as well as workloads that resemble enterprise environments.

In that same spirit, keeping strict cost discipline is a key factor, since the workloads on this Landing Zone are expected to be purely personal and for learning purposes — the same reasoning already running through ADR-002, ADR-003, and ADR-005.

No real workload VPCs exist yet — Dev, Staging, and Prod are OUs waiting on accounts. Networking is being decided ahead of any real workload, the same way guardrails were put in place before any account needed them (ADR-003).

Per ADR-001, an Infrastructure OU is planned to host `Networking` and `Shared Services` accounts, for cross-cutting services and inter-account connectivity, as well as hybrid-type traffic (VPNs, etc.).

Per ADR-003, a custom SCP will exist to prevent Transit Gateway creation across the organization — with no exception, not even for the `Networking` account itself. If that decision ever changes, the fix is to remove or scope down the SCP deliberately, not to have carried a silent exception since day one for the one account that looks like the "natural" place to build a Transit Gateway.

## Decision

Use **VPC Peering**, not Transit Gateway, for inter-account connectivity, arranged in a **hub-and-spoke topology centered on the `Networking` account** (Infrastructure OU):

- The `Networking` account holds the hub VPC. It peers individually with each workload VPC (Dev, Staging, Prod, Sandbox).
- No direct spoke-to-spoke peering — e.g. Dev never peers directly with Staging. Every cross-environment path routes through the hub, keeping a single choke point available for future centralized inspection or egress control instead of an N-to-N tangle of connections.
- `Shared Services` stays out of the network path entirely. It's reserved for things like AMI baking, a private module registry, or a shared CI/CD runner — this ADR only covers network topology, not what Shared Services eventually runs.

At the current scale — a handful of accounts, no meaningful east-west bandwidth requirement — VPC Peering's simplicity and $0 fixed cost win over Transit Gateway's centralized route management and per-attachment/per-GB charges.

**CIDR allocation.** Each account gets its own non-overlapping `/20`, sized generously since VPC Peering requires non-overlapping ranges up front — there's no cheap way to renumber a VPC after peering connections and route tables already reference it:

| Account | CIDR |
| --- | --- |
| `Networking` (hub) | `10.0.0.0/20` |
| Dev | `10.1.0.0/20` |
| Staging | `10.2.0.0/20` |
| Prod | `10.3.0.0/20` |
| Sandbox | `10.4.0.0/20` |

**Two different internal layouts, not one, because the `Networking` account isn't a workload account:**

- **Workload VPCs** (Dev, Staging, Prod, Sandbox): 2 AZs, one public and one private `/24` subnet per AZ, one Internet Gateway. No NAT Gateway yet — private subnets get a route table with only the local route, so they have no outbound path until a workload actually needs one. That's a deliberate, revisitable gap, not an oversight: NAT Gateway has a real hourly cost this Landing Zone doesn't need to carry before anything lives in a private subnet. Implemented as a reusable Terraform module (`terraform/modules/vpc-baseline`), instantiated once per workload account.
- **The `Networking` hub VPC** is deliberately not built from that module. This account never runs application workloads — its only job is to be the peering nexus, and later the attachment point for a Site-to-Site VPN to on-premises — so it gets no Internet Gateway and no public subnets: nothing in it is meant to be internet-facing. Just private subnets across 2 AZs, existing as attachment points for peering routes to each spoke and, later, propagated routes from a Virtual Private Gateway. Kept as plain resources in `terraform/networking.tf` rather than force-fit into `vpc-baseline`, since a workload-shaped module (IGW, public subnets) doesn't describe what this account is for.

**Cross-account Terraform.** Each account's VPC is created from the same Terraform state as everything else in this repo (ADR-005), via a per-account AWS provider alias that assumes a cross-account role rather than giving each account its own Terraform backend. `Networking` was created directly through `aws_organizations_account` (not Account Factory), so it only has the default `OrganizationAccountAccessRole` Organizations grants automatically — not Control Tower's `AWSControlTowerExecution`. Accounts created later via Account Factory (Dev, Staging, Prod) will need their own alias using that role instead once they exist. Keeping one shared backend, rather than a backend per account, was chosen for the same cost-discipline reason ADR-005 gives for not splitting state in the first place: an extra S3 bucket and lockfile per account buys isolation this project doesn't need yet.

## Consequences

**Positive:**

- $0 fixed networking cost until real cross-VPC traffic exists — VPC Peering has no hourly charge, only data transfer once it's actually used.
- Matches the guardrail already in place (SCP #2 denies Transit Gateway org-wide, with no exception for the `Networking` account) — no gap between what's technically blocked and what's architecturally decided.
- Hub-and-spoke via a single `Networking` account keeps a future centralized egress/inspection point possible without redesigning the topology later.

**Negative:**

- VPC Peering isn't transitive — every new spoke needs its own explicit peering connection to the hub, with route table updates on both sides. This stops being comfortable to manage by hand somewhere around 10 VPCs.
- No AWS-native central route table the way Transit Gateway provides one; more Terraform code to maintain per-VPC routes as the number of spokes grows.

## Alternatives Considered

- **Transit Gateway hub-and-spoke.** Rejected for now: real per-attachment-hour and per-GB cost with no workloads yet to justify it, and already blocked org-wide by SCP #2. Revisit if account count grows enough that peering's management overhead exceeds Transit Gateway's cost.
- **Full-mesh VPC Peering** (every account peers directly with every other account). Rejected: no central point for future inspection/egress control, and connection count grows quadratically instead of linearly with each new account.
- **No cross-account networking at all** (fully isolated VPCs, communicating only via S3/API if at all). Rejected: too restrictive for realistic multi-tier workloads — e.g. a Shared Services account hosting a private package registry that Dev/Staging/Prod need to reach over the network.
