# Production-Ready Three-Tier Architecture on AWS with DevOps Best Practices

*A deep dive into Infrastructure as Code, CI/CD automation, and cloud architecture best practices*

---

## Why This Project?
![Project](https://github.com/HasanAshab/three-tier-devops-aws/blob/main/static/images/project.png?raw=true)

Most DevOps tutorials barely scratch the surface — a container here, a pipeline there. But when you step into **real-world production**, you quickly realize there’s more at stake:

* **Security** across tiers
* **Scalability** that doesn’t break the budget
* **Monitoring** that catches issues before customers do
* **Environments** that mimic production without wasting resources

This project was my attempt to go **beyond “Hello World” DevOps** and design a **production-grade three-tier pipeline on AWS**.

---

## The Architecture at a Glance

Instead of reinventing the wheel, I leaned on the proven three-tier model — **frontend, backend, database** — but built it with **cloud-native services and IaC** for resilience and automation.

* **Frontend**: React SPA hosted on **S3 + CloudFront**
* **Backend**: Spring Boot API on **ECS Fargate + ALB**
* **Database**: Managed **RDS MySQL** with multi-AZ support

![Architecture](https://github.com/HasanAshab/three-tier-devops-aws/blob/main/infra/static/images/architecture.png?raw=true)

---

## Frontend: Global Delivery with CloudFront

Static doesn’t mean simple. The frontend setup ensures global speed and security:

* React SPA → **S3** → **CloudFront CDN** → **Route 53**
* HTTPS enforced with ACM certificates
* SPA-friendly error pages and routing
* OAC restricting S3 access to CloudFront only

*Result: Fast, cost-effective and secure delivery to users anywhere in the world.*

---

## Backend: Serverless Containers with ECS Fargate

No servers to babysit. Fargate handles orchestration:

* Load-balanced across multiple AZs
* Zero-downtime rolling deployments
* Spot instances for cost savings
* Security groups with least-privilege rules

*Result: Scalable API that grows or shrinks with traffic.*

---

## Database: Resilient RDS MySQL

AWS RDS took care of the heavy lifting:

* Multi-AZ failover
* Automated backups
* Encryption at rest and in transit
* Isolated private subnet

*Result: Reliable data persistence with minimal ops overhead.*

---

## Infrastructure as Code: Modular Terraform

Instead of a messy monolith, I split the infra into reusable modules:

```
infra/modules/
├── network/
├── frontend/
├── backend/
├── db/
└── domain/
```

This gave me:

* Cleaner code reviews
* Easier debugging
* The ability to swap modules without breaking others

---

## CI/CD Pipelines

Two kinds of pipelines — **infra** and **apps**.

### Infra Pipeline (Terraform)

* `terraform validate` + linting
* tfsec/Checkov for security scanning
* Approval gates before `apply`
* Drift detection alerts

![Infra Pipeline](https://github.com/HasanAshab/three-tier-devops-aws/blob/main/infra/static/images/cicd.png?raw=true)


### Application Pipelines

* **Frontend**: Build React → Test → Deploy → CloudFront invalidate
  ![Frontend Pipeline](https://github.com/HasanAshab/three-tier-devops-aws/blob/main/static/images/cicd/frontend.png?raw=true)

* **Backend**: Build Spring Boot → Dockerize → Push to ECR → Deploy to ECS
  ![Backend Pipeline](https://github.com/HasanAshab/three-tier-devops-aws/blob/main/static/images/cicd/backend.png?raw=true)

Automation handled the boring stuff; approval gates kept prod safe.

---

## Security by Design

I baked in security instead of bolting it on later:

* VPC isolation + subnet separation
* SSL everywhere
* IAM with least privilege
* Secrets stored in GitHub + SSM
* Container + infra scans in every pipeline

---

## Cost Optimization

* **Fargate Spot** for \~50% savings
* **CloudFront caching** reduces origin load
* Lifecycle policies for logs & S3 storage
* Smaller instances in dev/staging

---

## Monitoring and Observability

CloudWatch everywhere:

* Logs for ECS containers
* Alarms for CPU/memory spikes
* RDS performance insights
* Cost alerts to avoid surprises

---

## Multi-Environment Setup

Terraform workspaces + env-specific `tfvars` files gave me:

* Lightweight **dev** (single AZ, smaller instances)
* Staging mirroring prod for testing
* Hardened **production** with HA + stricter security

---

## Lessons Learned

* **Keep infra modular** — it pays off when debugging
* **Automate security checks** early
* **Separate pipelines** → less mess, more control
* **Tag everything** for cost tracking
* **Don’t underestimate monitoring** — it’s your lifeline

---

## What’s Next

* Add **WAF** and advanced security
* Introduce **distributed tracing** with X-Ray
* Explore **ElastiCache** + DB read replicas
* Automate **secrets rotation**

---

## Final Thoughts

This wasn’t just about “getting it to work” — it was about proving you can build **cloud infra that’s production-ready from day one**.

**Key takeaways:**

* Modular IaC makes scaling and reuse painless
* CI/CD with guardrails builds trust in automation
* Security and cost optimization must be designed in, not patched later
* Monitoring turns chaos into control

Check out the [source code](https://github.com/HasanAshab/three-tier-devops-aws) at GitHub for more details.


---

## 📬 Contact

If you’d like to connect, collaborate, or discuss DevOps, feel free to reach out:

* **Website**: [hasan-ashab](https://hasan-ashab.vercel.app/)
* **GitHub**: [github.com/HasanAshab](https://github.com/HasanAshab/)
* **LinkedIn**: [linkedin.com/in/hasan-ashab](https://linkedin.com/in/hasan-ashab/)

