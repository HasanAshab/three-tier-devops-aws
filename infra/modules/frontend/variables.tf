variable "name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "domain_names" {
  description = "List of domain names"
  type        = list(string)
}

variable "cdn_price_class" {
  description = "Price class for the CloudFront distribution"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for the CloudFront distribution"
  type        = string
  default     = "index.html"
}

variable "cdn_allowed_methods" {
  description = "List of allowed methods for the CloudFront distribution"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cdn_cached_methods" {
  description = "List of cached methods for the CloudFront distribution"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}