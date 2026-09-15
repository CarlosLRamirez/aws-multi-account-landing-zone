# MyWebApp-dev — primera cuenta Workload, primer slot del pool Dev
# (docs/ip-address-plan.md). Usa vpc-baseline tal cual: esta cuenta es
# exactamente la forma para la que el módulo fue diseñado.

module "mywebapp_dev_vpc" {
  source = "./modules/vpc-baseline"

  providers = {
    aws = aws.mywebapp_dev
  }

  name     = "mywebapp-dev"
  vpc_cidr = "10.0.64.0/20"

  tags = {
    Project     = "MyWebApp"
    Environment = "dev"
  }
}

