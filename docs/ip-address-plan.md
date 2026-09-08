# IP Address Plan

This is the living reference for CIDR allocation across the organization. The design rationale (why a hierarchical scheme replaced a flat one, why three VPC layouts instead of one) lives in [ADR-004](adr/ADR-004-Networking-Strategy.md) — this document only tracks what's allocated, what's reserved, and what's actually deployed. Update this file whenever a new slot is assigned; ADR-004 itself doesn't need to change for that.

Last updated: 2026-09-07.

## Organization-level allocation

Two `/16`s are allocated (`10.0.0.0/16`, `10.1.0.0/16`); only the first slot of each pool is in use today. The 8-slot pools per environment are address-space margin, not a commitment to multiple accounts per environment — as of this writing, it's still one account each for Dev/Staging/Prod/Sandbox.

| CIDR | Purpose | Status |
| --- | --- | --- |
| `10.0.0.0/21` | `Networking` hub | **In use** |
| `10.0.8.0/21` | `Shared Services` | Reserved — account not created yet |
| `10.0.16.0/21` | Cross-cutting / security tooling | Reserved — no account identified |
| `10.0.24.0/21` | Cross-cutting / security tooling | Reserved — no account identified |
| `10.0.32.0/21` | Cross-cutting / security tooling | Reserved — no account identified |
| `10.0.40.0/21` | Cross-cutting / security tooling | Reserved — no account identified |
| `10.0.48.0/23` | Sandbox pool, slot 1 | Reserved — Sandbox account not created yet |
| `10.0.50.0/23` – `10.0.62.0/23` (7× `/23`) | Sandbox pool, slots 2–8 | Reserved — future Sandbox accounts |
| `10.0.64.0/20` | Dev pool, slot 1 | Reserved — Dev account not created yet |
| `10.0.80.0/20` – `10.0.176.0/20` (7× `/20`) | Dev pool, slots 2–8 | Reserved — future Dev accounts |
| `10.0.192.0/20` | Staging pool, slot 1 | Reserved — Staging account not created yet |
| `10.0.208.0/20` – `10.1.48.0/20` (7× `/20`) | Staging pool, slots 2–8 | Reserved — future Staging accounts |
| `10.1.64.0/20` | Prod pool, slot 1 | Reserved — Prod account not created yet |
| `10.1.80.0/20` – `10.1.176.0/20` (7× `/20`) | Prod pool, slots 2–8 | Reserved — future Prod accounts |

## VPC-internal layouts

Three distinct shapes, per ADR-004 — `Networking`, workload accounts, and Sandbox each have different needs.

### `Networking` hub — `10.0.0.0/21` (in use)

3 AZs, `/24` subnets (newbits 3 from the `/21`, 8 slots total). Built as plain resources in [`terraform/networking.tf`](../terraform/networking.tf), not a module.

| CIDR | AZ | Subnet Type |
| --- | --- | --- |
| `10.0.0.0/24` | A | Private |
| `10.0.1.0/24` | A | Public (Future) |
| `10.0.2.0/24` | B | Private |
| `10.0.3.0/24` | B | Public (Future) |
| `10.0.4.0/24` | C | Private |
| `10.0.5.0/24` | C | Public (Future) |
| `10.0.6.0/24` | — | Reserved |
| `10.0.7.0/24` | — | Reserved |

"Public (Future)" subnets are provisioned now but carry no Internet Gateway and no route to one — they reserve address space and AZ placement for a future centralized-egress NAT (see ADR-004's "Networking Considerations"). Deployed: `aws_vpc.networking_hub` = `vpc-021f251e55eebe1cf`, in account `623609441070` (Account-Factory-provisioned, full Control Tower baseline — see ADR-004's "Control Tower Enrollment").

### Workload VPCs (Dev, Staging, Prod) — `vpc-baseline` module

3 AZs, `/24` subnets (newbits 4 from a `/20`, 16 slots total, 12 used). Module: [`terraform/modules/vpc-baseline`](../terraform/modules/vpc-baseline). Not yet instantiated — no Dev/Staging/Prod accounts exist yet. Pattern shown below applies to whichever `/20` slot an environment uses (e.g. Dev's slot 1 is `10.0.64.0/20`).

| CIDR offset | AZ | Subnet Type |
| --- | --- | --- |
| +0 | A | Public (Web) |
| +1 | A | Private (App) |
| +2 | A | Private (Data) |
| +3 | A | Reserved / TBD |
| +4 | B | Public (Web) |
| +5 | B | Private (App) |
| +6 | B | Private (Data) |
| +7 | B | Reserved / TBD |
| +8 | C | Public (Web) |
| +9 | C | Private (App) |
| +10 | C | Private (Data) |
| +11 | C | Reserved / TBD |
| +12 – +15 | — | Reserved for future `/23` expansion |

### Sandbox VPCs — `vpc-sandbox` module

2 AZs, `/26` subnets (newbits 3 from a `/23`, 8 slots total, 6 used). Module: [`terraform/modules/vpc-sandbox`](../terraform/modules/vpc-sandbox). Not yet instantiated — no Sandbox account exists yet. Pattern shown below applies to whichever `/23` slot a Sandbox account uses (slot 1 is `10.0.48.0/23`).

| CIDR offset | AZ | Subnet Type |
| --- | --- | --- |
| +0 | A | Public |
| +1 | A | Private |
| +2 | A | Private |
| +3 | B | Public |
| +4 | B | Private |
| +5 | B | Private |
| +6 | — | Reserved |
| +7 | — | Reserved |

## Change log

- **2026-09-07 (later same day)** — Closed the `Networking` account entirely and recreated it via Account Factory (Account ID `623609441070`), so it's Control Tower-managed from birth instead of retrofitting enrollment onto it (see ADR-004's "Control Tower Enrollment"). Rebuilt the hub VPC a second time on the same `/21` design, now in the new account: `vpc-021f251e55eebe1cf`.
- **2026-09-07** — Superseded the flat 5×`/20` plan (one `/20` per account, no reserved growth space) with this hierarchical scheme. Rebuilt the `Networking` hub VPC on its new `/21` (destroy+recreate, no peering existed yet so no live dependency broke). Rewrote `vpc-baseline` for 3 AZs/3 tiers and added `vpc-sandbox` as a separate module.
- **2026-09-04** — Original flat plan: `Networking` `10.0.0.0/20`, Dev `10.1.0.0/20`, Staging `10.2.0.0/20`, Prod `10.3.0.0/20`, Sandbox `10.4.0.0/20`. Superseded above.
