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
    # certificate is never issued or renewed against a stopped app. See
    # ADR-0001.
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

# Public DNS for sudhaus-engen.de. The zone takes no location argument: ARM
# reports the type as "dnszones" with locations ["global"], so a public DNS
# zone is a global resource and azurerm exposes no location on it.
#
# The zone name is the domain itself rather than the usual
# <project>-<env>-<resource> name, because a public DNS zone's name is the zone
# it answers for.
#
# Creating the zone before the registrar change is deliberate: DENIC checks the
# new name servers when a .de delegation is updated, and the update fails when
# the zone does not exist on them yet. See "DNS and the INWX delegation" in
# terraform/README.md.
resource "azurerm_dns_zone" "prod" {
  name                = "sudhaus-engen.de"
  resource_group_name = azurerm_resource_group.prod.name

  tags = local.common_tags
}

# The apex of sudhaus-engen.de. A zone apex cannot hold a CNAME, so it points
# at the Container Apps environment's single static ingress address instead of
# at the app's generated host name. Azure keeps that address for the life of
# the environment.
#
# No CAA record accompanies it: the zone publishes none at all, which leaves
# every public CA free to issue, including the DigiCert account behind the
# Azure-managed certificate.
resource "azurerm_dns_a_record" "apex" {
  name                = "@"
  zone_name           = azurerm_dns_zone.prod.name
  resource_group_name = azurerm_resource_group.prod.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.prod.static_ip_address]

  tags = local.common_tags
}

# Proof that this subscription controls the domain. Azure resolves
# asuid.sudhaus-engen.de and compares it with the app's verification id before
# it accepts the custom domain, so this record has to be in place first.
resource "azurerm_dns_txt_record" "asuid" {
  name                = "asuid"
  zone_name           = azurerm_dns_zone.prod.name
  resource_group_name = azurerm_resource_group.prod.name
  ttl                 = 300

  record {
    value = azurerm_container_app.prod.custom_domain_verification_id
  }

  tags = local.common_tags
}

# The custom domain and its Azure-managed certificate, split across two
# resources on purpose.
#
# Section 4.2 of .github/ace-fca/research/0001-site-rollout-requirements.md
# lists the combinations the pinned ~> 5.0 provider offers. Binding the host
# name and the certificate in one step, by setting
# container_app_environment_certificate_id here, needs a certificate that
# already exists. HTTP validation cannot produce one first: the validating CA
# fetches http://sudhaus-engen.de/.well-known/pki-validation/fileauth.txt from
# the app, which only answers for the domain once the host name is bound. The
# two resources would wait on each other.
#
# So the host name is added on its own, with no certificate arguments, and the
# managed certificate is issued against it afterwards. Azure attaches the
# issued certificate to the host name itself, outside Terraform, which is what
# the ignore_changes below covers: without it every later plan would read
# Azure's binding as drift and replace the custom domain.
#
# azurerm_container_app_environment_certificate is the remaining candidate, but
# it uploads an operator-supplied PFX, which is the certificate automation
# ADR 0001 set out to avoid.
resource "azurerm_container_app_custom_domain" "prod" {
  name             = azurerm_dns_zone.prod.name
  container_app_id = azurerm_container_app.prod.id

  # Neither record is an argument here, so the graph does not order them, and
  # Azure rejects the binding while asuid does not resolve.
  depends_on = [
    azurerm_dns_a_record.apex,
    azurerm_dns_txt_record.asuid,
  ]

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

# HTTP is the validation method an apex domain gets; CNAME validation is for
# subdomains. Issuance and every automatic renewal reach the app over the
# custom domain, which is why the app holds min_replicas = 1.
resource "azurerm_container_app_environment_managed_certificate" "prod" {
  name                         = "sudhaus-engen-prod-cert"
  container_app_environment_id = azurerm_container_app_environment.prod.id
  subject_name                 = azurerm_dns_zone.prod.name
  domain_control_validation    = "HTTP"

  depends_on = [azurerm_container_app_custom_domain.prod]

  tags = local.common_tags
}
