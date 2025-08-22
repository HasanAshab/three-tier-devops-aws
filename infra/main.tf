module "network" {
  source = "./modules/network"

  name_prefix = local.project_name
  cidr = local.network_cidr
  azs_count = var.azs_count
}

module "db" {
  source = "./modules/db"

  name_prefix = local.project_name
  vpc_id = module.network.vpc_id
  subnet_ids  = module.network.private_subnets
  source_security_group_id = module.backend.security_group_id
  instance_class = var.db_instance_class
  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  apply_immediately = var.db_apply_immediately
  skip_final_snapshot = var.db_skip_final_snapshot
  enable_deletion_protection = var.enable_deletion_protection
}

module "backend" {
  source = "./modules/backend"

  name_prefix = local.project_name
  vpc_id = module.network.vpc_id
  subnet_ids  = module.network.private_subnets
  alb_subnet_ids = module.network.public_subnets
  service_cpu = var.backend_service_cpu
  service_memory = var.backend_service_memory

  db_host = module.db.db_instance_address
  db_name = module.db.db_instance_name
  db_username = module.db.db_instance_username
  db_password = var.db_password

  enable_deletion_protection = var.enable_deletion_protection
}


###########################
# 1️⃣ S3 Bucket
###########################
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.5.0"

  bucket = "${local.project_name}-static-site" #todo

  # Website hosting
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  ### Domain Name ###
  # aliases = ["three-tier-app.com"]

  comment             = "CloudFront for ${local.project_name} static site"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false


  ### Enable Logging ###
  # logging_config = {
  #   bucket = "logs-my-cdn.s3.amazonaws.com"
  # }

  origin = {
    s3 = {
      domain_name = module.s3_bucket.s3_bucket_bucket_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_oai"
      }
    }
  }

  create_origin_access_identity = true
  origin_access_identities = {
    s3_oai = "Allow CloudFront to access S3"
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values = {
      query_string = false
      cookies      = { forward = "none" }
    }
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_domain" {
  value = module.cdn.cloudfront_distribution_domain_name
}