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

## Prerequisites

- In progress

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
- [x] ADR-002-Foundational Account and Parameters Documented
- [x] ADR-003-Guardrail-Strategy Documented
- [ ] Custom Guardrails deployment via Terraform
