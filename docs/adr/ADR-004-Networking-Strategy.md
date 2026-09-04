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

**Left open, to be decided when the `Networking` account actually exists:**

- CIDR allocation plan across accounts (peering requires non-overlapping ranges, so this has to be settled before the first VPC is created, just not as part of this ADR)

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
