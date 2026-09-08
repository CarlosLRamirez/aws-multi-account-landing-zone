# Hub VPC for the Networking account (ADR-004). Deliberately NOT built from
# modules/vpc-baseline or modules/vpc-sandbox -- neither shape (3-tier /20,
# 2-AZ /23) matches what this account is for. This account never runs
# application workloads; its job is to be the peering nexus for every
# workload VPC today, and the attachment point for a Site-to-Site VPN to
# on-premises later.
#
# CIDR allocation plan (hierarchical, ADR-004 revision 2026-09-07):
#   Networking hub  10.0.0.0/21    Dev pool     10.0.64.0/20 (+7 reserved /20s)
#   Shared Services 10.0.8.0/21    Staging pool 10.0.192.0/20 (+7 reserved)
#   (4x /21 reserved for cross-cutting/security tooling)
#   Sandbox pool    10.0.48.0/23   Prod pool    10.1.64.0/20 (+7 reserved)
#   (+7 reserved /23s)
#
# Per-AZ layout within the hub's /21 (3 AZs, /24 subnets, 2 slots per AZ):
#   offset 0: Private            offset 1: Public (Future)
# 2 of 8 /24 slots at the end are reserved, not provisioned.
#
# "Public (Future)" subnets exist now to reserve address space and AZ
# placement for centralized egress (NAT Instance/Gateway) per ADR-004's
# "Networking Considerations" section -- they carry no Internet Gateway and
# no route to one yet. Nothing in this VPC is internet-facing today.

data "aws_availability_zones" "networking" {
  provider = aws.networking
  state    = "available"
}

locals {
  networking_hub_cidr         = "10.0.0.0/21"
  networking_hub_azs          = slice(data.aws_availability_zones.networking.names, 0, 3)
  networking_hub_subnet_bits  = 3
  networking_hub_slots_per_az = 2
}

resource "aws_vpc" "networking_hub" {
  provider             = aws.networking
  cidr_block           = local.networking_hub_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "networking-hub"
    Account = "Networking"
  }
}

# Private tier: slot offset 0 within each AZ's 2-slot group. Peering
# attachment points and, later, the landing spot for a VGW's propagated
# on-prem routes.
resource "aws_subnet" "networking_hub_private" {
  provider          = aws.networking
  count             = length(local.networking_hub_azs)
  vpc_id            = aws_vpc.networking_hub.id
  cidr_block        = cidrsubnet(local.networking_hub_cidr, local.networking_hub_subnet_bits, count.index * local.networking_hub_slots_per_az)
  availability_zone = local.networking_hub_azs[count.index]

  tags = {
    Name = "networking-hub-private-${local.networking_hub_azs[count.index]}"
    Tier = "private"
  }
}

# Public (Future) tier: slot offset 1 within each AZ's 2-slot group.
# Reserved for a future centralized-egress Internet Gateway -- not attached
# to one yet, so this is address space, not a live public subnet.
resource "aws_subnet" "networking_hub_public_future" {
  provider          = aws.networking
  count             = length(local.networking_hub_azs)
  vpc_id            = aws_vpc.networking_hub.id
  cidr_block        = cidrsubnet(local.networking_hub_cidr, local.networking_hub_subnet_bits, count.index * local.networking_hub_slots_per_az + 1)
  availability_zone = local.networking_hub_azs[count.index]

  tags = {
    Name = "networking-hub-public-future-${local.networking_hub_azs[count.index]}"
    Tier = "public-future"
  }
}

# Remaining 2 of 8 /24 slots (offsets 6, 7) are reserved address space --
# deliberately not provisioned as subnets.

# Local-only for now -- this is where peering routes to each workload VPC
# get added as those accounts and their VPCs come online, and where a
# future VGW's propagated on-prem routes would land too.
resource "aws_route_table" "networking_hub_private" {
  provider = aws.networking
  vpc_id   = aws_vpc.networking_hub.id

  tags = {
    Name = "networking-hub-private-rt"
  }
}

resource "aws_route_table_association" "networking_hub_private" {
  provider       = aws.networking
  count          = length(local.networking_hub_azs)
  subnet_id      = aws_subnet.networking_hub_private[count.index].id
  route_table_id = aws_route_table.networking_hub_private.id
}

# Separate route table for Public (Future) so adding an IGW route later is
# a one-line change here, not a new association.
resource "aws_route_table" "networking_hub_public_future" {
  provider = aws.networking
  vpc_id   = aws_vpc.networking_hub.id

  tags = {
    Name = "networking-hub-public-future-rt"
  }
}

resource "aws_route_table_association" "networking_hub_public_future" {
  provider       = aws.networking
  count          = length(local.networking_hub_azs)
  subnet_id      = aws_subnet.networking_hub_public_future[count.index].id
  route_table_id = aws_route_table.networking_hub_public_future.id
}
