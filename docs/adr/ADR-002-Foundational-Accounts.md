# ADR-002: Foundational Account and Parameters

## Status

Accepted

## Context

AWS Control Tower Landing Zone 4.0 changed how foundational accounts are organized compared to previous versions.

Prior to 4.0, Config and CloudTrail shared resources and were conceptually bundled under a single "Audit" account acting as a general security/logging account. I the new version, this is decoupled: Config and CloudTrail now use separate dedicated S3 buckets and SNS topics instead of shared resources, The wizard no longer assumes a single predefined "Audit" account, instead it asks separately which account should serve as the _Config Aggregator_ and which should serve as the _CloudTrail administrator_, allowing the user to customize the names of this accounts.

### Implementation Discovery

During the Control Tower deployment wizard, you must enable or disable AWS Config for detective controls. If you enable it, you must select the account that will be used for log aggregation; if no account exists, you must create a new one.

During the first attempt to run the wizard, this step involved creating a new account named `Audit` (with a dedicated email address for that account).

Next, you must enable AWS CloudTrail Centralized Logging, where you must similarly specify the account to be used for CloudTrail Administrator. This account cannot be the same one used in the previous step; it must be a separate account.

In this step, the wizard was canceled to reevaluate the most appropriate names for each of these accounts. However, even though the wizard was canceled and Control Tower was not deployed on the first attempt, the AWS Organization had already been created, with the current account as the management account; the Audit account had also been created within the Security OU.

The Audit account was located within the AWS Organization and deleted before attempting to deploy Control Tower again.

In this new attempt, new accounts were assigned for both the Config service and CloudTrail; these were the Aggregator account and LogArchive, respectively.

## Decision

The following account names are adopted for the Control Tower's foundational accounts, instead of the previously planned and used scheme in earlier versions.

The `Audit` account is closed, and although it remains part of the Organization, it was never managed by the Control Tower.

| Account              | Email alias                | OU       | Role                                                                                          |
| -------------------- | --------------------------- | -------- | --------------------------------------------------------------------------------------------- |
| `Aggregator account` | dedicated alias (redacted) | Security | AWS Config delegated administrator (Service-Linked Config Aggregator)                         |
| `LogArchive`         | dedicated alias (redacted) | Security | Centralized CloudTrail log storage                                                            |
| `Audit` (closed)     | dedicated alias (redacted) | Security | Orphaned from first attempt — never reached active Control Tower management; see Consequences |

**Configuration parameters chosen:**

| Parameter                                | Value               | Rationale                                                                                                                                                                                                                   |
| ---------------------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AWS Config log retention (S3)            | 30 days             | Cost-conscious starting point for a lab/dev environment with no compliance requirement; revisit if this landing zone starts hosting production workloads.                                                                   |
| AWS Config access log retention          | 60 days             | Enough to trace who accessed the Config S3 bucket without carrying CloudTrail's forensic-grade retention standard.                                                                                                          |
| CloudTrail log retention (S3)            | 30 days             | Same cost-conscious reasoning as Config's log retention.                                                                                                                                                                    |
| CloudTrail access log retention          | 90 days             | Aligned with common compliance minimums (PCI-DSS, HIPAA reference points) for auditing access to the audit trail itself — even though this lab carries no real regulatory requirement, chosen as a good habit from day one. |
| KMS key encryption (Config / CloudTrail) | Not enabled         | AWS-managed encryption (SSE-S3) used instead of customer-managed keys, to avoid the fixed cost of KMS CMKs at this stage. Revisit explicitly if compliance requirements ever demand customer-managed keys.                  |
| AWS Backup integration                   | Disabled            | No stateful workloads exist yet to protect; revisit once real workload accounts with persistent data are provisioned.                                                                                                       |
| Identity management                      | IAM Identity Center | AWS Control Tower sets up account access via IAM Identity Center natively. Plan to migrate day-to-day authentication from IAM user access keys to Identity Center federation (`aws login`) now that it exists.              |
| Governed regions                         | us-east-1 only      | Matches the home region decision; each additional governed region duplicates the Config Recorder baseline cost.                                                                                                             |

## Consequences

**Positive:**

- The decoupled Aggregator/LogArchive model matches landing zone 4.0's actual architecture, which will make future delegated-admin extensions (GuardDuty, Security Hub) more straightforward, since 4.0 is designed around per-service delegated administrators rather than one general-purpose Audit account.
- Zero drift, full compliance on the completed deployment.

**Negative / minor technical debt:**

- **Orphaned `Audit` account**: It appears on AWS Organization with status Closed Status but not managed by Control Tower, even is Closed , AWS deletes all resources in the account and the account becomes unrecoverable 90 days after it's closed.
- **Naming inconsistency vs. the original plan.** "Aggregator account" and "LogArchive" are used instead of "Audit" and "Log Archive." Functionally equivalent; cosmetic only, and documented here as intentional rather than left unexplained.
- **No KMS customer-managed keys.** Acceptable for a lab-scale deployment with no compliance mandate; would need explicit reconsideration before this landing zone hosts anything with a real regulatory or contractual encryption requirement.

## Alternatives Considered

- **Force a single "Audit" account for both Config and CloudTrail roles**, matching the original plan and older tutorials: rejected — landing zone 4.0 no longer treats this as the default or even the primary supported pattern, and forcing it against the wizard's own model would create more inconsistency with AWS's current documentation, not less.
- **Attempt to reinstate/reuse the closed `Audit` account** instead of letting it age out: rejected — not worth the operational complexity for a lab-scale deployment; the 90-day grace period resolves it automatically at no cost.
