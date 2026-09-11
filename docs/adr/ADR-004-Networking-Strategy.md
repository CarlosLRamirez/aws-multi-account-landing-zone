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

Per ADR-003, a custom SCP will exist to prevent Transit Gateway creation across the organization — with no exception, not even for the `Networking` account itself. If that decision ever changes, the fix is to remove or scope down the SCP deliberately.

## Decision

Use **VPC Peering**, not Transit Gateway, for inter-account connectivity, arranged in a **hub-and-spoke topology centered on the `Networking` account** (Infrastructure OU):

- The `Networking` account holds the hub VPC. It peers individually with each workload VPC (Dev, Staging, Prod, Sandbox).
- No direct spoke-to-spoke peering — e.g. Dev never peers directly with Staging. Every cross-environment path routes through the hub, keeping a single choke point available for future centralized inspection or egress control instead of an N-to-N tangle of connections.
- `Shared Services` stays out of the network path entirely. It's reserved for things like AMI baking, a private module registry, or a shared CI/CD runner — this ADR only covers network topology, not what Shared Services eventually runs.

At the current scale — a handful of accounts, no meaningful east-west bandwidth requirement — VPC Peering's simplicity and $0 fixed cost win over Transit Gateway's centralized route management and per-attachment/per-GB charges.

### CIDR allocation

An IP addressing scheme was defined. It reserves network segments for shared and security accounts, sandbox accounts, and workload accounts by environment. Continuous segments are used for each environment. This makes grouping and summarization easy. This design provides future network segments. It does not mean that the accounts or VPCs exist from the beginning. Also, it assumes that each AWS Account will keep a single VPC.

Complete CIDR table and subnet layouts are detailed in [`docs/ip-address-plan.md`](../ip-address-plan.md)

In summary: `Networking` hub and `Shared Services` each get a `/21`; 4 more `/21`s are reserved for future cross-cutting/security tooling; Dev, Staging, Prod, and Sandbox each get a pool of 8 slots (`/20` for workload environments, `/23` for Sandbox).

Three different internal layouts: `Networking`, workload accounts, and Sandbox accounts (full subnet tables in `docs/ip-address-plan.md`):

#### Workload VPC
- The Terraform module `vpc-baseline` is included with the VPC template and the planned subnet mapping — implemented as a reusable module, instantiated once per workload account. CIDR values must be specified manually, using [`docs/ip-address-plan.md`](../ip-address-plan.md) as the reference; this is not automatic.
- Three AZs are considered. Each AZ has four `/24` subnets. The first three match a three-layer architecture: Web (Public), App (Private), and Data (Private).
- A fourth `/24` is reserved in the IP plan for a possible fourth layer if needed later, but it's not included as an `aws_subnet` resource in the `vpc-baseline` module.
- Four more `/24` blocks are reserved (equivalent to two `/23` blocks), for cases where bigger subnets are needed for a specific application or architecture — also not included in the Terraform module.
- This fills the entire `/20` reserved for each Workload VPC.
- None of these reserved spaces are deployed yet — they only hold address space that applications might need later. It doesn't mean every subnet will eventually be created; it only covers possible future scenarios.
- Each VPC has its own Internet Gateway for the public part. A NAT Gateway is not planned for now — a deliberate decision for cost reasons, detailed in the Consequences section below.

#### Sandbox VPC
- Smaller footprint, since sandbox workloads don't need production-grade capacity: 2 AZs, one Public + two Private `/26` subnets per AZ.
- A separate module, `terraform/modules/vpc-sandbox` available to faciliatate the deployemnet.

#### Networking Hub VPC
- One Private + one Public (Future) subnet per AZ across 3 AZs. "Public (Future)" subnets are provisioned now but carry **no Internet Gateway and no route to one yet** — they reserve the address space and AZ placement for the day this account centralizes egress (NAT Instance/Gateway) per the "Networking Considerations" section below, without requiring a resize later. 
- This account still runs no application workloads — the Private subnets remain the peering attachment points, and a future Virtual Private Gateway would land its propagated routes there too. 
- Kept as plain resources in `terraform/networking.tf` rather than either workload module.

