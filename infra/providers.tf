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
  region = "us-west-2"
}

# ------ Azure Provider -------
# provider "azurerm" {
#   features {}
# }
