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

  # Container Registry names are globally unique and alphanumeric-only, so they
  # cannot use the <project>-<env>-<resource> convention. The suffix is the
  # first six hex characters of sha256(lower(subscription id)), the same scheme
  # script/tfstate-bootstrap uses for the state account: deterministic,
  # re-derivable at cutover, and subscription-portable without bookkeeping.
  registry_name = "sudhausengenprodacr${substr(sha256(lower(var.subscription_id)), 0, 6)}"

  # The site reads PORT and defaults to 8000, so the ingress target port is
  # fixed at 8000 and the placeholder image must answer there too.
  app_port = 8000
}

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------

# The signed-in operator, used to grant AcrPush so images can be pushed from a
# workstation. Terraform runs operator-locally, never in CI, so this is the
# human running "make apply".
data "azurerm_client_config" "current" {}

# ------------------------------------------------------------------------------
# RESOURCES
# ------------------------------------------------------------------------------

resource "azurerm_resource_group" "prod" {
  name     = "sudhaus-engen-prod-rg"
  location = var.location

  tags = local.common_tags
}

# Console and system logs from the Container Apps environment land here. HTTP
# access logs do not: ContainerAppHTTPLogs is a separate opt-in that needs a
# diagnostic setting on the environment, and this root deliberately creates
# none, because the site logs no visitor information at all. The 30-day
# retention is the value the Datenschutzerklaerung states, and is also the
# PerGB2018 minimum.
resource "azurerm_log_analytics_workspace" "prod" {
  name                = "sudhaus-engen-prod-law"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Admin credentials stay disabled: both the operator (AcrPush) and the Container
# App (AcrPull) authenticate with Entra identities rather than a shared
# username and password.
resource "azurerm_container_registry" "prod" {
  name                = local.registry_name
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "Basic"
  admin_enabled       = false

  tags = local.common_tags
}

# The Container App pulls from the registry as this identity rather than with
# registry credentials.
resource "azurerm_user_assigned_identity" "prod" {
  name                = "sudhaus-engen-prod-id"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  tags = local.common_tags
}

# principal_type is pinned to ServicePrincipal so the assignment does not fail
# while the freshly created identity is still replicating through Entra.
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.prod.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.prod.principal_id
  principal_type       = "ServicePrincipal"
}

# Lets the operator running "make apply" push images. principal_type is left
# unset so Azure resolves it, because the caller may be either a user or a
# service principal.
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.prod.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_container_app_environment" "prod" {
  name                       = "sudhaus-engen-prod-cae"
  location                   = azurerm_resource_group.prod.location
  resource_group_name        = azurerm_resource_group.prod.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id
  logs_destination           = "log-analytics"

  # Azure assigns this profile itself when none is given, so declaring it keeps
  # the configuration equal to the deployed state and stops every later plan
  # proposing to remove it. Consumption is the serverless profile ADR-0001 chose.
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 0
  }

  tags = local.common_tags
}

# The image is a placeholder only. Promotion swaps it for a real build with
# "az containerapp update --image", so the lifecycle block below ignores image
# drift and keeps Terraform from reverting the running revision on the next
# apply.
#
# mcr.microsoft.com/dotnet/samples:aspnetapp is the placeholder because the
# ingress target port is fixed at 8000 and this image honours a port setting:
# ASPNETCORE_HTTP_PORTS makes Kestrel listen on [::]:8000. The usual Container
# Apps quickstart images are hard-wired to port 80 and cannot be used. The
# variable is inert for the real image, which reads PORT.
resource "azurerm_container_app" "prod" {
  name                         = "sudhaus-engen-prod-app"
  resource_group_name          = azurerm_resource_group.prod.name
  container_app_environment_id = azurerm_container_app_environment.prod.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.prod.id]
  }

  registry {
    server   = azurerm_container_registry.prod.login_server
    identity = azurerm_user_assigned_identity.prod.id
  }

  template {
    # min_replicas = 1 keeps the app out of scale-to-zero so the Azure-managed
    # certificate added in a later change is never issued or renewed against a
    # stopped app. See ADR-0001.
    min_replicas = 1

    container {
      name   = "sudhaus-engen"
      image  = "mcr.microsoft.com/dotnet/samples:aspnetapp"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ASPNETCORE_HTTP_PORTS"
        value = tostring(local.app_port)
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = local.app_port
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # The grant is not in the dependency graph, because the app refers to the
  # identity and to the registry but never to the role assignment between them.
  # Without this the first revision can start before AcrPull has landed.
  depends_on = [azurerm_role_assignment.acr_pull]

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  tags = local.common_tags
}
