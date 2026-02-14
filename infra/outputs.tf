output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group Name"
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR Login Server"
}

# Container App Outputs - AUSKOMMENTIERT BIS IMAGE VORHANDEN
# output "container_app_fqdn" {
#   value       = azurerm_container_app.api.ingress[0].fqdn
#   description = "Container App FQDN (Backend API URL)"
# }
# 
# output "container_app_url" {
#   value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
#   description = "Container App Full URL"
# }

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Storage Account Name"
}

output "storage_container_name" {
  value       = azurerm_storage_container.snapshots.name
  description = "Blob Container Name for Snapshots"
}

output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault Name"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI"
}

output "managed_identity_client_id" {
  value       = azurerm_user_assigned_identity.mi.client_id
  description = "Managed Identity Client ID"
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.mi.principal_id
  description = "Managed Identity Principal ID"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "Log Analytics Workspace ID"
}

output "container_app_environment_id" {
  value       = azurerm_container_app_environment.cae.id
  description = "Container App Environment ID"
}
