terraform {
  required_providers {
    # ------ AWS Provider -------
    aws = {
      source  = "hashicorp/aws"
      version = "6.5.0"
    }
    # ------ Azure Provider -------
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "4.33.0"
    # }
  }
  required_version = " >= 1.10.0"
}


# ------ AWS Provider -------
provider "aws" {
  region = var.aws_region
  # default_tags {
  #   tags = {
  #     Project     = local.project_name
  #     Environment = "dev"
  #   }
  # }
}

# ------ Azure Provider -------
# provider "azurerm" {
#   features {}
# }
