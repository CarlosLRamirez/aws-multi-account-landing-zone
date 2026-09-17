# `terraform apply` output evidence

## Baseline after initial Landing Zone deployment

```bash
❯ terraform apply
aws_organizations_policy.deny_transit_gateway: Refreshing state... [id=p-sqboxile]
aws_organizations_policy.restrict_ec2_types: Refreshing state... [id=p-y4hziqde]
aws_organizations_organizational_unit.workloads: Refreshing state... [id=ou-wfup-2h5futdy]
aws_organizations_organizational_unit.sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4]
aws_organizations_organizational_unit.policy_staging: Refreshing state... [id=ou-wfup-7taopy61]
aws_organizations_organizational_unit.infrastructure: Refreshing state... [id=ou-wfup-858qj8pv]
aws_organizations_policy.require_mandatory_tags: Refreshing state... [id=p-j44vkzls]
data.aws_availability_zones.networking: Reading...
aws_vpc.networking_hub: Refreshing state... [id=vpc-021f251e55eebe1cf]
aws_organizations_policy_attachment.require_mandatory_tags_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-j44vkzls]
aws_organizations_policy_attachment.deny_transit_gateway_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-sqboxile]
aws_organizations_organizational_unit.staging: Refreshing state... [id=ou-wfup-scewi8o5]
aws_organizations_organizational_unit.prod: Refreshing state... [id=ou-wfup-wmf44yl1]
aws_organizations_organizational_unit.dev: Refreshing state... [id=ou-wfup-89sqs9ew]
aws_organizations_policy_attachment.deny_transit_gateway_policy_staging: Refreshing state... [id=ou-wfup-7taopy61:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-y4hziqde]
aws_organizations_policy_attachment.deny_transit_gateway_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-sqboxile]
aws_organizations_policy_attachment.deny_transit_gateway_infrastructure: Refreshing state... [id=ou-wfup-858qj8pv:p-sqboxile]
data.aws_availability_zones.networking: Read complete after 1s [id=us-east-1]
aws_organizations_policy_attachment.restrict_ec2_types_dev: Refreshing state... [id=ou-wfup-89sqs9ew:p-y4hziqde]
aws_organizations_policy_attachment.restrict_ec2_types_staging: Refreshing state... [id=ou-wfup-scewi8o5:p-y4hziqde]
aws_route_table.networking_hub_private: Refreshing state... [id=rtb-03d50dd3a385fe4ff]
aws_subnet.networking_hub_public_future[2]: Refreshing state... [id=subnet-0b0102da4c154c112]
aws_subnet.networking_hub_private[1]: Refreshing state... [id=subnet-04034d3e054f44a52]
aws_subnet.networking_hub_private[0]: Refreshing state... [id=subnet-0394ea3f737bc1c44]
aws_subnet.networking_hub_private[2]: Refreshing state... [id=subnet-0452f982972951a18]
aws_route_table.networking_hub_public_future: Refreshing state... [id=rtb-06a11117a94fc9dee]
aws_subnet.networking_hub_public_future[0]: Refreshing state... [id=subnet-0b9579608dd67fbb2]
aws_subnet.networking_hub_public_future[1]: Refreshing state... [id=subnet-012c279969b4e5301]
aws_route_table_association.networking_hub_public_future[0]: Refreshing state... [id=rtbassoc-0dd191d67b4d0829b]
aws_route_table_association.networking_hub_public_future[1]: Refreshing state... [id=rtbassoc-0b29c18e2a7b9212f]
aws_route_table_association.networking_hub_public_future[2]: Refreshing state... [id=rtbassoc-0a42cf6611709761f]
aws_route_table_association.networking_hub_private[0]: Refreshing state... [id=rtbassoc-0eac6df37852e6b25]
aws_route_table_association.networking_hub_private[1]: Refreshing state... [id=rtbassoc-0d3816660b0128913]
aws_route_table_association.networking_hub_private[2]: Refreshing state... [id=rtbassoc-09f9b78638cf01df3]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
Releasing state lock. This may take a few moments...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

```
## WebApp-Dev Networking baseline deployment

