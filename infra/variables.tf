variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = false
}


# Database

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  # sensitive = true
}

variable "db_apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = true
}


# Backend 

variable "backend_service_cpu" {
  description = "Backend service CPU"
  type        = number
  default     = 1024
}

variable "backend_service_memory" {
  description = "Backend service memory"
  type        = number
  default     = 2048
}
