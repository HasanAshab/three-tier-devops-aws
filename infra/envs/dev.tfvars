environment                = "development"
azs_count                  = 2
enable_deletion_protection = false

# Database
db_instance_class      = "db.t3.micro"
db_apply_immediately   = true
db_skip_final_snapshot = true

# Backend
backend_service_cpu    = 1024
backend_service_memory = 2048

# Frontend
frontend_cdn_price_class = "PriceClass_100"