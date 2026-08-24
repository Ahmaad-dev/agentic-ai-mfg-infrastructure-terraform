variable "prefix" {
  type        = string
  default     = "agenticai"
  description = "Prefix for all resources"
}

variable "location" {
  type        = string
  default     = "Sweden Central"
  description = "Azure Region"
}

variable "subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure subscription ID required by AzureRM 4.x; provide via TF_VAR_subscription_id"
}

variable "owner_tag" {
  type        = string
  default     = "ahmad.alsayad@cca-dev.com"
  description = "Owner tag for all resources"
}

variable "rg_name" {
  type        = string
  default     = "rg-agentic-ai-mfg-prod"
  description = "Resource Group Name"
}

variable "acr_name" {
  type        = string
  default     = "acragenticaimfg"
  description = "Azure Container Registry Name"
}

variable "kv_name" {
  type        = string
  default     = "kv-agentic-ai-mfg"
  description = "Key Vault Name"
}

variable "sa_name" {
  type        = string
  default     = "stagenticaimfg"
  description = "Storage Account Name for Blob Storage"
}

variable "storage_container_name" {
  type        = string
  default     = "snapshots"
  description = "Blob Storage Container for Snapshots"
}

variable "cae_name" {
  type        = string
  default     = "cae-agentic-ai-mfg"
  description = "Container App Environment Name"
}

# --- Netzwerk (Smart-Planning-Anbindung, siehe network.tf) -------------------

variable "vnet_name" {
  type        = string
  default     = "vnet-agentic-ai-mfg"
  description = "Virtual Network Name"
}

variable "vnet_address_space" {
  type        = string
  default     = "10.113.0.0/22"
  description = <<-EOT
    Adressraum des VNets. Darf sich mit KEINEM Netz ueberschneiden, mit dem
    spaeter gepeert wird. Belegt sind laut Hub-Peerings (Stand 2026-08-04):
    10.112.0.0/23 (Hub), 10.112.16.0/22 (IDP), 10.112.32.0/29,
    10.127.224.0/22, 10.127.228.0/24, 10.128.0.0/22 bis 10.128.12.0/22,
    10.100.200.0/22. Vor dem ersten Apply gegen das IPAM gegenpruefen —
    sichtbar sind hier nur die an DIESEN Hub gepeerten Bereiche.
  EOT

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid CIDR block."
  }
}

variable "cae_subnet_name" {
  type        = string
  default     = "snet-cae-infrastructure"
  description = "Name des Infrastruktur-Subnetzes der Container App Environment"
}

variable "cae_subnet_prefix" {
  type        = string
  default     = "10.113.0.0/23"
  description = <<-EOT
    Infrastruktur-Subnetz der Container App Environment. Mindestens /23 fuer
    eine Consumption-only Environment. Muss innerhalb von vnet_address_space
    liegen und gehoert exklusiv der Environment.
  EOT

  validation {
    condition     = can(cidrhost(var.cae_subnet_prefix, 0))
    error_message = "cae_subnet_prefix must be a valid CIDR block."
  }
}

variable "ca_name" {
  type        = string
  default     = "ca-agentic-ai-backend"
  description = "Container App Name"
}

variable "mi_name" {
  type        = string
  default     = "mi-agentic-ai-mfg"
  description = "User Assigned Managed Identity Name"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Container image tag"
}

variable "api_port" {
  type        = number
  default     = 8000
  description = "API Port (Flask default)"
}

variable "allowed_origins" {
  type        = list(string)
  default     = []
  description = "Allowed Origins for CORS"
}

variable "custom_domain_name" {
  description = "Custom domain name for Container App (optional, e.g. api.agentic-ai-mfg.com)"
  type        = string
  default     = ""
}

variable "revision_mode" {
  description = "Revision mode: Single (only latest) or Multiple (traffic split, blue/green)"
  type        = string
  default     = "Single"
  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "Revision mode must be either 'Single' or 'Multiple'."
  }
}

variable "enable_blue_green" {
  description = "Enable Blue/Green deployment with traffic split (requires Multiple revision mode)"
  type        = bool
  default     = false
}

# Resources recreated from the manually deployed resource group
variable "manual_rg_name" {
  type        = string
  default     = "rg-agentic-ai-mfg"
  description = "Resource group deleted manually in the portal and then recreated by Terraform"
}

variable "terraform_principal_object_id" {
  type        = string
  default     = "1b513227-4b85-413f-bb86-b603197b92dc"
  description = "Object ID of the GitHub Actions managed identity that Terraform grants Key Vault Secrets Officer"
}

variable "foundry_account_name" {
  type        = string
  default     = "agentic-ai-mfg"
  description = "Azure AI Foundry AIServices account name"
}

variable "foundry_project_name" {
  type        = string
  default     = "agentic-ai-mfg-project"
  description = "Azure AI Foundry project name"
}

variable "foundry_allowed_ips" {
  type = list(string)
  default = [
    "46.151.204.34",
    "212.197.172.220",
    "84.115.220.146",
    "84.115.213.84",
    "46.124.165.247",
    "140.78.167.9",
    "140.78.5.110",
    "140.78.5.104",
    "194.166.59.190",
    "192.164.16.200",
  ]
  description = "IP rules captured from the existing Foundry account"
}

