variable "location" {
  type        = string
  description = "Azure region for regional resources"
}

variable "owner_tag" {
  type        = string
  description = "Owner tag applied to the recreated resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the manually deleted and Terraform-recreated resource group"
}

variable "foundry_account_name" {
  type        = string
  description = "Azure AI Foundry AIServices account name"
}

variable "foundry_project_name" {
  type        = string
  description = "Azure AI Foundry project name"
}

variable "foundry_allowed_ips" {
  type        = list(string)
  description = "IP rules captured from the existing Foundry account"
}

variable "speech_account_name" {
  type        = string
  description = "Azure AI Speech account name"
}

variable "search_service_name" {
  type        = string
  description = "Azure AI Search service name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account for the AI source documents"
}

variable "storage_container_name" {
  type        = string
  description = "Private blob container for the AI source documents"
}

variable "communication_service_name" {
  type        = string
  description = "Azure Communication Services resource name"
}

variable "email_communication_service_name" {
  type        = string
  description = "Email Communication Service resource name"
}

variable "acs_sender_username" {
  type        = string
  description = "Username on the Azure-managed email domain"
}

variable "acs_sender_display_name" {
  type        = string
  description = "Display name of the ACS email sender"
}
