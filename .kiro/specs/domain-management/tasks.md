# Implementation Plan

- [ ] 1. Create domain module structure and core files
  - Create the domain module directory structure at `/infra/modules/domain/`
  - Create `versions.tf` with required Terraform and AWS provider versions
  - Create `variables.tf` with input variable definitions for domain configuration
  - Create `outputs.tf` with certificate ARNs and validation record outputs
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 2. Implement SSL certificate resources
  - [ ] 2.1 Create frontend multi-domain certificate resource
    - Write `aws_acm_certificate` resource for frontend domains in `main.tf`
    - Configure certificate with primary domain and subject alternative names
    - Set DNS validation method and lifecycle rules
    - _Requirements: 1.1, 1.2, 3.1, 3.2, 4.1, 4.2_

  - [ ] 2.2 Create backend single-domain certificate resource
    - Write `aws_acm_certificate` resource for backend API domain in `main.tf`
    - Configure certificate with single domain for API endpoint
    - Set DNS validation method and lifecycle rules
    - _Requirements: 1.1, 1.3, 3.1, 3.2_

- [ ] 3. Implement certificate validation and outputs
  - [ ] 3.1 Add certificate validation resources
    - Create `aws_acm_certificate_validation` resources for both certificates
    - Configure validation timeouts and dependencies
    - Add conditional logic for optional certificate creation
    - _Requirements: 1.4, 3.2, 5.1, 5.3_

  - [ ] 3.2 Implement module outputs
    - Write output blocks for frontend and backend certificate ARNs
    - Create outputs for DNS validation records for Route 53 configuration
    - Add conditional outputs based on certificate creation flags
    - _Requirements: 2.3, 5.1, 5.2, 5.3_

- [ ] 4. Add input validation and error handling
  - Write validation rules for domain name format in `variables.tf`
  - Add validation for required frontend domains when creating frontend certificate
  - Create validation for backend domain when creating backend certificate
  - Add descriptive error messages for validation failures
  - _Requirements: 2.2, 5.4_

- [ ] 5. Create module documentation
  - Write comprehensive `README.md` with usage examples and requirements
  - Document all input variables with descriptions and examples
  - Document all outputs with descriptions and usage instructions
  - Include DNS validation setup instructions
  - _Requirements: 2.2, 5.3_

- [ ] 6. Integrate domain module into main infrastructure
  - [ ] 6.1 Add domain module to main.tf
    - Add domain module block in `/infra/main.tf`
    - Configure module inputs with domain names and creation flags
    - Pass appropriate tags and naming conventions
    - _Requirements: 1.1, 2.2_

  - [ ] 6.2 Update frontend module for HTTPS
    - Modify `/infra/modules/frontend/main.tf` to use custom certificate
    - Update CloudFront viewer certificate configuration
    - Configure certificate ARN from domain module output
    - _Requirements: 1.2, 4.2, 4.3_

  - [ ] 6.3 Update backend module for HTTPS
    - Modify `/infra/modules/backend/main.tf` to add HTTPS listener
    - Add security group rule for HTTPS traffic (port 443)
    - Configure ALB listener with certificate from domain module
    - Add HTTP to HTTPS redirect listener
    - _Requirements: 1.3, 3.3_

- [ ] 7. Add regional provider configuration
  - Create provider alias for us-east-1 region in domain module
  - Configure frontend certificate to use us-east-1 provider
  - Ensure backend certificate uses default region provider
  - _Requirements: 1.1, 3.1_

- [ ] 8. Create integration tests
  - [ ] 8.1 Write Terraform validation tests
    - Create test configuration files for module validation
    - Write tests for valid domain name inputs
    - Write tests for invalid domain name validation
    - Test conditional certificate creation scenarios
    - _Requirements: 2.2, 5.4_

  - [ ] 8.2 Write integration test scenarios
    - Create test for frontend-only certificate creation
    - Create test for backend-only certificate creation
    - Create test for both certificates creation
    - Verify output values are correctly generated
    - _Requirements: 2.1, 2.3, 5.1, 5.2_