```bash
❯ terraform apply
aws_organizations_organizational_unit.policy_staging: Refreshing state... [id=ou-wfup-7taopy61]
aws_organizations_policy.deny_transit_gateway: Refreshing state... [id=p-sqboxile]
aws_organizations_organizational_unit.infrastructure: Refreshing state... [id=ou-wfup-858qj8pv]
aws_organizations_policy.restrict_ec2_types: Refreshing state... [id=p-y4hziqde]
aws_organizations_organizational_unit.sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4]
aws_organizations_policy.require_mandatory_tags: Refreshing state... [id=p-j44vkzls]
aws_organizations_organizational_unit.workloads: Refreshing state... [id=ou-wfup-2h5futdy]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Reading...
data.aws_availability_zones.networking: Reading...
aws_vpc.networking_hub: Refreshing state... [id=vpc-021f251e55eebe1cf]
aws_organizations_policy_attachment.deny_transit_gateway_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-y4hziqde]
aws_organizations_organizational_unit.prod: Refreshing state... [id=ou-wfup-wmf44yl1]
aws_organizations_organizational_unit.dev: Refreshing state... [id=ou-wfup-89sqs9ew]
aws_organizations_policy_attachment.require_mandatory_tags_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-j44vkzls]
aws_organizations_organizational_unit.staging: Refreshing state... [id=ou-wfup-scewi8o5]
aws_organizations_policy_attachment.deny_transit_gateway_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-sqboxile]
aws_organizations_policy_attachment.deny_transit_gateway_policy_staging: Refreshing state... [id=ou-wfup-7taopy61:p-sqboxile]
aws_organizations_policy_attachment.deny_transit_gateway_infrastructure: Refreshing state... [id=ou-wfup-858qj8pv:p-sqboxile]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Read complete after 4s [id=us-east-1]
data.aws_availability_zones.networking: Read complete after 4s [id=us-east-1]
aws_organizations_policy_attachment.restrict_ec2_types_staging: Refreshing state... [id=ou-wfup-scewi8o5:p-y4hziqde]
aws_organizations_policy_attachment.restrict_ec2_types_dev: Refreshing state... [id=ou-wfup-89sqs9ew:p-y4hziqde]
aws_route_table.networking_hub_public_future: Refreshing state... [id=rtb-06a11117a94fc9dee]
aws_subnet.networking_hub_private[2]: Refreshing state... [id=subnet-0452f982972951a18]
aws_route_table.networking_hub_private: Refreshing state... [id=rtb-03d50dd3a385fe4ff]
aws_subnet.networking_hub_public_future[1]: Refreshing state... [id=subnet-012c279969b4e5301]
aws_subnet.networking_hub_private[0]: Refreshing state... [id=subnet-0394ea3f737bc1c44]
aws_subnet.networking_hub_private[1]: Refreshing state... [id=subnet-04034d3e054f44a52]
aws_subnet.networking_hub_public_future[2]: Refreshing state... [id=subnet-0b0102da4c154c112]
aws_subnet.networking_hub_public_future[0]: Refreshing state... [id=subnet-0b9579608dd67fbb2]
aws_route_table_association.networking_hub_private[1]: Refreshing state... [id=rtbassoc-0d3816660b0128913]
aws_route_table_association.networking_hub_private[0]: Refreshing state... [id=rtbassoc-0eac6df37852e6b25]
aws_route_table_association.networking_hub_private[2]: Refreshing state... [id=rtbassoc-09f9b78638cf01df3]
aws_route_table_association.networking_hub_public_future[2]: Refreshing state... [id=rtbassoc-0a42cf6611709761f]
aws_route_table_association.networking_hub_public_future[1]: Refreshing state... [id=rtbassoc-0b29c18e2a7b9212f]
aws_route_table_association.networking_hub_public_future[0]: Refreshing state... [id=rtbassoc-0dd191d67b4d0829b]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.mywebapp_dev_vpc.aws_internet_gateway.this will be created
  + resource "aws_internet_gateway" "this" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-igw"
          + "Project"     = "MyWebApp"
        }
      + tags_all = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-igw"
          + "Project"     = "MyWebApp"
        }
      + vpc_id   = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table.private will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-private-rt"
          + "Project"     = "MyWebApp"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-private-rt"
          + "Project"     = "MyWebApp"
        }
      + vpc_id           = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + gateway_id                 = (known after apply)
                # (11 unchanged attributes hidden)
            },
        ]
      + tags             = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-rt"
          + "Project"     = "MyWebApp"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-rt"
          + "Project"     = "MyWebApp"
        }
      + vpc_id           = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.app[0] will be created
  + resource "aws_route_table_association" "app" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.app[1] will be created
  + resource "aws_route_table_association" "app" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.app[2] will be created
  + resource "aws_route_table_association" "app" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.data[0] will be created
  + resource "aws_route_table_association" "data" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.data[1] will be created
  + resource "aws_route_table_association" "data" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.data[2] will be created
  + resource "aws_route_table_association" "data" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.public[0] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.public[1] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_route_table_association.public[2] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.app[0] will be created
  + resource "aws_subnet" "app" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.65.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.app[1] will be created
  + resource "aws_subnet" "app" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.69.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.app[2] will be created
  + resource "aws_subnet" "app" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1c"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.73.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-app-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "app"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.data[0] will be created
  + resource "aws_subnet" "data" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.66.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.data[1] will be created
  + resource "aws_subnet" "data" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.70.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.data[2] will be created
  + resource "aws_subnet" "data" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1c"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.74.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-data-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "data"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.public[0] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.64.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1a"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.public[1] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.68.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1b"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_subnet.public[2] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1c"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.72.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev-public-us-east-1c"
          + "Project"     = "MyWebApp"
          + "Tier"        = "public"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.mywebapp_dev_vpc.aws_vpc.this will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.64.0/20"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev"
          + "Project"     = "MyWebApp"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "Name"        = "mywebapp-dev"
          + "Project"     = "MyWebApp"
        }
    }

Plan: 22 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.mywebapp_dev_vpc.aws_vpc.this: Creating...
module.mywebapp_dev_vpc.aws_vpc.this: Still creating... [00m10s elapsed]
module.mywebapp_dev_vpc.aws_vpc.this: Creation complete after 12s [id=vpc-0b217d0676a8cb822]
module.mywebapp_dev_vpc.aws_internet_gateway.this: Creating...
module.mywebapp_dev_vpc.aws_subnet.public[2]: Creating...
module.mywebapp_dev_vpc.aws_subnet.public[0]: Creating...
module.mywebapp_dev_vpc.aws_route_table.private: Creating...
module.mywebapp_dev_vpc.aws_subnet.data[0]: Creating...
module.mywebapp_dev_vpc.aws_subnet.app[2]: Creating...
module.mywebapp_dev_vpc.aws_subnet.app[1]: Creating...
module.mywebapp_dev_vpc.aws_subnet.data[2]: Creating...
module.mywebapp_dev_vpc.aws_subnet.public[1]: Creating...
module.mywebapp_dev_vpc.aws_subnet.data[1]: Creating...
module.mywebapp_dev_vpc.aws_internet_gateway.this: Creation complete after 1s [id=igw-01d370dfae467122e]
module.mywebapp_dev_vpc.aws_subnet.app[0]: Creating...
module.mywebapp_dev_vpc.aws_subnet.data[2]: Creation complete after 1s [id=subnet-060adbc8a98741b07]
module.mywebapp_dev_vpc.aws_route_table.public: Creating...
module.mywebapp_dev_vpc.aws_subnet.app[2]: Creation complete after 1s [id=subnet-007642f0320552794]
module.mywebapp_dev_vpc.aws_route_table.private: Creation complete after 1s [id=rtb-04d913d9e026784e6]
module.mywebapp_dev_vpc.aws_subnet.app[0]: Creation complete after 0s [id=subnet-08f023447e914aab4]
module.mywebapp_dev_vpc.aws_route_table.public: Creation complete after 1s [id=rtb-0af07ff224e27c7f9]
module.mywebapp_dev_vpc.aws_subnet.data[0]: Creation complete after 3s [id=subnet-0731dbdab2cba0e91]
module.mywebapp_dev_vpc.aws_subnet.app[1]: Creation complete after 3s [id=subnet-0821574d4be70465a]
module.mywebapp_dev_vpc.aws_route_table_association.app[1]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.app[0]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.app[2]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.app[1]: Creation complete after 0s [id=rtbassoc-022a319952eb2e86c]
module.mywebapp_dev_vpc.aws_route_table_association.app[0]: Creation complete after 0s [id=rtbassoc-04dc93ef83bc433b2]
module.mywebapp_dev_vpc.aws_subnet.data[1]: Creation complete after 3s [id=subnet-0b57859b627b3534f]
module.mywebapp_dev_vpc.aws_route_table_association.data[2]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.data[1]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.data[0]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.app[2]: Creation complete after 0s [id=rtbassoc-067bcffcaae650938]
module.mywebapp_dev_vpc.aws_route_table_association.data[0]: Creation complete after 1s [id=rtbassoc-023df77632c971c29]
module.mywebapp_dev_vpc.aws_route_table_association.data[2]: Creation complete after 1s [id=rtbassoc-0554318989a10b6c9]
module.mywebapp_dev_vpc.aws_route_table_association.data[1]: Creation complete after 1s [id=rtbassoc-0b85eb0d4dd07d7f4]
module.mywebapp_dev_vpc.aws_subnet.public[2]: Still creating... [00m10s elapsed]
module.mywebapp_dev_vpc.aws_subnet.public[0]: Still creating... [00m10s elapsed]
module.mywebapp_dev_vpc.aws_subnet.public[1]: Still creating... [00m10s elapsed]
module.mywebapp_dev_vpc.aws_subnet.public[2]: Creation complete after 11s [id=subnet-061a24e4c1011e1cc]
module.mywebapp_dev_vpc.aws_subnet.public[0]: Creation complete after 14s [id=subnet-0f4a71cd35dedf910]
module.mywebapp_dev_vpc.aws_subnet.public[1]: Creation complete after 14s [id=subnet-062e5c2c0566ba12e]
module.mywebapp_dev_vpc.aws_route_table_association.public[1]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.public[2]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.public[0]: Creating...
module.mywebapp_dev_vpc.aws_route_table_association.public[2]: Creation complete after 1s [id=rtbassoc-03e41887ac7622980]
module.mywebapp_dev_vpc.aws_route_table_association.public[1]: Creation complete after 1s [id=rtbassoc-0cbe155792b97da0c]
module.mywebapp_dev_vpc.aws_route_table_association.public[0]: Creation complete after 1s [id=rtbassoc-0b20eed35f9288ac0]

Apply complete! Resources: 22 added, 0 changed, 0 destroyed.
```

