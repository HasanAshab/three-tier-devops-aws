output "url" {
  value = "https://" + var.frontend_domains[0]
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster for backend deployment"
  value       = module.backend.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service for backend deployment"
  value       = module.backend.ecs_service_name
}