#### Cross-account Terraform
The `Networking` account's VPC is managed via the `networking` provider alias — see ADR-005 for the general cross-account provider-alias pattern this follows. `Networking` was created via Account Factory, so its alias assumes Control Tower's `AWSControlTowerExecution` role. Future accounts provisioned the same way (Dev, Staging, Prod) will follow the same pattern once they exist.

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

## Networking Considerations (Future Work)

Notes for when the Landing Zone needs real internet access. Not implemented yet, written down here so the reasoning is not lost.

**Centralized egress (NAT) and centralized ingress (IGW) are two different problems.**

- **Centralized egress works with VPC Peering, but only using a NAT instance, not a NAT Gateway.** AWS does not allow routing through a gateway of a peered VPC — this is called "edge to edge routing" and AWS lists it as not supported. A gateway here means an Internet Gateway, a NAT Gateway, a VPN connection, or a Direct Connect connection. So a managed NAT Gateway placed in the `Networking` hub cannot serve outbound traffic from the other VPCs through peering — it just does not route, no matter the configuration. A NAT instance (a normal EC2 instance doing NAT) is not a "gateway" in AWS's sense, so it does not hit this restriction and works fine across peering: `private subnet → peering connection → Networking hub → NAT instance → IGW → Internet`. If a managed NAT Gateway is needed later for this, VPC Peering is not enough — that would require moving to Transit Gateway. The hub's `/21` layout already reserves one "Public (Future)" `/24` per AZ for this, so adding it later only means new resources, not a redesign.
- **Centralized ingress does not work with VPC Peering.** An Internet Gateway belongs to a single VPC and cannot be shared with peered VPCs. If a workload account (e.g. Prod) needs to expose something to the internet, like an ALB, that VPC needs its own IGW and public subnet. Centralizing ingress through the hub would need Transit Gateway with a Gateway Load Balancer, VPC Lattice, or PrivateLink — none of these work on top of plain VPC Peering. Conclusion: **each workload account keeps its own IGW for public-facing resources; only the outbound path can be centralized, and only with a NAT instance.**

**NAT Gateway vs. NAT Instance — cost trade-off for a personal-lab context.** This table is a general comparison. Under VPC Peering, only the NAT Instance column is actually usable for centralized egress — the NAT Gateway column would only apply if the topology moves to Transit Gateway later (see Alternatives Considered).

| | NAT Gateway (managed) | NAT Instance (EC2) |
| --- | --- | --- |
| Cost | ~$32/month fixed + $0.045/GB processed | ~$3/month (`t4g.nano`, on-demand) + standard EC2 data transfer |
| Availability | Managed, AZ-resilient | Single point of failure unless built HA manually |
| Maintenance | None (AWS-managed) | OS patching, iptables/NAT config, AMI upgrades |
| Throughput | Scales automatically (up to 100 Gbps) | Capped by instance size |

For this Landing Zone's actual traffic profile (personal lab, no production SLA), a **NAT Instance is the better cost fit** — roughly 10x cheaper than NAT Gateway, and the availability/throughput ceiling a `t4g.nano` imposes is not a real constraint here. NAT Gateway's managed reliability is worth paying for once there's a workload with an actual uptime requirement, not before.

**Cheaper still: no NAT at all, until something actually needs outbound access.** Per the Decision section above, private subnets in workload VPCs currently have no outbound route at all — that's $0 and remains the default until a specific workload needs it. VPC Gateway Endpoints (S3, DynamoDB — free, no hourly charge) can also satisfy some outbound traffic without any NAT path at all, if the destination is one of the services they cover.

**Working conclusion (not yet implemented):** when egress is needed, prefer a NAT Instance in the `Networking` hub over NAT Gateway, sized minimally (`t4g.nano` or smaller), with Gateway Endpoints covering S3/DynamoDB traffic to reduce what has to go through NAT at all. Revisit NAT Gateway only if a real availability requirement shows up and the topology moves to Transit Gateway — it is not an option under plain VPC Peering.
