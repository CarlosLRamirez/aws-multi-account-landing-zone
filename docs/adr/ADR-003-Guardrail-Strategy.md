---
title: Guardrail Strategy
status: ready
date: 2026-08-20
---

# ADR-003: Guardrail Strategy (Control Tower Controls vs. Custom SCPs)

## Status

Proposed

## Context

Control Tower enabled **13 mandatory preventive controls** on the Security OU by default (verified via `list-enabled-controls`). All of them protect resources provisioned by Control Tower itself, like CloudTrail configuration, Config recording, Log Archive S3 bucket encryption/logging, and the supporting roles, Lambda functions, and SNS/CloudWatch resources that make the landing zone's own guardrails work:

| No. | Control                                                                          | Protects                                                        |
| --- | -------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| 1   | Enable AWS Config in all available regions                                       | Config recorder can't be selectively disabled in a region       |
| 2   | Disallow configuration changes to AWS Config                                     | Config recorder itself can't be reconfigured or disabled        |
| 3   | Disallow changes to AWS Config Rules set up by Control Tower                     | Compliance rules CT deployed can't be weakened or deleted       |
| 4   | Disallow modifications to AWS Config recorder S3 buckets managed by CT           | Where Config data lands can't be altered                        |
| 5   | Disallow modifications to S3 buckets managed by CT                               | CloudTrail/Config log buckets broadly protected                 |
| 6   | Disallow changes to CloudWatch set up by Control Tower                           | CT's compliance-monitoring alarms and dashboards protected      |
| 7   | Disallow changes to CloudWatch Logs Log Groups                                   | Log groups holding the audit trail can't be tampered with       |
| 8   | Disallow changes to Amazon SNS set up by Control Tower                           | CT's alert notification topics protected                        |
| 9   | Disallow changes to Amazon SNS subscriptions set up by Control Tower             | Who receives those alerts can't be silently changed             |
| 10  | Disallow changes to Amazon SNS subscriptions and topics managed by CT            | Broader variant covering both topics and subscriptions together |
| 11  | Disallow changes to Lambda functions set up by Control Tower                     | Automation behind CT's guardrails can't be altered              |
| 12  | Disallow changes to IAM roles set up by AWS Control Tower and AWS CloudFormation | Service roles CT depends on to function are protected           |
| 13  | Deny access to AWS based on the requested Region (`AWS-GR_REGION_DENY`)          | Blocks API calls outside the landing zone's governed regions    |

None of these govern actual user workloads deployed _on top of_ the landing zone. Custom SCPs are needed for that purpose.

This landing zone is a personal lab and portfolio project, built to resemble a real enterprise environment rather than to host one. The SCPs proposed here reflect that: enterprise-grade governance criteria, kept intentionally minimal, and constrained to policies that cost $0 or effectively $0 to run.

## Decision

The decision is to apply three minimal but meaningful custom SCPs, each attached only to the OU where it's actually relevant.

1. Restricted EC2 instance types (cost guardrail)
2. Deny Transit Gateway creation
3. Require mandatory resource tags

A 4th SCP was considered early on, to restrict which regions could be used. That's no longer needed: Control Tower already has a control for this, `AWS-GR_REGION_DENY`, which only allows the regions it governs, so it already does what that SCP would have done. If a second region is ever needed in the future (for example, a DR lab), that region will simply be added to Control Tower's governed regions, or another solution will be found at that point.

### 1. Restricted EC2 instance types (cost guardrail)

**Applies to:** Sandbox OU, Dev OU.

**Denies:** `ec2:RunInstances` unless the requested instance type is on an approved list of low-cost types (e.g. `t3.micro`, `t3.small`, `t2.micro`).

**Why:** stops an accidental expensive instance launch, like a typo in the instance type, or a copy-pasted example from documentation that uses a GPU or large memory-optimized instance in environments where there's no real reason to need that capacity. Prod OU doesn't get this restriction. A production workload might actually need a bigger instance, and that decision should go through Prod's own review process instead of a blanket org-wide rule.

### 2. Deny Transit Gateway creation

**Applies to:** Sandbox OU, Workloads OU.

**Denies:** `ec2:CreateTransitGateway`, `ec2:CreateTransitGatewayVpcAttachment`.

**Why:** Transit Gateway has real per-hour and per-GB costs, so this control makes sure nobody spins one up just to experiment and forgets about it. It also lines up with the decision to use VPC Peering instead of Transit Gateway at the current scale (ADR-004). At enterprise scale, or with a lot more accounts, this might make less sense, but for now that's the call.

Not applied to the Infrastructure OU, in case a future decision is made to run Transit Gateway centrally from a Networking account.

### 3. Require mandatory resource tags

**Applies to:** all OUs except Security OU (Control Tower-managed accounts don't need project-level tagging).

**Denies:** `ec2:RunInstances`, `rds:CreateDBInstance`, `s3:CreateBucket` unless the request includes `Project` and `Environment` tags.

**Why:** this is the one SCP here based on an actual future need, not just risk prevention. This landing zone is meant to host multiple future projects, not just this one. Without tagging enforced from day one, tracking cost and ownership across projects becomes impossible to fix later. It's cheaper to enforce this now, before any real workload exists, than to retrofit tagging discipline onto resources that already exist.

## Consequences

**Positive:** closes the actual gap left by Control Tower's default controls. Workloads get baseline protection instead of relying on people remembering to be careful. All three SCPs apply automatically to every account created under their target OUs going forward, with no extra setup per account.

**Negative:** these 3 SCPs need to be written, tested in Policy Staging OU, and kept up to date in Terraform. Unlike Control Tower's controls, AWS doesn't update them automatically if best practices change.

## Alternatives Considered

- **Wait and add SCPs only once a real workload account exists.** Rejected. These SCPs cost nothing to have in place early, and they protect every account created under their target OUs from that point on, including this project's own accounts.
- **Recreate everything Control Tower's 13 controls already do, as custom SCPs, just to have it all visible in Terraform.** Rejected. It's redundant, and risks drifting from Control Tower's own policies over time. The platform already owns and maintains that layer.
