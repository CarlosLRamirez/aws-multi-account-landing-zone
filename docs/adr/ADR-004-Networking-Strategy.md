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

A hierarchical scheme that pre-reserves address space by function and environment, so future accounts within an environment don't require renumbering anything already deployed. The full allocation table, per-VPC subnet layouts, and change history now live in [`docs/ip-address-plan.md`](../ip-address-plan.md) — that document tracks current allocation state and gets updated whenever a new slot is assigned; this ADR records the design rationale, which doesn't change just because a slot got used.

In summary: `Networking` hub and `Shared Services` each get a `/21`; 4 more `/21`s are reserved for future cross-cutting/security tooling; Dev, Staging, Prod, and Sandbox each get a pool of 8 slots (`/20` for workload environments, `/23` for Sandbox) with only the first slot in use. **The 8-slots-per-environment pools are address-space margin, not a commitment to multiple accounts per environment** — as of this revision, the plan is still one account each for Dev/Staging/Prod/Sandbox; the extra 7 slots per pool exist so that *if* a future need arises (e.g. splitting Dev by team), it's a new VPC in already-reserved space, not a renumbering exercise across the whole org.

**Three different internal layouts, not one — `Networking`, workload accounts, and Sandbox all have distinct shapes** (full subnet tables in `docs/ip-address-plan.md`):

- **Workload VPCs** (Dev, Staging, Prod) — 3-tier layout across 3 AZs: Public (Web), Private (App), Private (Data), plus one reserved/TBD slot per AZ and 4 more reserved for future `/23` expansion. Reserved slots are **not provisioned as `aws_subnet` resources** — they're address space held for later, not idle infrastructure. One Internet Gateway, no NAT Gateway yet (same reasoning as before — see Consequences). Implemented as the reusable Terraform module `terraform/modules/vpc-baseline`, instantiated once per workload account.
- **Sandbox VPCs** — smaller footprint, since sandbox workloads don't need production-grade capacity: 2 AZs, one Public + two Private `/26` subnets per AZ. A separate module, `terraform/modules/vpc-sandbox` — not a smaller instance of `vpc-baseline`, since the tier count and AZ count differ enough that forcing one module to cover both would need conditional logic that isn't worth the complexity at this scale.
- **The `Networking` hub VPC** — one Private + one Public (Future) subnet per AZ across 3 AZs. "Public (Future)" subnets are provisioned now but carry **no Internet Gateway and no route to one yet** — they reserve the address space and AZ placement for the day this account centralizes egress (NAT Instance/Gateway) per the "Networking Considerations" section below, without requiring a resize later. This account still runs no application workloads — the Private subnets remain the peering attachment points, and a future Virtual Private Gateway would land its propagated routes there too. Kept as plain resources in `terraform/networking.tf` rather than either workload module, since neither shape matches what this account is for.

**Cross-account Terraform.** Each account's VPC is created from the same Terraform state as everything else in this repo (ADR-005), via a per-account AWS provider alias that assumes a cross-account role rather than giving each account its own Terraform backend. `Networking` was created directly through `aws_organizations_account` (not Account Factory), so it only has the default `OrganizationAccountAccessRole` Organizations grants automatically — not Control Tower's `AWSControlTowerExecution`. Accounts created later via Account Factory (Dev, Staging, Prod) will need their own alias using that role instead once they exist. Keeping one shared backend, rather than a backend per account, was chosen for the same cost-discipline reason ADR-005 gives for not splitting state in the first place: an extra S3 bucket and lockfile per account buys isolation this project doesn't need yet.

## Consequences

**Positive:**

