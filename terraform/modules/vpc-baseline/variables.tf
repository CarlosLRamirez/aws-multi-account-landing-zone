variable "name" {
  description = "Short identifier used to tag/name every resource this module creates (e.g. \"networking-hub\", \"dev\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Expected to be a /20 per the account CIDR allocation plan in ADR-004, but any block that leaves room for subnet_newbits works."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across. One public + one private subnet is created per AZ."
  type        = number
  default     = 2
}

variable "subnet_newbits" {
  description = "Bits added to vpc_cidr for each subnet (cidrsubnet newbits). Default 4 turns a /20 into /24 subnets."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Extra tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
