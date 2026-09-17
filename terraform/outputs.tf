# Root-level outputs -- the explicit "contract" exposed to other Terraform
# configs (BrewOps, in the MyWebApp-dev account) via
# `data "terraform_remote_state"` through the `brewops-terraform-state-reader`
# role (see iam-brewops-cross-account.tf). Kept intentionally narrow: only
# what a workload actually needs to place its own resources, not everything
# this repo manages.
#
# `terraform_remote_state` still reads the whole state file under the hood --
# there's no way to scope that further at the IAM/S3 layer, so this list is
# the documented contract for what's meant to be consumed, not a hard access
# boundary enforced by Terraform itself.

output "mywebapp_dev_vpc_id" {
  description = "VPC ID for MyWebApp-dev, where BrewOps deploys."
  value       = module.mywebapp_dev_vpc.vpc_id
}

output "mywebapp_dev_vpc_cidr" {
  description = "CIDR block of the MyWebApp-dev VPC (10.0.64.0/20)."
  value       = module.mywebapp_dev_vpc.vpc_cidr
}

output "mywebapp_dev_public_subnet_ids" {
  description = "Public (Web) subnet IDs -- for an ALB or other internet-facing resource."
  value       = module.mywebapp_dev_vpc.public_subnet_ids
}

output "mywebapp_dev_app_subnet_ids" {
  description = "Private (App) subnet IDs -- for EC2/Auto Scaling Group."
  value       = module.mywebapp_dev_vpc.app_subnet_ids
}

output "mywebapp_dev_data_subnet_ids" {
  description = "Private (Data) subnet IDs -- for RDS or similar."
  value       = module.mywebapp_dev_vpc.data_subnet_ids
}

output "networking_hub_peering_connection_id" {
  description = "VPC Peering connection ID between the Networking hub and MyWebApp-dev."
  value       = aws_vpc_peering_connection.hub_to_mywebapp_dev.id
}
