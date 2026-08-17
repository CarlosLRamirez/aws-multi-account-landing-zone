# ADR-001: Organizational Units (OU)

## Status

Accepted

## Context

This Landing Zone serves several purposes: first, as an environment for learning, experimentation, and project work for my professional portfolio; and second, to provide a solid foundation to deploy personal projects and learning labs, as well as workloads that resemble enterprise environments.

The architecture enables deploying workloads through multi-stage pipelines (`dev`, `staging`, `prod`) with true isolation between environments following industry best practices. The chosen hierarchy provides the flexibility needed to host simple, sandboxed projects while maintaining the strict structure and governance required by production-grade environments.

## Decision

Use an OUs structure organized by environments (not by project), with a explicit separation between **Sandbox** (labs) and **Operational** Workloads (`Dev`/`Staging`/`Prod`):

A dedicated **Policy Staging OU** which serves as a quarantine zone for testing new or modified SCPs before applying them to the actual OUs (Foundational, Infrastructure, Sandbox and Workloads). It allows you to verify that a guardrail behaves as expected, without the risk of disrupting production or foundational accounts if the policy contains an error.

```text
Root
├── Foundational OU
│   ├── Log Archive        # Control Tower Managed
│   └── Audit              # Control Tower Managed
├── Infrastructure OU
│   ├── Shared Services
│   └── Networking
├── Sandbox OU             # Labs and experimentation
├── Workloads OU           # Operational Environments
│   ├── Dev OU
│   ├── Staging OU
│   └── Prod OU
└── Policy Staging OU
```

## Consequences

| Category | Impact                                   | Details                                                                                                                                                                                                                 |
| -------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Positive | **Environment-Wide Guardrail**           | SCPs applied at the OU level, automatically govern all current and future accounts within and environment (e.g `Prod OU` policies automatically apply all production accounts without manual replication).              |
| Positive | **Strict Structural Isolation**          | Allows true multi-account boundary isolation between `Dev` and `Prod` environments, instead of depending on naming conventions or resource tagging.                                                                     |
| Negative | **Operational Overhead & Baseline Cost** | Provisioning a new project across 2-3 accounts environment require 2-3 separate AWS accounts. Each account incurs minor baseline charges for services like AWS Config and CloudTrail (a few dollars per account/month). |
| Negative | **Identity & Access Management**         | Cross accounts access management is by nature more complex than a single-account architecture, requiring well-structured IAM Identity Center (AWS SSO) strategy - with AWS Control Tower actually helps to setup.       |

## Alternatives Considered

- Organizational Units (OUs) by Project: Structuring each project with its own sub-hierarchy (Project A -> Dev/Staging/Prod).
  - Discarded because: It requires duplicating Service Control Policies (SCPs) for every new project instead of inheriting them globally by environment. It scales poorly as project count grows, leading to OU bloat and administrative drift, while diverging from enterprise best practices.
- Single AWS Account with Logical Separation (Tags, Isolated VPCs): Hosting all environments and projects within a single AWS account using VPCs and IAM boundaries.
  - Discarded because: Logical separation does not provide true multi-tenant isolation. A single account configuration mistake or security breach exposes the entire blast radius across all projects and environments.
