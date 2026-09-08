# Accounts provisioned directly through Organizations rather than through
# Control Tower's Account Factory. Per ADR-005, this is Terraform's scope for
# account provisioning going forward: non-Control-Tower-managed accounts.
#
# `Networking` used to live here (created 2026-09-03 via
# aws_organizations_account, no Control Tower baseline). Closed and
# recreated 2026-09-07 through Account Factory instead, so it gets the full
# CT baseline (CloudTrail, Config, AWSControlTowerExecution role) — see
# ADR-004's "Control Tower Enrollment" section. An Account-Factory-created
# account is Control-Tower-managed, so per ADR-005 it stays out of this
# file/state entirely — only the provider alias in main.tf references it
# (by ID, via var.networking_account_id).
#
# This file is currently empty of resources. It stays as the designated
# home for any future account that's deliberately created outside Account
# Factory (the exception, not the default — see README's "Provisioning a
# New Workload Account").
