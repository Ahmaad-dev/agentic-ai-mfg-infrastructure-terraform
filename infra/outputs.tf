output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group Name"
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR Login Server"
}

#Container App Outputs - AUSKOMMENTIERT BIS IMAGE VORHANDEN
output "container_app_fqdn" {
  value       = azurerm_container_app.api.ingress[0].fqdn
  description = "Container App FQDN (Backend API URL)"
}

output "container_app_url" {
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
  description = "Container App Full URL"
}

output "container_app_default_domain" {
  description = "Container App Default FQDN (for DNS CNAME)"
  value       = azurerm_container_app.api.ingress[0].fqdn
}

output "container_app_custom_domain" {
  description = "Custom Domain Name (if configured)"
  value       = var.custom_domain_name != "" ? var.custom_domain_name : "Not configured - use default domain"
}

output "container_app_revision_info" {
  description = "Container App Revision Info"
  value = {
    mode        = var.revision_mode
    latest_name = azurerm_container_app.api.latest_revision_name
    blue_green  = var.enable_blue_green
  }
}

output "static_web_app_url" {
  description = "Static Web App Default URL"
  value       = "https://${azurerm_static_web_app.ui.default_host_name}"
}

output "static_web_app_api_token" {
  description = "Static Web App Deployment Token (for GitHub Actions)"
  value       = azurerm_static_web_app.ui.api_key
  sensitive   = true
}

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

output "manual_resource_group_name" {
  value       = module.manual_resources.resource_group_name
  description = "Resource group recreated from the former manual deployment"
}

output "foundry_account_id" {
  value       = module.manual_resources.foundry_account_id
  description = "Azure AI Foundry AIServices account ID"
}

output "foundry_project_id" {
  value       = module.manual_resources.foundry_project_id
  description = "Azure AI Foundry project ID"
}

output "azure_openai_endpoint" {
  value       = module.manual_resources.openai_endpoint
  description = "Azure OpenAI-compatible endpoint"
}

output "azure_search_service_id" {
  value       = module.manual_resources.search_service_id
  description = "Azure AI Search service ID"
}

output "document_storage" {
  value = {
    account_name   = module.manual_resources.document_storage_account_name
    container_name = module.manual_resources.document_storage_container_name
  }
  description = "Target for restoring the three source PDF files"
}

output "acs_sender_email" {
  value       = module.manual_resources.acs_sender_email
  description = "Email sender address on the recreated ACS Azure-managed domain"
}
