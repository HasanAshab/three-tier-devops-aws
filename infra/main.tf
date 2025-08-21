module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project_name}-vpc"
  cidr = local.vnet_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b" /*, "${var.aws_region}c"*/]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24" /*, "10.0.3.0/24"*/]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24" /*, "10.0.103.0/24"*/]

  enable_nat_gateway = true
  single_nat_gateway = true
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
  deletion_protection = var.db_deletion_protection
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.project_name}-alb"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    # all_https = {
    #   from_port   = 443
    #   to_port     = 443
    #   ip_protocol = "tcp"
    #   description = "HTTPS web traffic"
    #   cidr_ipv4   = "0.0.0.0/0"
    # }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  ### Turn on ALB Access Logs ###
  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  listeners = {
    ### Redirect HTTP to HTTPS ###
    # http-https-redirect = {
    #   port     = 80
    #   protocol = "HTTP"
    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # }
    backend = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "backend"
      }
    }
  }

  target_groups = {
    backend = {
      name_prefix       = "be"
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
      create_attachment = false
      # Backend health check endpoint not implemented yet
      # health_check = {
      #   port     = 8080
      #   protocol = "HTTP"
      #   path     = "/health"
      # }
    }
  }

  tags = {
    Environment = "Development"
    Project     = local.project_name
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = local.project_name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  services = {
    backend = {
      cpu    = 1024
      memory = 2048

      container_definitions = {
        backend = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "ghcr.io/hasanashab/three-tier-devops-aws-backend:latest"
          portMappings = [
            {
              name          = "backend-8080-tcp"
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
          environment = [
            {
              name  = "SPRING_DATASOURCE_URL"
              value = "jdbc:mysql://${module.db.db_instance_address}:${module.db.db_instance_port}/${module.db.db_instance_name}?allowPublicKeyRetrieval=true&useSSL=true&createDatabaseIfNotExist=true&useUnicode=true&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=Europe/Paris"
            },
            {
              name  = "SPRING_DATASOURCE_USERNAME"
              value = module.db.db_instance_username
            },
            {
              name  = "SPRING_DATASOURCE_PASSWORD"
              value = var.db_password
            }
          ]
          readonlyRootFilesystem    = true
          enable_cloudwatch_logging = true
          memoryReservation         = 512
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["backend"].arn
          container_name   = "backend"
          container_port   = 8080
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_ingress_rules = {
        alb_ingress = {
          description                  = "Allow ALB to reach Backend"
          from_port                    = 8080
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.alb.security_group_id
        }
      }
      security_group_egress_rules = {
        all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = local.project_name
  }
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
}
