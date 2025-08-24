output "certificate_arns" {
  description = "Map of service names to their ACM certificate ARN."
  value       = { for service, cert in aws_acm_certificate.this : service => cert.arn }
}

output "domain_validation_records" {
  description = "Map of service names to their DNS validation records for certificate"
  value       = { for service, cert in aws_acm_certificate.this : service => cert.domain_validation_options }
}