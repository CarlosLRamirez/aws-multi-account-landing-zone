# Hub VPC for the Networking account (ADR-004). Deliberately NOT built from
# modules/vpc-baseline — that module is shaped for workload accounts (public
# subnets, an IGW). This account never runs application workloads; its job
# is to be the peering nexus for every workload VPC today, and the
# attachment point for a Site-to-Site VPN to on-premises later. So this VPC
# has no Internet Gateway and no public subnets — nothing here is meant to
# be internet-facing.
#
# CIDR allocation plan (non-overlapping /20s, required for VPC Peering):
#   Networking (hub) 10.0.0.0/20   Staging 10.2.0.0/20
#   Dev              10.1.0.0/20   Prod    10.3.0.0/20
#                                  Sandbox 10.4.0.0/20

data "aws_availability_zones" "networking" {
  provider = aws.networking
  state    = "available"
}

locals {
  networking_hub_cidr = "10.0.0.0/20"
  networking_hub_azs  = slice(data.aws_availability_zones.networking.names, 0, 2)
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

# One subnet per AZ — no public/private split, since nothing in this VPC is
# meant to be internet-facing. VPC Peering attaches at the VPC level, and a
# future Virtual Private Gateway (for on-prem VPN) does too, so this is
# enough surface to route from without an IGW.
resource "aws_subnet" "networking_hub" {
  provider          = aws.networking
  count             = length(local.networking_hub_azs)
  vpc_id            = aws_vpc.networking_hub.id
  cidr_block        = cidrsubnet(local.networking_hub_cidr, 4, count.index)
  availability_zone = local.networking_hub_azs[count.index]

  tags = {
    Name = "networking-hub-${local.networking_hub_azs[count.index]}"
  }
}

# Local-only for now — this is where peering routes to each workload VPC
# get added as those accounts and their VPCs come online, and where a
# future VGW's propagated on-prem routes would land too.
resource "aws_route_table" "networking_hub" {
  provider = aws.networking
  vpc_id   = aws_vpc.networking_hub.id

  tags = {
    Name = "networking-hub-rt"
  }
}

resource "aws_route_table_association" "networking_hub" {
  provider       = aws.networking
  count          = length(local.networking_hub_azs)
  subnet_id      = aws_subnet.networking_hub[count.index].id
  route_table_id = aws_route_table.networking_hub.id
}
