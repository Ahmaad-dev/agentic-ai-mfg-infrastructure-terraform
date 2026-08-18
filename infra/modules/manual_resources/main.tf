terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  common_tags = {
    Owner       = var.owner_tag
    Environment = "Production"
    Project     = "Agentic-AI-MFG"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "manual" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cognitive_account" "foundry" {
  name                          = var.foundry_account_name
  resource_group_name           = azurerm_resource_group.manual.name
  location                      = azurerm_resource_group.manual.location
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = var.foundry_account_name
  project_management_enabled    = true
  local_auth_enabled            = true
  public_network_access_enabled = true
  tags                          = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Allow"
    ip_rules       = var.foundry_allowed_ips
  }
}

resource "azurerm_cognitive_account_project" "foundry" {
  name                 = var.foundry_project_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_cognitive_account.foundry.location
  display_name         = var.foundry_project_name
  description          = "Default project created with the resource"
  tags                 = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "gpt_4_1" {
  name                   = "gpt-4.1"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-4.1"
    version = "2025-04-14"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 5000
  }
}

resource "azurerm_cognitive_deployment" "gpt_4o" {
  name                   = "gpt-4o"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }

  sku {
    name     = "DataZoneStandard"
    capacity = 250
  }
}

resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  name                   = "gpt-4o-mini"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "DataZoneStandard"
    capacity = 200
  }
}

resource "azurerm_cognitive_deployment" "gpt_5_1" {
  name                   = "gpt-5.1"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-5.1"
    version = "2025-11-13"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 150
  }
}

resource "azurerm_cognitive_deployment" "gpt_5_2_chat" {
  name                   = "gpt-5.2-chat"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-chat-latest"
    version = "2026-05-05"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 350
  }
}

resource "azurerm_cognitive_deployment" "text_embedding_3_small" {
  name                   = "text-embedding-3-small"
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = "NoAutoUpgrade"
  rai_policy_name        = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 350
  }
}

resource "azurerm_cognitive_account" "speech" {
  name                          = var.speech_account_name
  resource_group_name           = azurerm_resource_group.manual.name
  location                      = azurerm_resource_group.manual.location
  kind                          = "SpeechServices"
  sku_name                      = "F0"
  local_auth_enabled            = true
  public_network_access_enabled = true
  tags                          = local.common_tags
}

resource "azurerm_search_service" "search" {
  name                          = var.search_service_name
  resource_group_name           = azurerm_resource_group.manual.name
  location                      = azurerm_resource_group.manual.location
  sku                           = "free"
  replica_count                 = 1
  partition_count               = 1
  hosting_mode                  = "default"
  local_authentication_enabled  = true
  public_network_access_enabled = true
  network_rule_bypass_option    = "None"
  tags                          = local.common_tags
}

resource "azurerm_storage_account" "documents" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.manual.name
  location                        = azurerm_resource_group.manual.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = true
  large_file_share_enabled        = true
  is_hns_enabled                  = false
  default_to_oauth_authentication = false
  local_user_enabled              = true
  tags                            = local.common_tags

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "documents" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.documents.id
  container_access_type = "private"
}

resource "azurerm_communication_service" "email" {
  name                = var.communication_service_name
  resource_group_name = azurerm_resource_group.manual.name
  data_location       = "Europe"
  tags                = local.common_tags
}

resource "azurerm_email_communication_service" "email" {
  name                = var.email_communication_service_name
  resource_group_name = azurerm_resource_group.manual.name
  data_location       = "Europe"
  tags                = local.common_tags
}

resource "azurerm_email_communication_service_domain" "azure_managed" {
  name                             = "AzureManagedDomain"
  email_service_id                 = azurerm_email_communication_service.email.id
  domain_management                = "AzureManaged"
  user_engagement_tracking_enabled = false
  tags                             = local.common_tags
}

resource "azurerm_communication_service_email_domain_association" "email" {
  communication_service_id = azurerm_communication_service.email.id
  email_service_domain_id  = azurerm_email_communication_service_domain.azure_managed.id
}

resource "azurerm_email_communication_service_domain_sender_username" "default" {
  name                    = var.acs_sender_username
  email_service_domain_id = azurerm_email_communication_service_domain.azure_managed.id
  display_name            = var.acs_sender_display_name
}

resource "azurerm_cognitive_account_connection_api_key" "search" {
  name                 = "aisearchmfg7ezg7x"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  category             = "CognitiveSearch"
  target               = "${trimsuffix(azurerm_search_service.search.endpoint, "/")}/"
  api_key              = azurerm_search_service.search.primary_key
  metadata = {
    ApiType              = "Azure"
    ApiVersion           = "2024-05-01-preview"
    DeploymentApiVersion = "2023-11-01"
    ResourceId           = azurerm_search_service.search.id
    displayName          = var.search_service_name
    type                 = "azure_ai_search"
  }

  depends_on = [azurerm_cognitive_account_project.foundry]
}
