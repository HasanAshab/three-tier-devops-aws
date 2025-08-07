# ------------------------------------------------------------------------------
# NOTE:
# This test is intended solely for CI/CD pipeline demonstration purposes.
# Comprehensive and production-ready tests will be authored at a later stage.
# ------------------------------------------------------------------------------


run "demo_plan" {
  command = plan

  assert {
    condition     = local.project_name == "three-tier-app"
    error_message = "Invalid project name"
  }
}
