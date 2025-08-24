environment                = "production"
azs_count                  = 3
enable_deletion_protection = true

# Database
db_instance_class        = "db.m4.large"
db_allocated_storage     = 20
db_max_allocated_storage = 100
db_apply_immediately     = false
db_skip_final_snapshot   = false

# Backend
backend_service_cpu    = 2048
backend_service_memory = 4096

# Frontend
frontend_cdn_price_class = "PriceClass_200"