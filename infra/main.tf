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
module "static_site_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.5.0"

  bucket = "${local.project_name}-fe-static-site" #todo

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

  attach_policy = false # We'll attach OAI policy instead

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

###########################
# 2️⃣ CloudFront OAI
###########################
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${local.project_name} S3 bucket"
}

###########################
# 3️⃣ S3 Bucket Policy for OAI
###########################
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.static_site_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${module.static_site_bucket.s3_bucket_id}/*"
      }
    ]
  })
}

###########################
# 4️⃣ CloudFront Distribution
###########################
resource "aws_cloudfront_distribution" "static_site" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  origin {
    domain_name = module.static_site_bucket.s3_bucket_bucket_regional_domain_name
    origin_id   = "S3-${module.static_site_bucket.s3_bucket_id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = "S3-${module.static_site_bucket.s3_bucket_id}"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

###########################
# 5️⃣ Optional Output
###########################
output "cloudfront_url" {
  value = aws_cloudfront_distribution.static_site.domain_name
  description = "Use this URL to access your static site"
}
