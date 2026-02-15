data "azurerm_client_config" "me" {}

# Random Suffix für globale Uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
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
  tags                = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.kv_name}-${local.suffix}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  tenant_id                   = data.azurerm_client_config.me.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  tags                        = local.common_tags
}

# Key Vault Secrets - Azure OpenAI
resource "azurerm_key_vault_secret" "azure_openai_key" {
  name         = "AZURE-OPENAI-API-KEY"
  value        = var.azure_openai_api_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_openai_endpoint" {
  name         = "AZURE-OPENAI-ENDPOINT"
  value        = var.azure_openai_endpoint
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
  value        = var.azure_search_admin_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "azure_search_endpoint" {
  name         = "AZURE-SEARCH-ENDPOINT"
  value        = var.azure_search_endpoint
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
  value        = var.client_secret
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Key Vault Secret - Azure Speech
resource "azurerm_key_vault_secret" "azure_speech_key" {
  name         = "AZURE-SPEECH-KEY"
  value        = var.azure_speech_key
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

# Storage Account für Blob Storage (Snapshots)
resource "azurerm_storage_account" "storage" {
  name                     = "${var.sa_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
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

# Container App Environment Storage (für Blob Mount)
resource "azurerm_container_app_environment_storage" "snapshots_storage" {
  name                         = "snapshots-storage"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = var.storage_container_name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite"
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

      # Storage Connection
      env {
        name  = "AZURE_STORAGE_CONNECTION_STRING"
        value = azurerm_storage_account.storage.primary_connection_string
      }

      env {
        name  = "SNAPSHOTS_CONTAINER"
        value = var.storage_container_name
      }

      # Volume Mount für Snapshots
      volume_mounts {
        name = "snapshots-volume"
        path = "/mnt/snapshots"
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    volume {
      name         = "snapshots-volume"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.snapshots_storage.name
    }
  }

  # Key Vault Secrets References
  secret {
    name                = "azure-openai-api-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_key.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-openai-endpoint"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_endpoint.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-openai-deployment"
    key_vault_secret_id = azurerm_key_vault_secret.azure_openai_deployment.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-admin-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_key.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-endpoint"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_endpoint.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-search-index"
    key_vault_secret_id = azurerm_key_vault_secret.azure_search_index.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "client-secret"
    key_vault_secret_id = azurerm_key_vault_secret.client_secret.id
    identity            = azurerm_user_assigned_identity.mi.id
  }

  secret {
    name                = "azure-speech-key"
    key_vault_secret_id = azurerm_key_vault_secret.azure_speech_key.id
    identity            = azurerm_user_assigned_identity.mi.id
  }
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
  principal_id         = data.azurerm_client_config.me.object_id
}

# Static Web App
resource "azurerm_static_web_app" "ui" {
  name                = "swa-agentic-ai-ui"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West Europe"  # Static Web Apps nicht in Sweden Central verfügbar
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = local.common_tags
}