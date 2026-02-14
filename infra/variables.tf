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
  description = "Allowed Origins for CORS (Static Web App URL wird automatisch hinzugefügt)"
}

# Azure OpenAI Configuration
variable "azure_openai_endpoint" {
  type        = string
  default     = "https://agentic-ai-mfg.openai.azure.com"
  description = "Azure OpenAI Endpoint"
}

variable "azure_openai_deployment" {
  type        = string
  default     = "gpt-4o"
  description = "Azure OpenAI Deployment Name"
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
variable "azure_search_endpoint" {
  type        = string
  default     = "https://ai-search-mfg.search.windows.net"
  description = "Azure AI Search Endpoint"
}

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
variable "azure_openai_api_key" {
  type        = string
  sensitive   = true
  description = "Azure OpenAI API Key"
}

variable "azure_search_admin_key" {
  type        = string
  sensitive   = true
  description = "Azure Search Admin Key"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Smart Planning API Client Secret"
}

variable "azure_speech_key" {
  type        = string
  sensitive   = true
  description = "Azure Speech Service Key"
}

# Container Scaling Configuration
variable "min_replicas" {
  type        = number
  default     = 0
  description = "Minimum replicas (0 = Scale-to-Zero)"
}

variable "max_replicas" {
  type        = number
  default     = 5
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
