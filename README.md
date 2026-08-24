# AWS Multi-Account Landing Zone Implementation

## Overview

This repository contains the Infrastructure as Code (IaC) and architectural decisions records (ARDs) for deploying an **AWS Control Tower Landing Zone**. It establishes a multi-account governance framework tailored for both experimental lab environments and production-grade multi-stage workloads.

## Architecture

```text
Root
├── Security OU
│   ├── LogArchive            # Control Tower Managed
│   └── Aggregator account    # Control Tower Managed
├── Infrastructure OU
│   ├── Shared Services
│   └── Networking
├── Sandbox OU                # Labs and experimentation
├── Workloads OU              # Operational Environments
│   ├── Dev OU
│   ├── Staging OU
│   └── Prod OU
└── Policy Staging OU
```

## Prerequisites - In progress

## Repository Structure

```text
├── docs
│   └── adr
├── README.md            # this file
└── terraform
```

## Status

- [x] Fresh AWS Account created
- [x] Root account secured with Multi-Factor Authentication (MFA)
- [x] IAM user created with `AdministratorAccess`and MFA configured
- [x] Programmatic credentials and local AWS CLI profile configured
- [x] IAM user and role access to Billing information
- [x] Billing Budgets & CloudWatch billing alarm
- [x] ADR-001-OU-Structure Documented
- [x] AWS Control Tower Wizard run
- [x] Create the missing OUs according to ADR-001
	- Infrastructure OU
	- Workloads OU
		- Dev OU
		- Staging OU
		- Prod OU
	- Policy Staging OU
- [x] ADR-002-Foundational Account and Parameters Documented
- [x] ADR-003-Guardrail-Strategy Documented
- [x] Create Policy Staging test account via Account Factory (manual, persistent staging account)
- [ ] Create & test SCP #1 (Restricted EC2 instance types) manually in Policy Staging
- [ ] Create & test SCP #2 (Deny Transit Gateway creation) manually in Policy Staging
- [ ] Create & test SCP #3 (Require mandatory resource tags) manually in Policy Staging
- [ ] Automate with Terraform: Policy Staging test account provisioning
- [ ] Automate with Terraform: SCP #1, #2, #3 (attach to their target OUs per ADR-003)
- [ ] Decide: keep Policy Staging test account persistent, or destroy after automation
