variable "hosted_zone_name" {
  description = "The name of the Route 53 Hosted Zone (e.g., example.com)"
  type        = string
}

variable "records" {
  description = "Map of service names to their domains, DNS type, optional provider, and alias configuration."
  type = map(object({
    domains                = list(string)
    type                   = string
    use_us_east_1_provider = optional(bool, false)
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
}
