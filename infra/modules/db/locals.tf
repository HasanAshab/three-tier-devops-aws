locals {
  major_engine_version = coalesce(var.major_engine_version,  regex_replace(var.engine_version, "^([0-9]+\\.[0-9]+).*", "$1"))
  family = coalesce(var.family, "${var.engine}${local.major_engine_version}")
}