# Nicht-sensitive Werte für das Projekt
prefix    = "agenticai"
location  = "Sweden Central"
owner_tag = "ahmad.alsayad@cca-dev.com"

# Existing GitHub Actions managed identity (mi-swe-agentic-ai-mfg-github)
terraform_principal_object_id = "1b513227-4b85-413f-bb86-b603197b92dc"

rg_name  = "rg-agentic-ai-mfg-environment"
acr_name = "acragenticaimfg"
kv_name  = "kv-agentic-ai-mfg"
sa_name  = "stagenticaimfg"
cae_name = "cae-agentic-ai-mfg"
ca_name  = "ca-agentic-ai-backend"
mi_name  = "mi-agentic-ai-mfg"

storage_container_name = "snapshots"

# Resources recreated after manually deleting rg-agentic-ai-mfg in the portal
manual_rg_name                   = "rg-agentic-ai-mfg"
foundry_account_name             = "agentic-ai-mfg"
foundry_project_name             = "agentic-ai-mfg-project"
speech_account_name              = "agentic-ai-stt-mfg"
search_service_name              = "ai-search-mfg"
document_storage_account_name    = "saagenticaimfg"
document_storage_container_name  = "basic-ai-informations"
communication_service_name       = "acs-agentic-ai-test"
email_communication_service_name = "agentic-ai-mfg-ecs-test"
acs_sender_username              = "DoNotReply"
acs_sender_display_name          = "DoNotReply"

# Container Configuration
api_port         = 8000
min_replicas     = 0 # Scale-to-Zero aktiviert
max_replicas     = 1
container_cpu    = 0.5
container_memory = "1Gi"
image_tag        = "0.2.1"

# Azure OpenAI Configuration
azure_openai_deployment            = "gpt-4o"
azure_openai_api_version           = "2025-01-01-preview"
azure_openai_embeddings_deployment = "text-embedding-3-small"

# Azure AI Search Configuration
azure_search_index = "process-docs-index"

# Azure Speech Configuration
azure_speech_region = "swedencentral"

# Allowed origins - wird durch Static Web App ergänzt
allowed_origins = []
