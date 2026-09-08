variable "name" {
  description = "Short identifier used to tag/name every resource this module creates (e.g. \"dev\", \"staging\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Expected to be a /20 per the account CIDR allocation plan in ADR-004, but any block that leaves room for az_count * 4 subnet_newbits-sized subnets works."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across. Each AZ gets 4 CIDR slots: Public, Private (App), Private (Data), and one reserved/TBD slot not provisioned as a subnet."
  type        = number
  default     = 3
}

variable "subnet_newbits" {
  description = "Bits added to vpc_cidr for each subnet (cidrsubnet newbits). Default 4 turns a /20 into /24 subnets, giving 4 slots per AZ; with az_count=3 that uses 12 of 16 slots, leaving 4 reserved for future /23 expansion."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Extra tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
