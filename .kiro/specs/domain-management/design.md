# Domain Management Design Document

## Overview

The domain management module will provide SSL certificate provisioning and domain configuration for a three-tier application. It will create and manage AWS Certificate Manager (ACM) certificates for custom domains and provide the necessary outputs for integration with existing CloudFront and ALB resources.

The module will be designed as a standalone Terraform module that can be integrated into the existing infrastructure without modifying the core application modules, following the principle of separation of concerns.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Route 53      │    │  Certificate     │    │   CloudFront    │
│   DNS Records   │───▶│  Manager (ACM)   │───▶│   Distribution  │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Application     │
                       │  Load Balancer   │
                       │  (ALB)           │
                       └──────────────────┘
```

### Domain Mapping Strategy

- **Frontend Domains**: `three-tier-app.com` and `www.three-tier-app.com` → CloudFront Distribution
- **Backend Domain**: `api.three-tier-app.com` → Application Load Balancer
- **Certificate Strategy**: 
  - Single multi-domain certificate for frontend domains (SAN certificate)
  - Separate certificate for backend API domain
  - DNS validation for automatic certificate verification

## Components and Interfaces

### 1. Domain Management Module Structure

```
infra/modules/domain/
├── main.tf              # Main certificate and validation resources
├── variables.tf         # Input variables
└── outputs.tf           # Certificate ARNs and validation records
```

### 2. Certificate Resources

#### Frontend Certificate (Multi-Domain)
- **Primary Domain**: `three-tier-app.com`
- **Subject Alternative Names**: `www.three-tier-app.com`
- **Validation Method**: DNS validation
- **Region**: use data "aws_region" "current" {} to get current region (required for CloudFront)

#### Backend Certificate (Single Domain)
- **Domain**: `api.three-tier-app.com`
- **Validation Method**: DNS validation
- **Region**: use data "aws_region" "current" {} to get current region

### 3. Module Interface

#### Input Variables
```hcl
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
```

#### Output Values
```hcl
output "certificate_arns" {
  description = "Map of service names to their ACM certificate ARN."
  value       = { for service, cert in aws_acm_certificate.this : service => cert.arn }
}

output "domain_validation_records" {
  description = "Map of service names to their DNS validation records for certificate"
  value       = { for service, cert in aws_acm_certificate.this : service => cert.domain_validation_options }
}
```

## Data Models

### Route 53 Hosted Zone

```hcl
resource "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

```

### Route 53 DNS Records

```hcl

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


```

### Certificate Configuration Model

```hcl
# ACM Certificates for each service
resource "aws_acm_certificate" "this" {
  for_each = var.records

  # Only set provider if one is defined for the service
  provider = lookup(each.value, "provider", null)

  domain_name = each.value.domains[0]

  # Set SANs only if more than one domain
  subject_alternative_names = slice(each.value.domains, 1, length(each.value.domains))

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation for ACM certificates
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for service, cert in aws_acm_certificate.this :
    service => cert
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.this.zone_id

  dynamic "records" {
    for_each = each.value.domain_validation_options
    content {
      name    = records.value.resource_record_name
      type    = records.value.resource_record_type
      ttl     = 60
      records = [records.value.resource_record_value]
    }
  }
}

```


### Integration Model

The module will be integrated into the main infrastructure by:

1. **Adding the domain module** to `main.tf`
2. **Updating frontend module** to use the certificate ARN
3. **Updating backend module** to use the certificate ARN and enable HTTPS

## Error Handling

### Certificate Validation Failures
- **DNS Validation Timeout**: Module will output validation records but not wait for validation
- **Domain Ownership Issues**: Clear error messages about DNS record requirements

### Integration Error Handling
- **Missing Domain Configuration**: Validation rules for required domain inputs
- **Certificate ARN References**: Conditional resource creation to avoid circular dependencies
- **Provider Region Issues**: Separate provider aliases for different regions if needed

```

## Implementation Notes

### Security Considerations
- Certificates use DNS validation (more secure than email validation)
- Automatic certificate renewal handled by AWS Certificate Manager
- No private keys stored in Terraform state (managed by AWS)

### Dependencies
- Requires existing domain registration in Route 53 or external DNS provider
- No dependencies on other infrastructure modules
