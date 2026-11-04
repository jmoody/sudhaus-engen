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
