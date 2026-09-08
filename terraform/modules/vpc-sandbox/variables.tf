variable "name" {
  description = "Short identifier used to tag/name every resource this module creates (e.g. \"sandbox\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Expected to be a /23 per the Sandbox pool in ADR-004."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across. Each AZ gets 3 CIDR slots: Public, Private, Private."
  type        = number
  default     = 2
}

variable "subnet_newbits" {
  description = "Bits added to vpc_cidr for each subnet (cidrsubnet newbits). Default 3 turns a /23 into /26 subnets, giving 3 slots per AZ; with az_count=2 that uses 6 of 8 slots, leaving 2 reserved."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Extra tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
