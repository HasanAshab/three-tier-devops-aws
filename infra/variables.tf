variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  # sensitive = true
}
