variable "name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create the database in"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to create the database in"
  type        = list(string)
}

variable "source_security_group_id" {
  description = "ID of the security group to allow access from"
  type        = string
}

variable "engine" {
  description = "Database engine"
  type        = string
  default = "mysql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default = "8.0.43"
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Database username"
  type        = string
}

variable "password" {
  description = "Database password"
  type        = string
  # sensitive = true
}

variable "port" {
  description = "Database port"
  type        = number
  default = 3306
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default = "Mon:00:00-Mon:03:00"  
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default = "03:00-06:00"  
}

variable "major_engine_version" {
  description = "Major engine version"
  type        = string
  default = null
}

variable "family" {
  description = "Family"
  type        = string
  default = null
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
}

variable "enable_deletion_protection" {
  description = "Deletion protection"
  type        = bool
}
