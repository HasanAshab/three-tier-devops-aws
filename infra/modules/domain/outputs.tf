output "certificate_arns" {
  description = "Map of service names to their validated ACM certificate ARN."
  value = merge(
    { for service, validation in aws_acm_certificate_validation.this : service => validation.certificate_arn },
    { for service, validation in aws_acm_certificate_validation.this_us_east_1 : service => validation.certificate_arn }
  )
}

output "domain_validation_records" {
  description = "Map of service names to their DNS validation records for certificate"
  value = merge(
    { for service, cert in aws_acm_certificate.this : service => cert.domain_validation_options },
    { for service, cert in aws_acm_certificate.this_us_east_1 : service => cert.domain_validation_options }
  )
}

output "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}