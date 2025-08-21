# terraform {
# ------ AWS Provider -------
# backend "s3" {
#   bucket = "terraform-hasan"
#   key    = "three-tier-app.terraform.tfstate"
#   region = "us-west-2"
# }

# ------ Azure Provider -------
# backend "azurerm" {
#   resource_group_name  = "terraform"
#   storage_account_name = "tfstatehasan"
#   container_name       = "tfstate"
#   key                  = "three-tier-app.terraform.tfstate"
# }
# }
