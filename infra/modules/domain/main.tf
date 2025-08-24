resource "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.domains[0]
  type    = each.value.type

  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}

resource "aws_acm_certificate" "this" {
  for_each = {
    for k, v in var.records : k => v if !v.use_us_east_1_provider
  }

  domain_name = each.value.domains[0]

  subject_alternative_names = slice(each.value.domains, 1, length(each.value.domains))

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "this_us_east_1" {
  for_each = {
    for k, v in var.records : k => v if v.use_us_east_1_provider
  }

  provider = aws.us_east_1

  domain_name = each.value.domains[0]

  subject_alternative_names = slice(each.value.domains, 1, length(each.value.domains))

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in flatten([
      for cert_key, cert in aws_acm_certificate.this : [
        for dvo in cert.domain_validation_options : {
          key     = "${cert_key}-${dvo.domain_name}"
          zone_id = aws_route53_zone.this.zone_id
          name    = dvo.resource_record_name
          type    = dvo.resource_record_type
          record  = dvo.resource_record_value
        }
      ]
    ]) : dvo.key => dvo
  }

  allow_overwrite = true
  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  for_each = aws_acm_certificate.this

  certificate_arn         = each.value.arn
  validation_record_fqdns = [
    for dvo in each.value.domain_validation_options : 
    aws_route53_record.acm_validation["${each.key}-${dvo.domain_name}"].fqdn
  ]

  timeouts {
    create = "5m"
  }
}

resource "aws_acm_certificate_validation" "this_us_east_1" {
  for_each = aws_acm_certificate.this_us_east_1

  provider = aws.us_east_1

  certificate_arn         = each.value.arn
  validation_record_fqdns = [
    for dvo in each.value.domain_validation_options : 
    aws_route53_record.acm_validation["${each.key}-${dvo.domain_name}"].fqdn
  ]

  timeouts {
    create = "5m"
  }
}
