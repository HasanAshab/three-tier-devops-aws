module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name            = "${var.name_prefix}-vpc"
  cidr            = var.cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 4)]

  enable_nat_gateway = true
  single_nat_gateway = true
}