# ADR-002: Foundational Account and Parameters

## Status

Accepted

## Context

AWS Control Tower Landing Zone 4.0 changed how foundational accounts are organized compared to previous versions.

Prior to 4.0, Config and CloudTrail shared resources and were conceptually bundled under a single "Audit" account acting as a general security/logging account. In the new version, this is decoupled: Config and CloudTrail now use separate dedicated S3 buckets and SNS topics instead of shared resources. The wizard no longer assumes a single predefined "Audit" account; instead, it asks separately which account should serve as the _Config Aggregator_ and which should serve as the _CloudTrail administrator_, allowing the user to customize the names of these accounts.

## Decision

- Assign the following account name for the Control Tower's foundational accounts, according with Control Tower 4.0 standard.

| Account              | Email alias                                          | OU       | Role                                                                  |
| -------------------- | ---------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| `Aggregator account` | dedicated alias (e.g. `myemail+aggregator@mail.com`) | Security | AWS Config delegated administrator (Service-Linked Config Aggregator) |
| `LogArchive`         | dedicated alias (e.g. `myemail+log@mail.com`)        | Security | Centralized CloudTrail log storage                                    |

- **Configuration parameters chosen:**

| Parameter                                | Value               | Rationale                                                                                                                                                                                                                   |
| ---------------------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AWS Config log retention (S3)            | 30 days             | Cost-conscious starting point for a lab/dev environment with no compliance requirement; revisit if this landing zone starts hosting production workloads.                                                                   |
| AWS Config access log retention          | 60 days             | Enough to trace who accessed the Config S3 bucket without carrying CloudTrail's forensic-grade retention standard.                                                                                                          |
| CloudTrail log retention (S3)            | 30 days             | Same cost-conscious reasoning as Config's log retention.                                                                                                                                                                    |
| CloudTrail access log retention          | 90 days             | Aligned with common compliance minimums (PCI-DSS, HIPAA reference points) for auditing access to the audit trail itself — even though this lab carries no real regulatory requirement, chosen as a good habit from day one. |
| KMS key encryption (Config / CloudTrail) | Not enabled         | AWS-managed encryption (SSE-S3) used instead of customer-managed keys, to avoid the fixed cost of KMS CMKs at this stage. Revisit explicitly if compliance requirements ever demand customer-managed keys.                  |
| AWS Backup integration                   | Disabled            | No stateful workloads exist yet to protect; revisit once real workload accounts with persistent data are provisioned.                                                                                                       |
| Identity management                      | IAM Identity Center | AWS Control Tower sets up account access via IAM Identity Center natively.              |
| Home region | us-east-1 | |
| Governed regions                         | us-east-1 only      | Matches the home region decision; each additional governed region duplicates the Config Recorder baseline cost.                                                                                                             |

## Consequences

**Positive:**

- The decoupled Aggregator/LogArchive model matches landing zone 4.0's actual architecture, which will make future delegated-admin extensions (GuardDuty, Security Hub) more straightforward, since 4.0 is designed around per-service delegated administrators rather than one general-purpose Audit account.
- Zero drift, full compliance on the completed deployment.

**Negative / minor technical debt:**

- **No KMS customer-managed keys.** Acceptable for a lab-scale deployment with no compliance mandate; would need explicit reconsideration before this landing zone hosts anything with a real regulatory or contractual encryption requirement.

## Alternatives Considered

- **Force a single "Audit" account for both Config and CloudTrail roles**, matching older tutorials: rejected — landing zone 4.0 no longer treats this as the default or even the primary supported pattern, and forcing it against the wizard's own model would create more inconsistency with AWS's current documentation, not less.

## Appendix: The Closed `Audit` Account

An account named `Audit` exists in the AWS Organization with status `Closed`, parked in the `ClosedAccounts` OU. It was never managed by Control Tower and carries no active cost. This section explains why it exists.

During the Control Tower deployment wizard, the Config Aggregator step requires selecting (or creating) the account that will serve as Config's delegated administrator. On the first attempt to run the wizard, this step created a new account named `Audit`. The wizard was then canceled, before reaching the CloudTrail Administrator step, to reconsider the naming scheme for these foundational accounts. At that point the AWS Organization and the `Audit` account already existed, even though Control Tower itself was never deployed on that attempt.

The `Audit` account was closed before retrying the wizard. On the second attempt, new accounts were created for the Config and CloudTrail roles — `Aggregator account` and `LogArchive` — which are the accounts documented in this ADR's Decision section above.

AWS retains closed accounts for 90 days before permanently deleting them; no action is required before then. This also explains the naming difference from the "Audit" / "Log Archive" convention used in older Control Tower tutorials — the names used here (`Aggregator account`, `LogArchive`) reflect Control Tower 4.0's actual delegated-admin model and are functionally equivalent; cosmetic only.
