output "resource_group_name" {
  value       = azurerm_resource_group.manual.name
  description = "Recreated application resource group"
}

output "foundry_account_id" {
  value       = azurerm_cognitive_account.foundry.id
  description = "Azure AI Foundry AIServices account ID"
}

output "foundry_project_id" {
  value       = azurerm_cognitive_account_project.foundry.id
  description = "Azure AI Foundry project ID"
}

output "foundry_primary_access_key" {
  value       = azurerm_cognitive_account.foundry.primary_access_key
  description = "Primary key of the recreated Foundry account"
  sensitive   = true
}

output "openai_endpoint" {
  value       = "https://${azurerm_cognitive_account.foundry.name}.openai.azure.com"
  description = "Azure OpenAI-compatible endpoint used by the backend"
}

output "gpt_4o_deployment_name" {
  value       = azurerm_cognitive_deployment.gpt_4o.name
  description = "Default chat deployment used by the backend"
}

output "search_service_id" {
  value       = azurerm_search_service.search.id
  description = "Azure AI Search resource ID"
}

output "search_primary_key" {
  value       = azurerm_search_service.search.primary_key
  description = "Primary admin key of Azure AI Search"
  sensitive   = true
}

output "search_endpoint" {
  value       = azurerm_search_service.search.endpoint
  description = "Azure AI Search endpoint"
}

output "speech_primary_access_key" {
  value       = azurerm_cognitive_account.speech.primary_access_key
  description = "Primary key of Azure AI Speech"
  sensitive   = true
}

output "communication_primary_connection_string" {
  value       = azurerm_communication_service.email.primary_connection_string
  description = "Primary Azure Communication Services connection string"
  sensitive   = true
}

output "acs_sender_email" {
  value = format(
    "%s@%s",
    azurerm_email_communication_service_domain_sender_username.default.name,
    azurerm_email_communication_service_domain.azure_managed.mail_from_sender_domain,
  )
  description = "Full sender address on the Azure-managed email domain"
}

output "document_storage_account_name" {
  value       = azurerm_storage_account.documents.name
  description = "Storage account that receives the restored source PDFs"
}

output "document_storage_container_name" {
  value       = azurerm_storage_container.documents.name
  description = "Container that receives the restored source PDFs"
}
