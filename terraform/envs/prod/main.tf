# ------------------------------------------------------------------------------
# LOCALS
# ------------------------------------------------------------------------------

# The tag pair every taggable resource in this root must carry, per
# .github/instructions/terraform.instructions.md. Declared once here and merged
# into each resource so the contract lives in a single place.
locals {
  common_tags = {
    service     = "sudhaus-engen"
    environment = "production"
  }
}

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# RESOURCES
# ------------------------------------------------------------------------------

# No workload resources yet. This root is bootstrapped with its backend,
# provider, region pin, and tag locals in place. The Container Apps environment,
# container registry, Log Analytics workspace, DNS zone, and custom-domain
# resources described in ADR-0001 are added in a later change.
