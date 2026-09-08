output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = concat(aws_subnet.private_a[*].id, aws_subnet.private_b[*].id)
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}
