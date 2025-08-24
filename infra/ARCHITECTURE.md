# Three-Tier AWS Architecture Documentation

## Architecture Overview

Three-tier web application architecture on AWS.

**Architecture Pattern**: Presentation → Application → Data Tier
- **Frontend**: React app via CloudFront CDN + S3
- **Backend**: Spring Boot on ECS Fargate + ALB  
- **Database**: MySQL RDS with autoscaling storage

## Network Infrastructure

**VPC Configuration**:
- CIDR: 10.0.0.0/16
- Availability Zones: 3
- Public Subnets: ALB, NAT Gateway
- Private Subnets: ECS services, RDS database
- Single NAT Gateway (cost optimization)

**DNS & SSL**:
- Route 53: three-tier-app.com hosted zone
- ACM Certificates: Frontend (us-east-1), Backend (regional)
- Domains: 
  - Frontend: three-tier-app.com, www.three-tier-app.com
  - Backend: api.three-tier-app.com

## Frontend Tier

**S3 Bucket**:
- Content: React application build assets
- Access: CloudFront Origin Access Control only

**CloudFront CDN**:
- Global distribution with custom domains
- HTTPS redirect, TLS 1.2+
- Caching: Optimized for web content + static assets

## Backend Tier

**Application Load Balancer**:
- Internet-facing in public subnets
- HTTP→HTTPS redirect (port 80→443)
- SSL termination with ACM certificate
- Target: ECS Fargate services

**ECS Fargate Cluster**:
- Cluster: three-tier-cluster
- Capacity: 50% Fargate + 50% Fargate Spot

## Data Tier

**RDS MySQL Database**:
- Storage Autoscaling:
  - Dev: 5 GB (no autoscaling)
  - Prod: 20 GB → 100 GB autoscaling
- Location: Private subnets across multiple AZs


## Security Architecture

**Network Security**:
- VPC isolation with public/private subnet separation
- Security Groups: Principle of least privilege
  - Frontend: No direct access (CloudFront only)
  - Backend: ALB → ECS services only
  - Database: Backend services → RDS only

**Data Security**:
- HTTPS/TLS encryption in transit
- RDS encryption at rest
- SSL database connections

## Traffic Flow

**User Request Flow**:
1. User → CloudFront CDN (global edge locations)
2. CloudFront → S3 (static React assets)
3. API calls → Route 53 → ALB (api.three-tier-app.com)
4. ALB → ECS Fargate services (Spring Boot)
5. ECS → RDS MySQL (private subnets)

**Data Flow**:
- Frontend: Static assets served from S3 via CloudFront
- Backend: API requests load balanced across ECS tasks
- Database: MySQL connections from ECS services only


## Key AWS Services

**Compute & Networking**:
- VPC, Subnets, NAT Gateway, Internet Gateway
- Application Load Balancer (ALB)
- ECS Fargate cluster and services
- Route 53 DNS

**Storage & Content Delivery**:
- S3 bucket for static assets
- CloudFront CDN for global distribution
- RDS MySQL with autoscaling storage

**Security & Certificates**:
- ACM SSL certificates
- Security Groups for network access control
- Origin Access Control for S3-CloudFront integration

**Monitoring & Management**:
- CloudWatch logs for ECS containers
- RDS automated backups