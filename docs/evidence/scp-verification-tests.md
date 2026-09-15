# SCP Verification — Denied and Allowed API Calls

Closes the Appendix item "SCP #1, #2, and #3 verification evidence (a denied and an allowed API call for each)". Captured 2026-09-14 by reopening the `SCP-test` account (see [ADR-003](../adr/ADR-003-Guardrail-Strategy.md) for the testing methodology) and temporarily re-attaching SCP #1 and #3 to `Policy Staging` — SCP #2 was already attached there permanently. All `RunInstances`/`CreateTransitGateway` calls use `--dry-run`, so nothing was actually created: AWS evaluates IAM and SCPs and returns `DryRunOperation` (would have succeeded) or `UnauthorizedOperation` (denied) without provisioning anything.

Long base64 `Encoded authorization failure message` blocks are truncated below for readability — the operation, resource, and policy ID lines are what confirm the SCP is the one doing the denying.

## Account reopened, parked in `Policy Staging`

```json
{
    "Account": {
        "Id": "376834080797",
        "Arn": "arn:aws:organizations::189053741492:account/o-r1e3db1vbq/376834080797",
        "Email": "carloslrm+ct26-scp-test@gmail.com",
        "Name": "SCP-TEST",
        "Status": "ACTIVE",
        "State": "ACTIVE",
        "Paths": ["o-r1e3db1vbq/r-wfup/ou-wfup-7taopy61/376834080797/"],
        "JoinedMethod": "CREATED",
        "JoinedTimestamp": "2026-08-24T11:36:51.207000-06:00"
    }
}
```

`Paths` confirms `ou-wfup-7taopy61` = `Policy Staging`.

## SCP #1 — Restrict EC2 instance types

**Denied** (`t3.medium`, outside the `t2.micro`/`t3.micro`/`t3.small` allowlist):

```text
$ aws ec2 run-instances --dry-run --image-id ami-0b301e023c868669e --instance-type t3.medium \
  --subnet-id subnet-0bfbd8493e1e8edf3 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=scp-verification},{Key=Environment,Value=test}]' \
  --profile scp-test-admin --region us-east-1

An error occurred (UnauthorizedOperation) when calling the RunInstances operation: You are not authorized to
perform this operation. User: arn:aws:sts::376834080797:assumed-role/AWSReservedSSO_AdministratorAccess_.../carlos.ramirez
is not authorized to perform: ec2:RunInstances on resource: arn:aws:ec2:us-east-1:376834080797:instance/*
with an explicit deny in a service control policy: arn:aws:organizations::189053741492:policy/o-r1e3db1vbq/service_control_policy/p-y4hziqde.
Encoded authorization failure message: l26LbhSrTHsbjKaIOy7T... [truncated]
```

`p-y4hziqde` = `scp-restrict-ec2-instance-types`.

## SCP #3 — Require mandatory tags

**Denied** (`t3.micro`, allowed type, but no `Project`/`Environment` tags):

```text
$ aws ec2 run-instances --dry-run --image-id ami-0b301e023c868669e --instance-type t3.micro \
  --subnet-id subnet-0bfbd8493e1e8edf3 \
  --profile scp-test-admin --region us-east-1

An error occurred (UnauthorizedOperation) when calling the RunInstances operation: You are not authorized to
perform this operation. User: arn:aws:sts::376834080797:assumed-role/AWSReservedSSO_AdministratorAccess_.../carlos.ramirez
is not authorized to perform: ec2:RunInstances on resource: arn:aws:ec2:us-east-1:376834080797:instance/*
with an explicit deny in a service control policy: arn:aws:organizations::189053741492:policy/o-r1e3db1vbq/service_control_policy/p-j44vkzls.
Encoded authorization failure message: bgY5NJ5A4Z3LHvG9ddO8... [truncated]
```

`p-j44vkzls` = `scp-require-mandatory-tags`.

## SCP #1 + #3 — Allowed case

Same request, correct type **and** both required tags — satisfies both SCPs at once:

```text
$ aws ec2 run-instances --dry-run --image-id ami-0b301e023c868669e --instance-type t3.micro \
  --subnet-id subnet-0bfbd8493e1e8edf3 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=scp-verification},{Key=Environment,Value=test}]' \
  --profile scp-test-admin --region us-east-1

An error occurred (DryRunOperation) when calling the RunInstances operation: Request would have succeeded,
but DryRun flag is set.
```

## SCP #2 — Deny Transit Gateway creation

**Denied**:

```text
$ aws ec2 create-transit-gateway --dry-run --profile scp-test-admin --region us-east-1

An error occurred (UnauthorizedOperation) when calling the CreateTransitGateway operation: You are not
authorized to perform this operation. User: arn:aws:sts::376834080797:assumed-role/AWSReservedSSO_AdministratorAccess_.../carlos.ramirez
is not authorized to perform: ec2:CreateTransitGateway on resource: arn:aws:ec2:us-east-1:376834080797:transit-gateway/*
with an explicit deny in a service control policy: arn:aws:organizations::189053741492:policy/o-r1e3db1vbq/service_control_policy/p-sqboxile.
Encoded authorization failure message: RJ7OGjS996zh3ZG4m8x1... [truncated]
```

`p-sqboxile` = `scp-deny-transit-gateway`.

**Allowed** (same service, different action — confirms the deny is scoped to TGW creation, not all of EC2):

```text
$ aws ec2 describe-transit-gateways --profile scp-test-admin --region us-east-1
{
    "TransitGateways": []
}
```

## Cleanup

SCP #1 and #3 were attached to `Policy Staging` only for this test — [`policies-attached-on-SCP-test.json`](./policies-attached-on-SCP-test.json) shows all 3 attached during testing, [`policies-attached-on-SCP-test-final.json`](./policies-attached-on-SCP-test-final.json) confirms they were detached afterward, leaving only the permanent `scp-deny-transit-gateway` (plus Control Tower's own guardrails and `FullAWSAccess`). `SCP-test` itself stays active, parked in `Policy Staging`, instead of being closed again — avoids repeating the close → support ticket → reopen cycle next time it's needed.
