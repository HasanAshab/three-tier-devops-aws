module "network" {
  source = "./modules/network"

  name_prefix = local.project_name
  cidr        = local.network_cidr
  azs_count   = var.azs_count
}

module "domain" {
  source = "./modules/domain"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  hosted_zone_name = var.hosted_zone_name
  records = {
    frontend = {
      domains                = var.frontend_domains
      type                   = "A"
      use_us_east_1_provider = true # Required for CloudFront
      alias = {
        name                   = module.frontend.cdn_domain_name
        zone_id                = module.frontend.cdn_hosted_zone_id
        evaluate_target_health = false
      }
    },
    backend = {
      domains = var.backend_domains
      type    = "A"
      alias = {
        name                   = module.backend.alb_dns_name
        zone_id                = module.backend.alb_zone_id
        evaluate_target_health = true
      }
    }
  }
}

module "db" {
  source = "./modules/db"

  name_prefix              = local.project_name
  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.private_subnets
  source_security_group_id = module.backend.security_group_id
  instance_class           = var.db_instance_class
  db_name                  = var.db_name
  username                 = var.db_username
  password                 = var.db_password

  apply_immediately          = var.db_apply_immediately
  skip_final_snapshot        = var.db_skip_final_snapshot
  enable_deletion_protection = var.enable_deletion_protection
}

module "backend" {
  source = "./modules/backend"

  name_prefix    = local.project_name
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.private_subnets
  alb_subnet_ids = module.network.public_subnets
  service_cpu    = var.backend_service_cpu
  service_memory = var.backend_service_memory

  db_host     = module.db.db_instance_address
  db_name     = module.db.db_instance_name
  db_username = module.db.db_instance_username
  db_password = var.db_password

  certificate_arn            = module.domain.certificate_arns["backend"]
  enable_deletion_protection = var.enable_deletion_protection
}

module "frontend" {
  source = "./modules/frontend"

  name_prefix     = local.project_name
  domain_names    = var.frontend_domains
  cdn_price_class = var.frontend_cdn_price_class

  certificate_arn            = module.domain.certificate_arns["frontend"]
  enable_deletion_protection = var.enable_deletion_protection
}
