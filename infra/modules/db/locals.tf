locals {
  _parts               = split(".", var.engine_version)
  major_engine_version = coalesce(var.major_engine_version, "${local._parts[0]}.${local._parts[1]}")
  family               = coalesce(var.family, "${var.engine}${local.major_engine_version}")
}