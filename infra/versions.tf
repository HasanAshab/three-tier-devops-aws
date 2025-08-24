terraform {
  required_providers {
    # ------ AWS Provider -------
    aws = {
      source  = "hashicorp/aws"
      version = "6.5.0"
    }
  }
  required_version = " >= 1.10.0"
}


# ------ AWS Provider -------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = var.environment
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = var.environment
    }
  }
}