- $0 fixed networking cost until real cross-VPC traffic exists — VPC Peering has no hourly charge, only data transfer once it's actually used.
- Matches the guardrail already in place (SCP #2 denies Transit Gateway org-wide, with no exception for the `Networking` account) — no gap between what's technically blocked and what's architecturally decided.
- Hub-and-spoke via a single `Networking` account keeps a future centralized egress/inspection point possible without redesigning the topology later.

**Negative:**

- VPC Peering isn't transitive — every new spoke needs its own explicit peering connection to the hub, with route table updates on both sides. This stops being comfortable to manage by hand somewhere around 10 VPCs.
- No AWS-native central route table the way Transit Gateway provides one; more Terraform code to maintain per-VPC routes as the number of spokes grows.

**CIDR revision migration cost (2026-09-07).** A VPC's primary CIDR block can't be changed in place — moving the hub from `10.0.0.0/20` to `10.0.0.0/21` forces Terraform to destroy and recreate `aws_vpc.networking_hub` and everything attached to it (subnets, route tables, associations). This is low-risk today only because no peering connections exist yet and the account runs no workloads (per CLAUDE.md, "no peering connections yet" as of this revision) — the same CIDR change made after real peering/workloads existed would be a breaking change requiring a maintenance window. Applying this revision is a `terraform apply` the user runs deliberately, not something to automate.

**Control Tower Enrollment.**

The `Networking` account was created via Terraform (`aws_organizations_account` in `terraform/accounts.tf`) rather than Control Tower's Account Factory, and is not currently enrolled in Control Tower baseline (no CloudTrail, Config, or IAM role setup from CT). This was chosen for cost discipline — avoiding Control Tower baseline charges on an account that doesn't run workloads — but carries a governance trade-off:

*Current state (as of 2026-09-07):*
- ✅ Cost: $0 baseline overhead, no Control Tower charges
- ❌ Auditability: CloudTrail logs don't flow to central aggregator account; Config compliance not recorded
- ❌ Uniform controls: 13 mandatory preventive SCPs from Control Tower don't apply; relying on manual SCP #2 (Deny Transit Gateway) coverage instead
- ❌ Operational drift detection: no built-in Control Tower drift checks; requires manual verification

*Production reality check:*
In a real enterprise environment, the best practice would be to enroll *all* accounts in Control Tower, including infrastructure/hub accounts, even if they don't run workloads. Governance and audit logging should be uniform across the organization; differentiation should come from targeted SCPs and permission sets, not from removing accounts from the baseline entirely. The exception to this rule — keeping platform/infrastructure accounts outside Control Tower — is rare and requires explicit organizational policy.

*Can it be enrolled later?*
Yes — Control Tower supports enrolling existing accounts retrospectively via `aws controltower enable-baseline --account-id 204957733187`. This creates the necessary IAM roles (`AWSControlTowerExecution`, CloudTrail log archive access), applies the 13 mandatory preventive SCPs, and starts recording CloudTrail/Config prospectively. **However, this creates audit gaps.** Any resources created before enrollment (in this case, the VPC and subnets created 2026-09-03) won't have a Config compliance history, and CloudTrail logs from before enrollment won't flow to the central aggregator account. The operational result is functionally identical to day-one enrollment, but the audit trail has a hole from 2026-09-03 to the enrollment date.

Best practice: **create all accounts via Account Factory from the start** — it auto-enrolls and avoids audit gaps. Enrolling after the fact is acceptable for POCs and demos but not for production accounts with compliance requirements.

*Resolved 2026-09-07:* rather than retrofit enrollment onto the existing account (and inherit the audit gap described above), the account was closed and recreated from scratch via Account Factory — at this stage the account held only a VPC with no peering connections and no workloads, making a full rebuild cheaper than living with a permanent hole in the audit trail. New account: `623609441070`, born with the full Control Tower baseline (CloudTrail, Config, `AWSControlTowerExecution` role) from the moment it existed. This was only possible because it was still Month 1 — the same rebuild after real peering/workloads existed would need the retrospective-enrollment path above instead, audit gap and all.

Two things this rebuild needed that hadn't been necessary before, both worth remembering for the next account: (1) the target OU has to be **registered** with Control Tower before Account Factory can provision into it — creating the OU in Organizations isn't enough (`Infrastructure` needed this registration; `Policy Staging` already had it from the `SCP-test` days), and Control Tower refuses to register an OU that contains suspended/closed accounts, which is why the old `Networking`, `Audit`, and `SCP-test` accounts got moved into a new `ClosedAccounts` OU first; (2) launching Account Factory itself requires the IAM Identity Center principal to be associated with the "AWS Control Tower Account Factory" Service Catalog portfolio — a separate access layer from IAM policy, so `AdministratorAccess` alone isn't enough. Both are one-time setup costs per OU/principal, not something every future account provisioning repeats.

## Alternatives Considered

- **Transit Gateway hub-and-spoke.** Rejected for now: real per-attachment-hour and per-GB cost with no workloads yet to justify it, and already blocked org-wide by SCP #2. Revisit if account count grows enough that peering's management overhead exceeds Transit Gateway's cost.
- **Full-mesh VPC Peering** (every account peers directly with every other account). Rejected: no central point for future inspection/egress control, and connection count grows quadratically instead of linearly with each new account.
- **No cross-account networking at all** (fully isolated VPCs, communicating only via S3/API if at all). Rejected: too restrictive for realistic multi-tier workloads — e.g. a Shared Services account hosting a private package registry that Dev/Staging/Prod need to reach over the network.

## Networking Considerations (Future Work)

Open questions and design notes for when the Landing Zone needs actual egress/ingress to the internet — not yet implemented, captured here so the reasoning isn't lost before it's needed.

**Centralized egress (NAT) vs. centralized ingress (IGW) — these are not the same problem.**

- **Centralized egress is viable with VPC Peering.** A single NAT Gateway (or NAT instance) in the `Networking` hub can serve all workload VPCs: `private subnet → peering connection → Networking hub → NAT → IGW → Internet`. This matches the hub-and-spoke topology already chosen and gives one choke point for future egress inspection/logging. The hub's `/21` layout (see Decision section above) already reserves one "Public (Future)" `/24` per AZ for exactly this — when the day comes, it's a matter of adding an Internet Gateway and a NAT resource in those subnets, not a redesign.
- **Centralized ingress is not practical with VPC Peering.** An Internet Gateway is bound to a single VPC — it can't be "shared" across peered VPCs the way a NAT path can. If a workload account (e.g. Prod) needs to expose something to the internet (an ALB, a public endpoint), that resource needs its own IGW/public subnet in its own VPC. Centralizing inbound traffic through the hub would require Transit Gateway + Gateway Load Balancer, VPC Lattice, or PrivateLink — none of which fit cleanly on top of plain VPC Peering. Conclusion: **each workload account keeps its own IGW for public-facing resources; only the outbound path centralizes.**

**Correction (2026-09-10): "centralized egress is viable with VPC Peering" above is only true for a NAT *instance*, not a NAT *Gateway*.** AWS's VPC Peering documentation lists "edge to edge routing through a gateway" as an explicitly unsupported configuration: a peered VPC cannot route traffic onward through another VPC's Internet Gateway, NAT Gateway, VPN connection, or Direct Connect connection. A managed NAT Gateway in the `Networking` hub therefore **cannot** serve spoke VPCs' outbound traffic at all — it's not a matter of cost or complexity, it simply doesn't route. A self-managed NAT instance (a plain EC2 host doing IP forwarding, not one of AWS's "gateway" constructs) is unaffected by this restriction and works fine across peering, which is what the "Working conclusion" below already recommends — that recommendation now rests on a hard technical constraint, not only the cost comparison it was originally framed around. This doesn't change the per-account IGW conclusion in the bullet above; it only narrows which mechanism can implement the centralized-egress side of it.