variable "speech_account_name" {
  type        = string
  default     = "agentic-ai-stt-mfg"
  description = "Azure AI Speech service name"
}

variable "search_service_name" {
  type        = string
  default     = "ai-search-mfg"
  description = "Azure AI Search service name"
}

variable "document_storage_account_name" {
  type        = string
  default     = "saagenticaimfg"
  description = "Storage account for AI source documents"
}

variable "document_storage_container_name" {
  type        = string
  default     = "basic-ai-informations"
  description = "Private blob container for AI source documents"
}

# Azure OpenAI Configuration
variable "azure_openai_deployment" {
  type        = string
  default     = "gpt-4o"
  description = "Azure OpenAI Deployment Name"

  validation {
    condition = contains([
      "gpt-4.1",
      "gpt-4o",
      "gpt-4o-mini",
      "gpt-5.1",
      "gpt-5.2-chat",
    ], var.azure_openai_deployment)
    error_message = "azure_openai_deployment must reference one of the Terraform-managed chat deployments."
  }
}

variable "azure_openai_api_version" {
  type        = string
  default     = "2025-01-01-preview"
  description = "Azure OpenAI API Version"
}

variable "azure_openai_embeddings_deployment" {
  type        = string
  default     = "text-embedding-3-small"
  description = "Azure OpenAI Embeddings Deployment"
}

# Azure AI Search Configuration
variable "azure_search_index" {
  type        = string
  default     = "process-docs-index"
  description = "Azure AI Search Index Name"
}

# Azure Speech Configuration
variable "azure_speech_region" {
  type        = string
  default     = "swedencentral"
  description = "Azure Speech Service Region"
}

# Sensitive Variables (aus GitHub Secrets)
variable "smart_planning_client_secret" {
  type        = string
  sensitive   = true
  description = "Smart Planning API client secret; provide via TF_VAR_smart_planning_client_secret"

  validation {
    condition     = length(trimspace(var.smart_planning_client_secret)) > 0
    error_message = "smart_planning_client_secret must not be empty; configure SMART_PLANNING_CLIENT_SECRET as a GitHub repository secret."
  }
}

# Container Scaling Configuration
variable "min_replicas" {
  type        = number
  default     = 1
  description = "Minimum replicas (0 = Scale-to-Zero; hier bewusst 1, siehe terraform.tfvars)"
}

variable "max_replicas" {
  type        = number
  default     = 1
  description = "Maximum replicas"
}

variable "container_cpu" {
  type        = number
  default     = 0.5
  description = "Container CPU (vCPU)"
}

variable "container_memory" {
  type        = string
  default     = "1Gi"
  description = "Container Memory"
}

# Azure SQL
variable "sql_server_name" {
  type        = string
  default     = "sql-agentic-ai-mfg"
  description = "Base name of the Azure SQL logical server; the existing random suffix is appended"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,54}[a-z0-9]$", var.sql_server_name))
    error_message = "sql_server_name must contain 2-56 lowercase letters, digits, or hyphens and must start and end with a letter or digit."
  }
}

variable "sql_database_name" {
  type        = string
  default     = "sqldb-agentic-ai-mfg"
  description = "Azure SQL database name"
}

variable "sql_sku" {
  type        = string
  default     = "Basic"
  description = "Cost-optimized Azure SQL Database SKU for the application workload"
}

variable "sql_admin_username" {
  type        = string
  default     = "agenticaiadmin"
  description = "SQL authentication administrator username"
}

# Azure Communication Services Email
variable "communication_service_name" {
  type        = string
  default     = "acs-agentic-ai-test"
  description = "Azure Communication Service recreated with its existing name"
}

variable "email_communication_service_name" {
  type        = string
  default     = "agentic-ai-mfg-ecs-test"
  description = "Email Communication Service recreated with its existing name"
}

variable "acs_sender_username" {
  type        = string
  default     = "DoNotReply"
  description = "Sender username for the Azure-managed ACS email domain"
}

variable "acs_sender_display_name" {
  type        = string
  default     = "DoNotReply"
  description = "Display name for ACS email messages"
}

variable "notification_recipient_email" {
  type        = string
  description = "Recipient for pending-review notifications"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", trimspace(var.notification_recipient_email)))
    error_message = "notification_recipient_email must be a valid email address."
  }
}

# ENTFERNT am 2026-08-23 (AP-UI1.1): die Variablen "human_in_the_loop" und
# "rulebook_mode". Sie wurden ausschliesslich von den beiden env-Bloecken in main.tf
# benutzt, die auf ausdrueckliche Entscheidung entfernt wurden. Eine nicht mehr
# referenzierte Variable mitzufuehren waere toter Code und wuerde faelschlich eine
# Stellschraube suggerieren, die nichts mehr bewirkt.
#
# Beide Schalter sind seit AP-UI1 in der Anwendung konfigurierbar. Wer sie wieder
# deploymentseitig festlegen will, braucht die Variable UND den env-Block in main.tf.

variable "skills_container_name" {
  description = "Blob-Container fuer die Lernkarten (AP7). Getrennt von den Snapshots, damit Konfiguration und Daten nicht im selben Behaelter liegen."
  type        = string
  default     = "skills"
}