## VPC Peering — hub `Networking` ↔ `MyWebApp-dev` deployment

```bash
❯ terraform apply
aws_organizations_organizational_unit.policy_staging: Refreshing state... [id=ou-wfup-7taopy61]
aws_organizations_organizational_unit.sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4]
aws_organizations_policy.require_mandatory_tags: Refreshing state... [id=p-j44vkzls]
aws_organizations_policy.restrict_ec2_types: Refreshing state... [id=p-y4hziqde]
aws_organizations_policy.deny_transit_gateway: Refreshing state... [id=p-sqboxile]
aws_organizations_organizational_unit.infrastructure: Refreshing state... [id=ou-wfup-858qj8pv]
aws_organizations_organizational_unit.workloads: Refreshing state... [id=ou-wfup-2h5futdy]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Reading...
module.mywebapp_dev_vpc.aws_vpc.this: Refreshing state... [id=vpc-0b217d0676a8cb822]
data.aws_availability_zones.networking: Reading...
aws_vpc.networking_hub: Refreshing state... [id=vpc-021f251e55eebe1cf]
aws_organizations_organizational_unit.staging: Refreshing state... [id=ou-wfup-scewi8o5]
aws_organizations_policy_attachment.deny_transit_gateway_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-sqboxile]
aws_organizations_policy_attachment.require_mandatory_tags_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-j44vkzls]
aws_organizations_organizational_unit.dev: Refreshing state... [id=ou-wfup-89sqs9ew]
aws_organizations_policy_attachment.restrict_ec2_types_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-y4hziqde]
aws_organizations_policy_attachment.deny_transit_gateway_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-sqboxile]
aws_organizations_policy_attachment.deny_transit_gateway_policy_staging: Refreshing state... [id=ou-wfup-7taopy61:p-sqboxile]
aws_organizations_organizational_unit.prod: Refreshing state... [id=ou-wfup-wmf44yl1]
aws_organizations_policy_attachment.deny_transit_gateway_infrastructure: Refreshing state... [id=ou-wfup-858qj8pv:p-sqboxile]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Read complete after 0s [id=us-east-1]
data.aws_availability_zones.networking: Read complete after 0s [id=us-east-1]
aws_organizations_policy_attachment.restrict_ec2_types_staging: Refreshing state... [id=ou-wfup-scewi8o5:p-y4hziqde]
aws_organizations_policy_attachment.restrict_ec2_types_dev: Refreshing state... [id=ou-wfup-89sqs9ew:p-y4hziqde]
module.mywebapp_dev_vpc.aws_internet_gateway.this: Refreshing state... [id=igw-01d370dfae467122e]
module.mywebapp_dev_vpc.aws_subnet.public[2]: Refreshing state... [id=subnet-061a24e4c1011e1cc]
module.mywebapp_dev_vpc.aws_subnet.data[1]: Refreshing state... [id=subnet-0b57859b627b3534f]
module.mywebapp_dev_vpc.aws_subnet.data[0]: Refreshing state... [id=subnet-0731dbdab2cba0e91]
module.mywebapp_dev_vpc.aws_subnet.public[1]: Refreshing state... [id=subnet-062e5c2c0566ba12e]
module.mywebapp_dev_vpc.aws_subnet.data[2]: Refreshing state... [id=subnet-060adbc8a98741b07]
module.mywebapp_dev_vpc.aws_route_table.private: Refreshing state... [id=rtb-04d913d9e026784e6]
module.mywebapp_dev_vpc.aws_subnet.public[0]: Refreshing state... [id=subnet-0f4a71cd35dedf910]
module.mywebapp_dev_vpc.aws_subnet.app[0]: Refreshing state... [id=subnet-08f023447e914aab4]
module.mywebapp_dev_vpc.aws_subnet.app[1]: Refreshing state... [id=subnet-0821574d4be70465a]
module.mywebapp_dev_vpc.aws_subnet.app[2]: Refreshing state... [id=subnet-007642f0320552794]
aws_route_table.networking_hub_private: Refreshing state... [id=rtb-03d50dd3a385fe4ff]
aws_route_table.networking_hub_public_future: Refreshing state... [id=rtb-06a11117a94fc9dee]
aws_subnet.networking_hub_private[2]: Refreshing state... [id=subnet-0452f982972951a18]
aws_subnet.networking_hub_private[1]: Refreshing state... [id=subnet-04034d3e054f44a52]
aws_subnet.networking_hub_public_future[0]: Refreshing state... [id=subnet-0b9579608dd67fbb2]
aws_subnet.networking_hub_private[0]: Refreshing state... [id=subnet-0394ea3f737bc1c44]
aws_subnet.networking_hub_public_future[1]: Refreshing state... [id=subnet-012c279969b4e5301]
aws_subnet.networking_hub_public_future[2]: Refreshing state... [id=subnet-0b0102da4c154c112]
module.mywebapp_dev_vpc.aws_route_table.public: Refreshing state... [id=rtb-0af07ff224e27c7f9]
module.mywebapp_dev_vpc.aws_route_table_association.data[1]: Refreshing state... [id=rtbassoc-0b85eb0d4dd07d7f4]
module.mywebapp_dev_vpc.aws_route_table_association.data[2]: Refreshing state... [id=rtbassoc-0554318989a10b6c9]
module.mywebapp_dev_vpc.aws_route_table_association.data[0]: Refreshing state... [id=rtbassoc-023df77632c971c29]
module.mywebapp_dev_vpc.aws_route_table_association.app[1]: Refreshing state... [id=rtbassoc-022a319952eb2e86c]
module.mywebapp_dev_vpc.aws_route_table_association.app[2]: Refreshing state... [id=rtbassoc-067bcffcaae650938]
module.mywebapp_dev_vpc.aws_route_table_association.app[0]: Refreshing state... [id=rtbassoc-04dc93ef83bc433b2]
module.mywebapp_dev_vpc.aws_route_table_association.public[1]: Refreshing state... [id=rtbassoc-0cbe155792b97da0c]
module.mywebapp_dev_vpc.aws_route_table_association.public[2]: Refreshing state... [id=rtbassoc-03e41887ac7622980]
module.mywebapp_dev_vpc.aws_route_table_association.public[0]: Refreshing state... [id=rtbassoc-0b20eed35f9288ac0]
aws_route_table_association.networking_hub_private[2]: Refreshing state... [id=rtbassoc-09f9b78638cf01df3]
aws_route_table_association.networking_hub_private[1]: Refreshing state... [id=rtbassoc-0d3816660b0128913]
aws_route_table_association.networking_hub_private[0]: Refreshing state... [id=rtbassoc-0eac6df37852e6b25]
aws_route_table_association.networking_hub_public_future[2]: Refreshing state... [id=rtbassoc-0a42cf6611709761f]
aws_route_table_association.networking_hub_public_future[0]: Refreshing state... [id=rtbassoc-0dd191d67b4d0829b]
aws_route_table_association.networking_hub_public_future[1]: Refreshing state... [id=rtbassoc-0b29c18e2a7b9212f]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_route.hub_private_to_mywebapp_dev will be created
  + resource "aws_route" "hub_private_to_mywebapp_dev" {
      + destination_cidr_block    = "10.0.64.0/20"
      + id                        = (known after apply)
      + instance_id               = (known after apply)
      + instance_owner_id         = (known after apply)
      + network_interface_id      = (known after apply)
      + origin                    = (known after apply)
      + route_table_id            = "rtb-03d50dd3a385fe4ff"
      + state                     = (known after apply)
      + vpc_peering_connection_id = (known after apply)
    }

  # aws_route.mywebapp_dev_private_to_hub will be created
  + resource "aws_route" "mywebapp_dev_private_to_hub" {
      + destination_cidr_block    = "10.0.0.0/21"
      + id                        = (known after apply)
      + instance_id               = (known after apply)
      + instance_owner_id         = (known after apply)
      + network_interface_id      = (known after apply)
      + origin                    = (known after apply)
      + route_table_id            = "rtb-04d913d9e026784e6"
      + state                     = (known after apply)
      + vpc_peering_connection_id = (known after apply)
    }

  # aws_route.mywebapp_dev_public_to_hub will be created
  + resource "aws_route" "mywebapp_dev_public_to_hub" {
      + destination_cidr_block    = "10.0.0.0/21"
      + id                        = (known after apply)
      + instance_id               = (known after apply)
      + instance_owner_id         = (known after apply)
      + network_interface_id      = (known after apply)
      + origin                    = (known after apply)
      + route_table_id            = "rtb-0af07ff224e27c7f9"
      + state                     = (known after apply)
      + vpc_peering_connection_id = (known after apply)
    }

  # aws_vpc_peering_connection.hub_to_mywebapp_dev will be created
  + resource "aws_vpc_peering_connection" "hub_to_mywebapp_dev" {
      + accept_status = (known after apply)
      + auto_accept   = false
      + id            = (known after apply)
      + peer_owner_id = "172644092356"
      + peer_region   = (known after apply)
      + peer_vpc_id   = "vpc-0b217d0676a8cb822"
      + tags          = {
          + "Name" = "pcx-networking-hub-mywebapp-dev"
          + "Side" = "requester"
        }
      + tags_all      = {
          + "Name" = "pcx-networking-hub-mywebapp-dev"
          + "Side" = "requester"
        }
      + vpc_id        = "vpc-021f251e55eebe1cf"

      + accepter (known after apply)

      + requester (known after apply)
    }

  # aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub will be created
  + resource "aws_vpc_peering_connection_accepter" "mywebapp_dev_accepts_hub" {
      + accept_status             = (known after apply)
      + auto_accept               = true
      + id                        = (known after apply)
      + peer_owner_id             = (known after apply)
      + peer_region               = (known after apply)
      + peer_vpc_id               = (known after apply)
      + tags                      = {
          + "Name" = "pcx-networking-hub-mywebapp-dev"
          + "Side" = "accepter"
        }
      + tags_all                  = {
          + "Name" = "pcx-networking-hub-mywebapp-dev"
          + "Side" = "accepter"
        }
      + vpc_id                    = (known after apply)
      + vpc_peering_connection_id = (known after apply)

      + accepter (known after apply)

      + requester (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc_peering_connection.hub_to_mywebapp_dev: Creating...
aws_vpc_peering_connection.hub_to_mywebapp_dev: Creation complete after 2s [id=pcx-00a6c63aeeb9f75b7]
aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub: Creating...
aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub: Creation complete after 1s [id=pcx-00a6c63aeeb9f75b7]
aws_route.hub_private_to_mywebapp_dev: Creating...
aws_route.mywebapp_dev_private_to_hub: Creating...
aws_route.mywebapp_dev_public_to_hub: Creating...
aws_route.hub_private_to_mywebapp_dev: Creation complete after 1s [id=r-rtb-03d50dd3a385fe4ff1834003930]
aws_route.mywebapp_dev_private_to_hub: Creation complete after 1s [id=r-rtb-04d913d9e026784e63220427898]
aws_route.mywebapp_dev_public_to_hub: Creation complete after 1s [id=r-rtb-0af07ff224e27c7f93220427898]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

### After cross-account role creation for WebApp-Dev (BrewOps)

```bash
❯ terraform apply
data.aws_iam_policy_document.brewops_state_reader_trust: Reading...
data.aws_iam_policy_document.brewops_state_reader_permissions: Reading...
aws_organizations_organizational_unit.infrastructure: Refreshing state... [id=ou-wfup-858qj8pv]
aws_organizations_policy.require_mandatory_tags: Refreshing state... [id=p-j44vkzls]
aws_organizations_policy.deny_transit_gateway: Refreshing state... [id=p-sqboxile]
aws_organizations_organizational_unit.sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4]
aws_organizations_policy.restrict_ec2_types: Refreshing state... [id=p-y4hziqde]
aws_organizations_organizational_unit.policy_staging: Refreshing state... [id=ou-wfup-7taopy61]
data.aws_iam_policy_document.brewops_state_reader_permissions: Read complete after 0s [id=2736050622]
data.aws_iam_policy_document.brewops_state_reader_trust: Read complete after 0s [id=1935475798]
aws_organizations_organizational_unit.workloads: Refreshing state... [id=ou-wfup-2h5futdy]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Reading...
module.mywebapp_dev_vpc.aws_vpc.this: Refreshing state... [id=vpc-0b217d0676a8cb822]
data.aws_availability_zones.networking: Reading...
aws_vpc.networking_hub: Refreshing state... [id=vpc-021f251e55eebe1cf]
aws_organizations_organizational_unit.prod: Refreshing state... [id=ou-wfup-wmf44yl1]
aws_organizations_policy_attachment.deny_transit_gateway_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-sqboxile]
aws_organizations_policy_attachment.require_mandatory_tags_workloads: Refreshing state... [id=ou-wfup-2h5futdy:p-j44vkzls]
aws_organizations_organizational_unit.dev: Refreshing state... [id=ou-wfup-89sqs9ew]
aws_organizations_organizational_unit.staging: Refreshing state... [id=ou-wfup-scewi8o5]
aws_organizations_policy_attachment.deny_transit_gateway_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_sandbox: Refreshing state... [id=ou-wfup-8r0fmvb4:p-y4hziqde]
aws_organizations_policy_attachment.deny_transit_gateway_policy_staging: Refreshing state... [id=ou-wfup-7taopy61:p-sqboxile]
data.aws_availability_zones.networking: Read complete after 0s [id=us-east-1]
module.mywebapp_dev_vpc.data.aws_availability_zones.available: Read complete after 0s [id=us-east-1]
aws_organizations_policy_attachment.deny_transit_gateway_infrastructure: Refreshing state... [id=ou-wfup-858qj8pv:p-sqboxile]
aws_organizations_policy_attachment.restrict_ec2_types_dev: Refreshing state... [id=ou-wfup-89sqs9ew:p-y4hziqde]
aws_route_table.networking_hub_private: Refreshing state... [id=rtb-03d50dd3a385fe4ff]
module.mywebapp_dev_vpc.aws_internet_gateway.this: Refreshing state... [id=igw-01d370dfae467122e]
module.mywebapp_dev_vpc.aws_route_table.public: Refreshing state... [id=rtb-0af07ff224e27c7f9]
module.mywebapp_dev_vpc.aws_route_table.private: Refreshing state... [id=rtb-04d913d9e026784e6]
module.mywebapp_dev_vpc.aws_subnet.data[1]: Refreshing state... [id=subnet-0b57859b627b3534f]
module.mywebapp_dev_vpc.aws_subnet.public[1]: Refreshing state... [id=subnet-062e5c2c0566ba12e]
module.mywebapp_dev_vpc.aws_subnet.public[0]: Refreshing state... [id=subnet-0f4a71cd35dedf910]
module.mywebapp_dev_vpc.aws_subnet.data[2]: Refreshing state... [id=subnet-060adbc8a98741b07]
module.mywebapp_dev_vpc.aws_subnet.data[0]: Refreshing state... [id=subnet-0731dbdab2cba0e91]
module.mywebapp_dev_vpc.aws_subnet.public[2]: Refreshing state... [id=subnet-061a24e4c1011e1cc]
aws_subnet.networking_hub_public_future[0]: Refreshing state... [id=subnet-0b9579608dd67fbb2]
aws_subnet.networking_hub_public_future[1]: Refreshing state... [id=subnet-012c279969b4e5301]
aws_subnet.networking_hub_public_future[2]: Refreshing state... [id=subnet-0b0102da4c154c112]
module.mywebapp_dev_vpc.aws_subnet.app[0]: Refreshing state... [id=subnet-08f023447e914aab4]
module.mywebapp_dev_vpc.aws_subnet.app[1]: Refreshing state... [id=subnet-0821574d4be70465a]
module.mywebapp_dev_vpc.aws_subnet.app[2]: Refreshing state... [id=subnet-007642f0320552794]
aws_subnet.networking_hub_private[0]: Refreshing state... [id=subnet-0394ea3f737bc1c44]
aws_subnet.networking_hub_private[2]: Refreshing state... [id=subnet-0452f982972951a18]
aws_subnet.networking_hub_private[1]: Refreshing state... [id=subnet-04034d3e054f44a52]
aws_route_table.networking_hub_public_future: Refreshing state... [id=rtb-06a11117a94fc9dee]
aws_vpc_peering_connection.hub_to_mywebapp_dev: Refreshing state... [id=pcx-00a6c63aeeb9f75b7]
module.mywebapp_dev_vpc.aws_route.public_internet_gateway: Refreshing state... [id=r-rtb-0af07ff224e27c7f91080289494]
module.mywebapp_dev_vpc.aws_route_table_association.data[0]: Refreshing state... [id=rtbassoc-023df77632c971c29]
module.mywebapp_dev_vpc.aws_route_table_association.data[1]: Refreshing state... [id=rtbassoc-0b85eb0d4dd07d7f4]
module.mywebapp_dev_vpc.aws_route_table_association.data[2]: Refreshing state... [id=rtbassoc-0554318989a10b6c9]
module.mywebapp_dev_vpc.aws_route_table_association.public[0]: Refreshing state... [id=rtbassoc-0b20eed35f9288ac0]
module.mywebapp_dev_vpc.aws_route_table_association.public[2]: Refreshing state... [id=rtbassoc-03e41887ac7622980]
module.mywebapp_dev_vpc.aws_route_table_association.public[1]: Refreshing state... [id=rtbassoc-0cbe155792b97da0c]
module.mywebapp_dev_vpc.aws_route_table_association.app[0]: Refreshing state... [id=rtbassoc-04dc93ef83bc433b2]
module.mywebapp_dev_vpc.aws_route_table_association.app[1]: Refreshing state... [id=rtbassoc-022a319952eb2e86c]
module.mywebapp_dev_vpc.aws_route_table_association.app[2]: Refreshing state... [id=rtbassoc-067bcffcaae650938]
aws_route_table_association.networking_hub_private[1]: Refreshing state... [id=rtbassoc-0d3816660b0128913]
aws_route_table_association.networking_hub_private[2]: Refreshing state... [id=rtbassoc-09f9b78638cf01df3]
aws_route_table_association.networking_hub_private[0]: Refreshing state... [id=rtbassoc-0eac6df37852e6b25]
aws_route_table_association.networking_hub_public_future[0]: Refreshing state... [id=rtbassoc-0dd191d67b4d0829b]
aws_route_table_association.networking_hub_public_future[1]: Refreshing state... [id=rtbassoc-0b29c18e2a7b9212f]
aws_route_table_association.networking_hub_public_future[2]: Refreshing state... [id=rtbassoc-0a42cf6611709761f]
aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub: Refreshing state... [id=pcx-00a6c63aeeb9f75b7]
aws_route.mywebapp_dev_public_to_hub: Refreshing state... [id=r-rtb-0af07ff224e27c7f93220427898]
aws_route.hub_private_to_mywebapp_dev: Refreshing state... [id=r-rtb-03d50dd3a385fe4ff1834003930]
aws_route.mywebapp_dev_private_to_hub: Refreshing state... [id=r-rtb-04d913d9e026784e63220427898]
aws_organizations_policy_attachment.restrict_ec2_types_staging: Refreshing state... [id=ou-wfup-scewi8o5:p-y4hziqde]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_role.brewops_state_reader will be created
  + resource "aws_iam_role" "brewops_state_reader" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::172644092356:root"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Read-only access to the landing zone Terraform state, for the BrewOps workload account"
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "brewops-terraform-state-reader"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # aws_iam_role_policy.brewops_state_reader will be created
  + resource "aws_iam_role_policy" "brewops_state_reader" {
      + id          = (known after apply)
      + name        = "read-landing-zone-state"
      + name_prefix = (known after apply)
      + policy      = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = "s3:GetObject"
                      + Effect   = "Allow"
                      + Resource = "arn:aws:s3:::mylz2027-terraform-state-189053741492/landing-zone/terraform.tfstate"
                      + Sid      = "ReadLandingZoneStateObject"
                    },
                  + {
                      + Action    = "s3:ListBucket"
                      + Condition = {
                          + StringLike = {
                              + "s3:prefix" = "landing-zone/terraform.tfstate"
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:s3:::mylz2027-terraform-state-189053741492"
                      + Sid       = "ListOnlyThatPrefix"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + role        = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + mywebapp_dev_app_subnet_ids          = [
      + "subnet-08f023447e914aab4",
      + "subnet-0821574d4be70465a",
      + "subnet-007642f0320552794",
    ]
  + mywebapp_dev_data_subnet_ids         = [
      + "subnet-0731dbdab2cba0e91",
      + "subnet-0b57859b627b3534f",
      + "subnet-060adbc8a98741b07",
    ]
  + mywebapp_dev_public_subnet_ids       = [
      + "subnet-0f4a71cd35dedf910",
      + "subnet-062e5c2c0566ba12e",
      + "subnet-061a24e4c1011e1cc",
    ]
  + mywebapp_dev_vpc_cidr                = "10.0.64.0/20"
  + mywebapp_dev_vpc_id                  = "vpc-0b217d0676a8cb822"
  + networking_hub_peering_connection_id = "pcx-00a6c63aeeb9f75b7"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_role.brewops_state_reader: Creating...
aws_iam_role.brewops_state_reader: Creation complete after 4s [id=brewops-terraform-state-reader]
aws_iam_role_policy.brewops_state_reader: Creating...
aws_iam_role_policy.brewops_state_reader: Creation complete after 0s [id=brewops-terraform-state-reader:read-landing-zone-stat
e]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

mywebapp_dev_app_subnet_ids = [
  "subnet-08f023447e914aab4",
  "subnet-0821574d4be70465a",
  "subnet-007642f0320552794",
]
mywebapp_dev_data_subnet_ids = [
  "subnet-0731dbdab2cba0e91",
  "subnet-0b57859b627b3534f",
  "subnet-060adbc8a98741b07",
]
mywebapp_dev_public_subnet_ids = [
  "subnet-0f4a71cd35dedf910",
  "subnet-062e5c2c0566ba12e",
  "subnet-061a24e4c1011e1cc",
]
mywebapp_dev_vpc_cidr = "10.0.64.0/20"
mywebapp_dev_vpc_id = "vpc-0b217d0676a8cb822"
networking_hub_peering_connection_id = "pcx-00a6c63aeeb9f75b7"
```

