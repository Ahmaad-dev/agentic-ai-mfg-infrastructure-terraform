data "azurerm_client_config" "me" {}

# Random Suffix für globale Uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Generated once and persisted in the remote Terraform state. The value is
# reused for Azure SQL and stored in Key Vault for controlled retrieval.
resource "random_password" "sql_admin" {
  length           = 32
  special          = true
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
  override_special = "!#$%&*()-_=+[]{}:?"
}

# Lokale Variablen für Tags
locals {
  common_tags = {
    Owner       = var.owner_tag
    Environment = "Production"
    Project     = "Agentic-AI-MFG"
    ManagedBy   = "Terraform"
  }
  suffix = random_string.suffix.result

  database_url = sensitive(format(
    "mssql+pyodbc://%s:%s@%s:1433/%s?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=no",
    urlencode(var.sql_admin_username),
    urlencode(random_password.sql_admin.result),
    azurerm_mssql_server.application.fully_qualified_domain_name,
    var.sql_database_name,
  ))

  acs_sender_email = module.manual_resources.acs_sender_email
}

# Resources that currently exist in rg-agentic-ai-mfg and will be recreated
# by Terraform after that resource group is manually deleted in the portal.
module "manual_resources" {
  source = "./modules/manual_resources"

  location                         = var.location
  owner_tag                        = var.owner_tag
  resource_group_name              = var.manual_rg_name
  foundry_account_name             = var.foundry_account_name
  foundry_project_name             = var.foundry_project_name
  foundry_allowed_ips              = var.foundry_allowed_ips
  speech_account_name              = var.speech_account_name
  search_service_name              = var.search_service_name
  storage_account_name             = var.document_storage_account_name
  storage_container_name           = var.document_storage_container_name
  communication_service_name       = var.communication_service_name
  email_communication_service_name = var.email_communication_service_name
  acs_sender_username              = var.acs_sender_username
  acs_sender_display_name          = var.acs_sender_display_name
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = local.common_tags
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "mi" {
  name                = "${var.mi_name}-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  encryption          = []
  tags                = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "${var.kv_name}-${local.suffix}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.me.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags                       = local.common_tags
}

# Key Vault Secrets - Azure OpenAI
resource "azurerm_key_vault_secret" "azure_openai_key" {
  name         = "AZURE-OPENAI-API-KEY"
  value        = module.manual_resources.foundry_primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_openai_endpoint" {
  name         = "AZURE-OPENAI-ENDPOINT"
  value        = module.manual_resources.openai_endpoint
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_openai_deployment" {
  name         = "AZURE-OPENAI-DEPLOYMENT"
  value        = var.azure_openai_deployment
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Key Vault Secrets - Azure Search
resource "azurerm_key_vault_secret" "azure_search_key" {
  name         = "AZURE-SEARCH-ADMIN-KEY"
  value        = module.manual_resources.search_primary_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_search_endpoint" {
  name         = "AZURE-SEARCH-ENDPOINT"
  value        = module.manual_resources.search_endpoint
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_search_index" {
  name         = "AZURE-SEARCH-INDEX"
  value        = var.azure_search_index
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Key Vault Secret - Smart Planning Client Secret
resource "azurerm_key_vault_secret" "client_secret" {
  name         = "CLIENT-SECRET"
  value        = var.smart_planning_client_secret
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Key Vault Secret - Azure Speech
resource "azurerm_key_vault_secret" "azure_speech_key" {
  name         = "AZURE-SPEECH-KEY"
  value        = module.manual_resources.speech_primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Storage Account für Blob Storage (Snapshots)
resource "azurerm_storage_account" "storage" {
  name                             = "${var.sa_name}${local.suffix}"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  account_kind                     = "StorageV2"
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  https_traffic_only_enabled       = true
  cross_tenant_replication_enabled = true
  tags                             = local.common_tags
}

# Blob Container für Snapshots
resource "azurerm_storage_container" "snapshots" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Container App Environment
resource "azurerm_container_app_environment" "cae" {
  name                       = "${var.cae_name}-${local.suffix}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.common_tags
}

# Container App
resource "azurerm_container_app" "api" {
  name                         = "${var.ca_name}-${local.suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = var.revision_mode
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.mi.id
  }

  ingress {
    external_enabled = true
    transport        = "auto"
    target_port      = var.api_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "agentic-ai-backend"
      image  = "${azurerm_container_registry.acr.login_server}/agentic-ai-backend:${var.image_tag}"
      cpu    = var.container_cpu
      memory = var.container_memory

      # Environment Variables - Non-Sensitive
      env {
        name  = "AZURE_OPENAI_API_VERSION"
        value = var.azure_openai_api_version
      }

      env {
        name  = "AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT"
        value = var.azure_openai_embeddings_deployment
      }

      env {
        name  = "AZURE_SPEECH_REGION"
        value = var.azure_speech_region
      }

      # Environment Variables - From Key Vault Secrets
      env {
        name        = "AZURE_OPENAI_API_KEY"
        secret_name = "azure-openai-api-key"
      }

      env {
        name        = "AZURE_OPENAI_ENDPOINT"
        secret_name = "azure-openai-endpoint"
      }

      env {
        name        = "AZURE_OPENAI_DEPLOYMENT"
        secret_name = "azure-openai-deployment"
      }

      env {
        name        = "AZURE_SEARCH_ADMIN_KEY"
        secret_name = "azure-search-admin-key"
      }

      env {
        name        = "AZURE_SEARCH_ENDPOINT"
        secret_name = "azure-search-endpoint"
      }

      env {
        name        = "AZURE_SEARCH_INDEX"
        secret_name = "azure-search-index"
      }

      env {
        name        = "CLIENT_SECRET"
        secret_name = "client-secret"
      }

      env {
        name        = "AZURE_SPEECH_KEY"
        secret_name = "azure-speech-key"
      }

      # Relational persistence
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      # Azure Communication Services Email
      env {
        name  = "NOTIFICATION_CHANNEL"
        value = "acs"
      }

      env {
        name        = "ACS_CONNECTION_STRING"
        secret_name = "acs-connection-string"
      }

      env {
        name  = "ACS_SENDER_EMAIL"
        value = local.acs_sender_email
      }

      env {
        name        = "NOTIFICATION_RECIPIENT_EMAIL"
        secret_name = "notification-recipient-email"
      }

      env {
        name  = "APP_BASE_URL"
        value = "https://${azurerm_static_web_app.ui.default_host_name}"
      }

      # Agent-spezifische OpenAI Env Vars (Chat, RAG, Orchestration)
      env {
        name        = "AZURE_OPENAI_CHAT_ENDPOINT"
        secret_name = "azure-openai-endpoint"
      }
      env {
        name        = "AZURE_OPENAI_CHAT_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_OPENAI_CHAT_API_VERSION"
        value = var.azure_openai_api_version
      }
      env {
        name        = "AZURE_OPENAI_CHAT_DEPLOYMENT"
        secret_name = "azure-openai-deployment"
      }

      env {
        name        = "AZURE_OPENAI_RAG_ENDPOINT"
        secret_name = "azure-openai-endpoint"
      }
      env {
        name        = "AZURE_OPENAI_RAG_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_OPENAI_RAG_API_VERSION"
        value = var.azure_openai_api_version
      }
      env {
        name        = "AZURE_OPENAI_RAG_DEPLOYMENT"
        secret_name = "azure-openai-deployment"
      }
      env {
        name        = "AZURE_OPENAI_ORCHESTRATION_ENDPOINT"
        secret_name = "azure-openai-endpoint"
      }
      env {
        name        = "AZURE_OPENAI_ORCHESTRATION_KEY"
        secret_name = "azure-openai-api-key"
      }
      env {
        name  = "AZURE_OPENAI_ORCHESTRATION_API_VERSION"
        value = var.azure_openai_api_version
      }
      env {
        name        = "AZURE_OPENAI_ORCHESTRATION_DEPLOYMENT"
        secret_name = "azure-openai-deployment"
      }
      # Storage Configuration
      env {
        name  = "STORAGE_MODE"
        value = "AZURE"
      }

      env {
        name  = "AZURE_STORAGE_CONNECTION_STRING"
        value = azurerm_storage_account.storage.primary_connection_string
      }

      env {
        name  = "AZURE_STORAGE_CONTAINER"
        value = var.storage_container_name
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  # Key Vault Secrets References
  secret {
    name                = "azure-openai-api-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_key.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-openai-endpoint"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_endpoint.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-openai-deployment"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_deployment.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-admin-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_key.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-endpoint"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_endpoint.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-index"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_index.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "client-secret"
    key_vault_secret_id = azurerm_key_vault_secret.client_secret.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-speech-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_speech_key.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "database-url"
    key_vault_secret_id = azurerm_key_vault_secret.database_url.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "acs-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.acs_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "notification-recipient-email"
    key_vault_secret_id = azurerm_key_vault_secret.notification_recipient_email.versionless_id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  depends_on = [azurerm_role_assignment.uami_kv_secrets_user]
}

# Role Assignments - Managed Identity Permissions
resource "azurerm_role_assignment" "uami_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "uami_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "uami_storage_blob_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "uami_contributor_rg" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Role Assignment - Terraform Service Principal für Key Vault
resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.terraform_principal_object_id
}

# Static Web App
resource "azurerm_static_web_app" "ui" {
  name                = "swa-agentic-ai-ui"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West Europe" # Static Web Apps nicht in Sweden Central verfügbar
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = local.common_tags
}

# Azure SQL persistence
resource "azurerm_mssql_server" "application" {
  name                          = "${var.sql_server_name}-${local.suffix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags                          = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_database" "application" {
  name                                = var.sql_database_name
  server_id                           = azurerm_mssql_server.application.id
  sku_name                            = var.sql_sku
  max_size_gb                         = 2
  storage_account_type                = "Geo"
  transparent_data_encryption_enabled = true
  tags                                = local.common_tags

  short_term_retention_policy {
    retention_days           = 7
    backup_interval_in_hours = 12
  }

  lifecycle {
    prevent_destroy = true
  }
}

# The existing Container Apps Environment has neither VNet integration nor a
# stable, dedicated outbound IP. The Azure-services rule is therefore the
# narrowest reliable SQL firewall option without adding prohibited networking.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.application.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_key_vault_secret" "database_url" {
  name         = "DATABASE-URL"
  value        = local.database_url
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "SQL-ADMIN-PASSWORD"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "acs_connection_string" {
  name         = "ACS-CONNECTION-STRING"
  value        = module.manual_resources.communication_primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "notification_recipient_email" {
  name         = "NOTIFICATION-RECIPIENT-EMAIL"
  value        = trimspace(var.notification_recipient_email)
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}
