module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project_name}-vpc"
  cidr = local.vnet_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${local.project_name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  # Turn on ALB Access Logs
  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  listeners = {
    # http-https-redirect = {
    #   port     = 80
    #   protocol = "HTTP"
    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # }

    http = {
      port            = 80
      protocol        = "HTTP"
      forward = {
        target_group_key = "frontend"
      }
    }
  }

  target_groups = {
    frontend = {
      name_prefix      = "fe"
      protocol         = "HTTP"
      port             = 4200
      target_type      = "ip"
      create_attachment = false
      health_check = {
        port     = 4200
        protocol = "HTTP"
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = local.project_name
  }
}

resource "aws_service_discovery_private_dns_namespace" "ecs" {
  name = "local"
  vpc  = module.vpc.vpc_id
  description = "Internal ECS Service Connect namespace"
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

  # Cluster capacity providers
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
    frontend = {
      cpu    = 512
      memory = 1024

      container_definitions = {
        frontend = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "ghcr.io/hasanashab/three-tier-devops-aws-frontend:latest"
          portMappings = [
            {
              name          = "frontend-4200-tcp"
              containerPort = 4200
              protocol      = "tcp"
            }
          ]

          # Nginx requires write access to /var/cache/nginx
          readonlyRootFilesystem = false

          enable_cloudwatch_logging = true
          memoryReservation = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["frontend"].arn
          container_name   = "frontend"
          container_port   = 4200
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_ingress_rules = {
        alb_ingress = {
          description                  = "Allow ALB to reach Frontend"
          from_port                    = 4200
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

    backend = {
      cpu    = 512
      memory = 1024

      container_definitions = {
        backend = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "ghcr.io/hasanashab/three-tier-devops-aws-frontend:latest" # todo
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
              value = ""
            },
            {
              name  = "SPRING_DATASOURCE_USERNAME"
              value = ""
            },
            {
              name  = "SPRING_DATASOURCE_PASSWORD"
              value = ""
            }
          ]
          readonlyRootFilesystem = false #todo
          enable_cloudwatch_logging = true
          memoryReservation = 512
        }
      }

      service_connect_configuration = {
        namespace = aws_service_discovery_private_dns_namespace.ecs.name
        service = [{
          client_alias = {
            port     = 8080
            dns_name = "backend"
          }
          port_name      = "backend-8080-tcp"
          discovery_name = "backend"
        }]
      }

      subnet_ids = module.vpc.private_subnets
    }
  }

  tags = {
    Environment = "Development"
    Project     = local.project_name
  }
}