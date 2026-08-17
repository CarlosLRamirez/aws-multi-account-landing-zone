# AWS Multi-Account Landing Zone Implementation

## Overview
This repository contains the Infrastructure as Code (IaC) and architectural decisions records (ARDs) for deploying an **AWS Control Tower Landing Zone**. It establishes a multi-account governance framework tailored for both experimental lab environments and production-grade multi-stage workloads.

## Architecture
- TBD

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
- [x] Root account secured with Multi-Factor Authentication (MFA) ✅ 2026-08-17
- [x] IAM user created with `AdministratorAccess`and MFA configured ✅ 2026-08-17
- [x] Programmatic credentials and local AWS CLI profile configured ✅ 2026-08-17
- [ ] AWS Control Tower Wizard run