**NAT Gateway vs. NAT Instance — cost trade-off for a personal-lab context.**

| | NAT Gateway (managed) | NAT Instance (EC2) |
| --- | --- | --- |
| Cost | ~$32/month fixed + $0.045/GB processed | ~$3/month (`t4g.nano`, on-demand) + standard EC2 data transfer |
| Availability | Managed, AZ-resilient | Single point of failure unless built HA manually |
| Maintenance | None (AWS-managed) | OS patching, iptables/NAT config, AMI upgrades |
| Throughput | Scales automatically (up to 100 Gbps) | Capped by instance size |

For this Landing Zone's actual traffic profile (personal lab, no production SLA), a **NAT Instance is the better cost fit** — roughly 10x cheaper than NAT Gateway, and the availability/throughput ceiling a `t4g.nano` imposes is not a real constraint here. NAT Gateway's managed reliability is worth paying for once there's a workload with an actual uptime requirement, not before.

**Cheaper still: no NAT at all, until something actually needs outbound access.** Per the Decision section above, private subnets in workload VPCs currently have no outbound route at all — that's $0 and remains the default until a specific workload needs it. VPC Gateway Endpoints (S3, DynamoDB — free, no hourly charge) can also satisfy some outbound traffic without any NAT path at all, if the destination is one of the services they cover.

**Working conclusion (not yet implemented):** when egress is needed, prefer a NAT Instance in the `Networking` hub over NAT Gateway, sized minimally (`t4g.nano` or smaller), with Gateway Endpoints covering S3/DynamoDB traffic to reduce what has to go through NAT at all. Revisit NAT Gateway if/when a real availability requirement shows up.
