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

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "frontend" {
  name               = "frontend-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_target_group" "frontend" {
  name = "frontend-tg"
  port     = 4200
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"
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
          readonlyRootFilesystem = true
          enable_cloudwatch_logging = true
          memoryReservation = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.frontend.arn
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
          referenced_security_group_id = aws_security_group.alb.id
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
      cpu    = 1024
      memory = 1024

      container_definitions = {
        backend = {
          cpu       = 1024
          memory    = 1024
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
          readonlyRootFilesystem = true
          enable_cloudwatch_logging = true
          memoryReservation = 512
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_ingress_rules = {
        frontend_ingress = {
          description                  = "Allow Frontend to reach Backend"
          from_port                    = 8080
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.ecs.services["frontend"].security_group_id
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