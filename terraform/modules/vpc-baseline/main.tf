# Standard per-account VPC baseline (ADR-004): one VPC, 3-tier subnet layout
# (Public/App/Data) replicated across `az_count` AZs, one Internet Gateway,
# and a route table per tier group.
#
# Per-AZ CIDR layout (default /20 -> 4x /24 slots per AZ):
#   offset 0: Public (Web)
#   offset 1: Private (App)
#   offset 2: Private (Data)
#   offset 3: Reserved / TBD -- NOT provisioned as a subnet, just reserved
#             address space until a use is decided
# After all AZs (12 of 16 slots used at az_count=3), the remaining slots are
# reserved for future /23 expansion -- also not provisioned.
#
# Deliberately no NAT Gateway. The private route table carries only the
# implicit local route -- no outbound path to the internet yet. See
# ADR-004's "Networking Considerations" section for the NAT Instance vs
# NAT Gateway decision to make when outbound access is actually needed.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs          = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  slots_per_az = 4
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public (Web) tier: slot offset 0 within each AZ's 4-slot group.
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index * local.slots_per_az)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

# Private (App) tier: slot offset 1 within each AZ's 4-slot group.
resource "aws_subnet" "app" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index * local.slots_per_az + 1)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-app-${local.azs[count.index]}"
    Tier = "app"
  })
}

# Private (Data) tier: slot offset 2 within each AZ's 4-slot group.
resource "aws_subnet" "data" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index * local.slots_per_az + 2)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-data-${local.azs[count.index]}"
    Tier = "data"
  })
}

# Slot offset 3 within each AZ's group, and every slot beyond
# az_count * slots_per_az, is reserved address space (TBD use / future /23
# expansion) -- deliberately not provisioned as an aws_subnet.


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Shared by App and Data: both have identical routing today (local route
# only, no NAT). Split into separate route tables later if their outbound
# paths ever need to diverge.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "app" {
  count          = var.az_count
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data" {
  count          = var.az_count
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private.id
}
