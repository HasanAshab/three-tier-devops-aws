module "network" {
  source = "./modules/network"

  name_prefix = local.project_name
  cidr = local.network_cidr
  azs_count = var.azs_count
}

module "db" {
  source = "./modules/db"

  name_prefix = local.project_name
  vpc_id = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  source_security_group_id = module.ecs.services["backend"].security_group_id
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
  vpc_id = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  alb_subnet_ids = module.vpc.public_subnets
  service_cpu = var.backend_service_cpu
  service_memory = var.backend_service_memory

  db_host = module.db.db_instance_address
  db_name = module.db.db_instance_name
  db_username = var.db_username
  db_password = var.db_password

  enable_deletion_protection = var.enable_deletion_protection
}

module "static_site_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.5.0"

  bucket = "${local.project_name}-fe-static-site"

  # Enable static website hosting
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # Public access block settings (must allow public for website hosting)
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_policy = true
  policy        = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${local.project_name}-fe-static-site/*"
      }
    ]
  })

  tags = {
    Role = "frontend"
  }
}
