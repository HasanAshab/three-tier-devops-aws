variable "hosted_zone_name" {
  description = "The name of the Route 53 Hosted Zone (e.g., example.com)"
  type        = string
}

variable "certificate_domains" {
  description = "Map of service names to their certificate domain configuration."
  type = map(object({
    domains                = list(string)
    use_us_east_1_provider = optional(bool, false)
  }))
}
