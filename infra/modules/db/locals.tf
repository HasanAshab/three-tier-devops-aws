locals {
  _parts = split(".", var.engine_version)
  major_engine_version = coalesce(var.major_engine_version, "${local._parts[0]}.${local._parts[1]}")
  family = coalesce(var.family, "${var.engine}${local.major_engine_version}")
  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}