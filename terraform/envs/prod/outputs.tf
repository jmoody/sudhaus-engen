# ------------------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the prod resource group that holds every workload resource."
  value       = azurerm_resource_group.prod.name
}

output "registry_login_server" {
  description = "Container Registry login server, the image prefix for builds and promotions."
  value       = azurerm_container_registry.prod.login_server
}

output "container_app_name" {
  description = "Name of the Container App, the target of an image promotion."
  value       = azurerm_container_app.prod.name
}

output "container_app_default_host_name" {
  description = "Azure-generated FQDN the Container App answers on before a custom domain is attached."
  value       = azurerm_container_app.prod.ingress[0].fqdn
}

# Azure assigns these when it creates the zone, and they are the values the
# operator enters at INWX under "Externe Nameserver".
output "dns_zone_name_servers" {
  description = "Name servers Azure assigned to the sudhaus-engen.de zone, to be entered at INWX as the domain's external name servers."
  value       = azurerm_dns_zone.prod.name_servers
}

# The three values script/bind-custom-domain needs to attach the managed
# certificate to the custom domain, which Terraform cannot do itself.
output "container_app_environment_name" {
  description = "Name of the Container Apps environment that holds the managed certificate."
  value       = azurerm_container_app_environment.prod.name
}

output "custom_domain_name" {
  description = "Custom domain bound to the Container App."
  value       = azurerm_container_app_custom_domain.prod.name
}

output "managed_certificate_id" {
  description = "Resource id of the Azure-managed certificate issued for the custom domain."
  value       = azurerm_container_app_environment_managed_certificate.prod.id
}
