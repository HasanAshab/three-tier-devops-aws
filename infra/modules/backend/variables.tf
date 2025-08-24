variable "name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to create the Backend ECS Service in"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs to create the Backend ALB in"
  type        = list(string)
}

variable "db_host" {
  description = "Database FQDN"
  type        = string
}

variable "db_name" {
  description = "Database Name"
  type        = string
}

variable "db_username" {
  description = "Database Username"
  type        = string
}

variable "db_password" {
  description = "Database Password"
  type        = string
  # sensitive   = true
}

variable "container_image" {
  description = "Container image"
  type        = string
  default = "ghcr.io/hasanashab/three-tier-devops-aws-backend:latest"
}

variable "container_port" {
  description = "Container port to expose"
  type        = number
  default = 8080
}

variable "service_cpu" {
  description = "Service CPU"
  type        = number
}

variable "service_memory" {
  description = "Service memory"
  type        = number
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}
