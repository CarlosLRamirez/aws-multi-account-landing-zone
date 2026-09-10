---
title: Guardrail Strategy
status: ready
date: 2026-08-20
---

# ADR-003: Guardrail Strategy (Control Tower Controls vs. Custom SCPs)

## Status

Accepted

## Context

Control Tower enabled **13 mandatory preventive controls** on the Security OU by default. All of them protect resources provisioned by Control Tower itself, like CloudTrail configuration, Config recording, Log Archive S3 bucket encryption/logging, and the supporting roles, Lambda functions, and SNS/CloudWatch resources that make the landing zone's own guardrails work:

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

None of these controls serves as guardrails for workloads deployed inside users accounts. Additional, tailored controls are needed for that purpose, whether drawn from general best practices, organization-specific requirements, or alignment with standard baselines like the CIS AWS Foundations Benchmark (and, for regulated industries, standards like PCI DSS or HIPAA).

This landing zone's purpose is a personal lab and portfolio project, built to resemble a real enterprise environment rather than to host one. The SCPs proposed here reflect that: enterprise-grade governance criteria, kept intentionally minimal, and constrained to policies that cost $0 or effectively $0 to run.

## Decision

The decision is to apply three small custom SCPs. Each policy attaches only to the relevant OU.

1. Restricted EC2 instance types (cost guardrail)
2. Deny Transit Gateway creation
3. Require mandatory resource tags

### 1. Restricted EC2 instance types (cost guardrail)

**Policy document:** [`policies/scp-1-restricted-ec2-instance-types.json`](../../policies/scp-1-restricted-ec2-instance-types.json)

**Applies to:** Dev OU, Staging OU, Sandbox OU.

**Denies:** `ec2:RunInstances` unless the requested instance type is on an approved list of low-cost types (e.g. `t3.micro`, `t3.small`, `t2.micro`).

Why: It stops an accidental launch of an expensive instance. This happens with a typo in the instance type. It also happens when someone copies an example from documentation that uses a GPU or a large instance. These environments do not need that capacity. Sandbox gets the same rule as Dev and Staging. It has high amounts of temporary testing. Prod OU does not get this restriction. A production workload might need a larger instance. That decision goes through the review process of Prod instead of an organization-wide rule.

### 2. Deny Transit Gateway creation

**Policy document:** [`policies/scp-2-deny-transit-gateway.json`](../../policies/scp-2-deny-transit-gateway.json)

**Applies to:** all OUs except Security. That includes Infrastructure, Sandbox, Workloads (inherited by Dev, Staging, Prod), and Policy Staging.

**Denies:** `ec2:CreateTransitGateway`, `ec2:CreateTransitGatewayVpcAttachment`.

Why: Transit Gateway has hourly costs and per-GB costs. This rule stops users from creating one to test and forgetting it. It matches our decision to use VPC Peering instead of Transit Gateway at this scale (ADR-004). At enterprise scale or with more accounts, this choice can change. This is the decision for now.

This rule includes the Infrastructure OU and the `Networking` account. We made no exception on purpose (see ADR-004). The `Networking` account is the normal place to build a Transit Gateway. An exception creates an easy mistake in the policy. If the decision changes later, we will update or remove this SCP. We will not leave an unexplained exception.

### 3. Require mandatory resource tags

**Policy document:** [`policies/scp-3-require-mandatory-tags.json`](../../policies/scp-3-require-mandatory-tags.json)

**Applies to:** Workloads OU (inherited by Dev, Staging, and Prod).

**Denies:** `ec2:RunInstances`, `rds:CreateDBInstance`, `s3:CreateBucket` unless the request includes `Project` and `Environment` tags.

Why: This SCP supports a future need. It does not only prevent risk. This landing zone will host multiple future projects. If we do not require tagging from the start, we cannot track cost and ownership across projects later. It is cheaper to enforce this now before workloads exist. We should not add tags to existing resources later.

Note: We originally proposed this for all OUs except Security. We changed it to Workloads OU when we attached it. Infrastructure and Policy Staging do not host project workloads. Sandbox is excluded for the same reason.

## Consequences

Positive: It fixes the actual safety gap from default Control Tower controls. Workloads get baseline protection. We do not rely on people remembering the rules. All three SCPs apply to every new account in those OUs automatically. You do not need extra setup for each account.

Negative: We must write these three SCPs. We must test them in Policy Staging OU. We must maintain them in Terraform. Control Tower updates its controls automatically. AWS does not update these SCPs if best practices change.

## Alternatives Considered

- Wait and add SCPs only once a real workload account exists. Rejected. These SCPs do not cost money. They protect every new account under the target OUs immediately. This includes accounts for this project.

- Recreate everything Control Tower does. Rejected. We do not want to duplicate existing AWS controls.

- Add a fourth custom SCP to restrict allowed regions. Rejected. Control Tower already has a control for this, `AWS-GR_REGION_DENY`, which only allows regions it governs and performs the same task. If we need a second region later, such as a DR lab, we will add that region to Control Tower instead — or reconsider a custom SCP at that time.
