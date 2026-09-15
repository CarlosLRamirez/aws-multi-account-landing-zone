
# Primera VPC Peering connection bajo la topología hub-and-spoke de ADR-004:
# Networking hub <-> MyWebApp-dev.

resource "aws_vpc_peering_connection" "hub_to_mywebapp_dev" {
  provider      = aws.networking
  vpc_id        = aws_vpc.networking_hub.id
  peer_vpc_id   = module.mywebapp_dev_vpc.vpc_id
  peer_owner_id = var.mywebapp_dev_account_id
  auto_accept   = false

  tags = {
    Name = "pcx-networking-hub-mywebapp-dev"
    Side = "requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "mywebapp_dev_accepts_hub" {
  provider                  = aws.mywebapp_dev
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_mywebapp_dev.id
  auto_accept               = true

  tags = {
    Name = "pcx-networking-hub-mywebapp-dev"
    Side = "accepter"
  }
}

# Ruta del lado del hub: sus subnets privadas -> la VPC de MyWebApp-dev.
resource "aws_route" "hub_private_to_mywebapp_dev" {
  provider                  = aws.networking
  route_table_id            = aws_route_table.networking_hub_private.id
  destination_cidr_block    = module.mywebapp_dev_vpc.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_mywebapp_dev.id

  depends_on = [aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub]
}

# Rutas del lado de MyWebApp-dev -> el hub, desde sus dos route tables
# (App y Data comparten una sola "private" dentro de vpc-baseline).
resource "aws_route" "mywebapp_dev_public_to_hub" {
  provider                  = aws.mywebapp_dev
  route_table_id            = module.mywebapp_dev_vpc.public_route_table_id
  destination_cidr_block    = "10.0.0.0/21"
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_mywebapp_dev.id

  depends_on = [aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub]
}

resource "aws_route" "mywebapp_dev_private_to_hub" {
  provider       = aws.mywebapp_dev
  route_table_id = module.mywebapp_dev_vpc.private_route_table_id

  destination_cidr_block    = "10.0.0.0/21"
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_mywebapp_dev.id

  depends_on = [aws_vpc_peering_connection_accepter.mywebapp_dev_accepts_hub]
}
