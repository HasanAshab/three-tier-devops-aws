module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${var.name_prefix}-fe-alb"
  vpc_id                     = var.vpc_id
  subnets                    = var.alb_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection

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
  #   bucket = "be-alb-logs"
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
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${var.name_prefix}-cluster"

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
      cpu    = var.service_cpu
      memory = var.service_memory

      container_definitions = {
        backend = {
          cpu       = var.service_cpu
          memory    = var.service_memory
          essential = true
          image     = var.container_image
          portMappings = [
            {
              name          = "backend-${var.container_port}-tcp"
              containerPort = var.container_port
              protocol      = "tcp"
            }
          ]
          environment = [
            {
              name  = "SPRING_DATASOURCE_URL"
              value = "jdbc:mysql://${var.db_host}:3306/${var.db_name}?allowPublicKeyRetrieval=true&useSSL=true&createDatabaseIfNotExist=true&useUnicode=true&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=Europe/Paris"
            },
            {
              name  = "SPRING_DATASOURCE_USERNAME"
              value = var.db_username
            },
            {
              name  = "SPRING_DATASOURCE_PASSWORD"
              value = var.db_password
            }
          ]
          readonlyRootFilesystem    = true
          enable_cloudwatch_logging = true
          memoryReservation         = var.service_memory / 2
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["backend"].arn
          container_name   = "backend"
          container_port   = var.container_port
        }
      }

      subnet_ids = var.subnet_ids
      security_group_ingress_rules = {
        alb_ingress = {
          description                  = "Allow ALB to reach Backend"
          from_port                    = var.container_port
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
}
