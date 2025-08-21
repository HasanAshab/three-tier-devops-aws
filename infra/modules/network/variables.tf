variable "name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs_count" {
  description = "Number of availability zones to setup"
  type        = number
}