variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "azs_count" {
  description = "Number of availability zones"
  type        = number
  default = 2
}

variable "hosted_zone_name" {
  description = "The name of the Route 53 Hosted Zone (e.g., example.com)"
  type        = string
  default     = "three-tier-app.com"
}

variable "enable_deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = false
}


# Database

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default = "mydb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default = "hasanashab"
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

variable "backend_domains" {
  description = "Backend domains"
  type        = list(string)
  default = ["api.three-tier-app.com"]
}

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


# Frontend

variable "frontend_domains" {
  description = "Frontend domains"
  type        = list(string)
  default = ["three-tier-app.com", "www.three-tier-app.com"]
}

variable "frontend_cdn_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
