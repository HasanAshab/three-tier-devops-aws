module "aws_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${var.name_prefix}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.port
      to_port                  = var.port
      protocol                 = "tcp"
      source_security_group_id = var.source_security_group_id
      description              = "Allow Source Security Group"
    },
  ]
}

module "aws_rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.name_prefix}-db"

  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = 5

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = tostring(var.port)
  manage_master_user_password = false

  vpc_security_group_ids = [module.aws_sg.security_group_id]

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  ### Enable Enhanced Monitoring ###
  # monitoring_interval    = "60"
  # monitoring_role_name   = "RDSMonitoringRole"
  # create_monitoring_role = true

  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids
  family                 = local.family
  major_engine_version   = local.major_engine_version
  apply_immediately      = var.apply_immediately
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.enable_deletion_protection
  parameters = local.parameters
  options = local.options
}