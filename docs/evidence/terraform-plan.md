```bash
❯ terraform plan
aws_organizations_policy.deny_transit_gateway: Refreshing state... [id=p-sqboxile]
aws_organizations_organizational_unit.policy_staging: Refreshing state... [id=ou-wfup-7taopy61]
aws_organizations_organizational_unit.infrastructure: Refreshing state... [id=ou-wfup-858qj8pv]
aws_organizations_organizational_unit.workloads: Refreshing state... [id=ou-wfup-2h5futdy]
aws_organizations_organizational_unit.sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4]
aws_organizations_policy.restrict_ec2_types: Refreshing state... [id=p-y4hziqde]
aws_organizations_policy.require_mandatory_tags: Refreshing state... [id=p-j44vkzls]
data.aws_availability_zones.networking: Reading...
aws_vpc.networking_hub: Refreshing state... [id=vpc-021f251e55eebe1cf]
aws_organizations_organizational_unit.dev: Refreshing state... [id=ou-wfup-89sqs9ew]
aws_organizations_policy_attachment.deny_transit_gateway_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-sqboxile]
aws_organizations_organizational_unit.staging: Refreshing state... [id=ou-wfup-scewi8o5]
aws_organizations_policy_attachment.require_mandatory_tags_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-j44vkzls]
aws_organizations_organizational_unit.prod: Refreshing state... [id=ou-wfup-wmf44yl1]
aws_organizations_policy_attachment.deny_transit_gateway_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-y4hziqde]
aws_organizations_policy_attachment.deny_transit_gateway_infrastructure: Refreshing state... [id=ou-wfup-858qj8pv:p-sqboxile]
data.aws_availability_zones.networking: Read complete after 1s [id=us-east-1]
aws_organizations_policy_attachment.deny_transit_gateway_policy_staging: Refreshing state... [id=ou-wfup-7taopy61:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_dev: Refreshing state... [id=ou-wfup-89sqs9ew:p-y4hziqde]
aws_organizations_policy_attachment.restrict_ec2_types_staging: Refreshing state... [id=ou-wfup-scewi8o5:p-y4hziqde]
aws_subnet.networking_hub_public_future[0]: Refreshing state... [id=subnet-0b9579608dd67fbb2]
aws_subnet.networking_hub_private[0]: Refreshing state... [id=subnet-0394ea3f737bc1c44]
aws_subnet.networking_hub_public_future[1]: Refreshing state... [id=subnet-012c279969b4e5301]
aws_route_table.networking_hub_private: Refreshing state... [id=rtb-03d50dd3a385fe4ff]
aws_subnet.networking_hub_private[2]: Refreshing state... [id=subnet-0452f982972951a18]
aws_route_table.networking_hub_public_future: Refreshing state... [id=rtb-06a11117a94fc9dee]
aws_subnet.networking_hub_private[1]: Refreshing state... [id=subnet-04034d3e054f44a52]
aws_subnet.networking_hub_public_future[2]: Refreshing state... [id=subnet-0b0102da4c154c112]
aws_route_table_association.networking_hub_private[1]: Refreshing state... [id=rtbassoc-0d3816660b0128913]
aws_route_table_association.networking_hub_private[0]: Refreshing state... [id=rtbassoc-0eac6df37852e6b25]
aws_route_table_association.networking_hub_private[2]: Refreshing state... [id=rtbassoc-09f9b78638cf01df3]
aws_route_table_association.networking_hub_public_future[1]: Refreshing state... [id=rtbassoc-0b29c18e2a7b9212f]
aws_route_table_association.networking_hub_public_future[0]: Refreshing state... [id=rtbassoc-0dd191d67b4d0829b]
aws_route_table_association.networking_hub_public_future[2]: Refreshing state... [id=rtbassoc-0a42cf6611709761f]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
Releasing state lock. This may take a few moments...

```
