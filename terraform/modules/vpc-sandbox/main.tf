# Smaller VPC footprint for Sandbox accounts (ADR-004): one VPC, one public
# and two private /26 subnets per AZ. Sized down from vpc-baseline (workload
# accounts get /20s; Sandbox gets a /23) since sandbox workloads don't need
# production-grade capacity. Kept as a separate module rather than a smaller
# instance of vpc-baseline: the tier shape differs (two unnamed private
# tiers here vs. named App/Data there) and so does the AZ count (2 vs 3) --
# forcing one module to cover both would need conditional logic that isn't
# worth it at this scale.
#
# Per-AZ CIDR layout (default /23 -> 8x /26 slots):
#   offset 0: Public
#   offset 1: Private
#   offset 2: Private
# After both AZs (6 of 8 slots used), the remaining 2 /26s are reserved --
# not provisioned as subnets.
#
# Deliberately no NAT Gateway, same reasoning as vpc-baseline.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs          = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  slots_per_az = 3
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

resource "aws_subnet" "private_a" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index * local.slots_per_az + 1)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-1-${local.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_subnet" "private_b" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index * local.slots_per_az + 2)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-2-${local.azs[count.index]}"
    Tier = "private"
  })
}

# Slot offset beyond az_count * slots_per_az (2 slots at az_count=2) is
# reserved address space -- deliberately not provisioned as an aws_subnet.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "private_a" {
  count          = var.az_count
  subnet_id      = aws_subnet.private_a[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  count          = var.az_count
  subnet_id      = aws_subnet.private_b[count.index].id
  route_table_id = aws_route_table.private.id
}
