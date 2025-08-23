/*
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

*/


module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.5.0"

  bucket = "${local.project_name}-static-site"
  
  attach_policy = true
  policy = jsonencode({
    Version = "2008-10-17",
    Id = "PolicyForCloudFrontPrivateContent",
    Statement = [
        {
            Sid = "AllowCloudFrontServicePrincipal",
            Effect = "Allow",
            Principal = {
                Service = "cloudfront.amazonaws.com"
            },
            Action = "s3:GetObject",
            Resource = "arn:aws:s3:::${module.s3_bucket.s3_bucket_id}/*",
            Condition = {
                StringEquals = {
                  "AWS:SourceArn" = module.cdn.cloudfront_distribution_arn
                }
            }
        }
    ]
  })

  force_destroy = true
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
  default_root_object = "index.html"

  ### Enable Logging ###
  # logging_config = {
  #   bucket = "logs-my-cdn.s3.amazonaws.com"
  # }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control = "s3_oac" # see `origin_access_control`
    }
  }

  default_cache_behavior = {
    target_origin_id         = "s3" # see`origin`
    viewer_protocol_policy   = "redirect-to-https"
    
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    
    use_forwarded_values     = false

    cache_policy_name          = "Managed-CachingOptimized"
    origin_request_policy_name = "Managed-CORS-S3Origin"
  }

  ordered_cache_behavior = [
    {
      target_origin_id       = "s3" # see `origin`
      path_pattern           = "/static/*"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]

      use_forwarded_values = false

      cache_policy_name            = "Managed-CachingOptimized"
      origin_request_policy_name   = "Managed-CORS-S3Origin"
      response_headers_policy_name = "Managed-SimpleCORS"
    },
  ]

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_domain" {
  value = module.cdn.cloudfront_distribution_domain_name
}