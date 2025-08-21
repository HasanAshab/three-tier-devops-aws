output "security_group_id" {
  description = "Security group ID of the Backend ECS Service"
  value = module.ecs.services["backend"].security_group_id
}