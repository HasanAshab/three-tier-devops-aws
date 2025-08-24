variable "hosted_zone_name" {
  description = "The name of the Route 53 Hosted Zone (e.g., example.com)"
  type        = string
}

variable "records" {
  description = "Map of service names to their domains, DNS type, optional provider, and alias configuration."
  type = map(object({
    domains  = list(string)
    type     = string
    provider = optional(any)
    alias    = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
}

variable "create_cert" {
  description = "Whether to create certificate for domains"
  type        = bool
  default     = true
}
