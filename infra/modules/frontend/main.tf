module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.5.0"

  bucket = "${var.name_prefix}-fe-s3"
  
  attach_policy = true
  policy = templatefile("${path.module}/templates/s3_bucket_policy.json", {
    bucket_id = module.s3_bucket.s3_bucket_id
    cf_arn  = module.cdn.cloudfront_distribution_arn
  })

  force_destroy = !var.enable_deletion_protection
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = var.domain_names

  comment             = "CloudFront for ${module.s3_bucket.s3_bucket_id} bucket"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cdn_price_class
  retain_on_delete    = var.enable_deletion_protection
  default_root_object = var.default_root_object

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
    
    allowed_methods          = var.cdn_allowed_methods
    cached_methods           = var.cdn_cached_methods

    use_forwarded_values     = false

    cache_policy_name          = "Managed-CachingOptimized"
    origin_request_policy_name = "Managed-CORS-S3Origin"
  }

  ordered_cache_behavior = [
    {
      target_origin_id       = "s3" # see `origin`
      path_pattern           = "/static/*"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = var.cdn_allowed_methods
      cached_methods  = var.cdn_cached_methods

      use_forwarded_values = false

      cache_policy_name            = "Managed-CachingOptimized"
      origin_request_policy_name   = "Managed-CORS-S3Origin"
      response_headers_policy_name = "Managed-SimpleCORS"
    },
  ]

  viewer_certificate = {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
