# Nicht-sensitive Werte für das Projekt
prefix     = "agenticai"
location   = "Sweden Central"
owner_tag  = "ahmad.alsayad@cca-dev.com"

rg_name    = "rg-agentic-ai-mfg-environment"
acr_name   = "acragenticaimfg"
kv_name    = "kv-agentic-ai-mfg"
sa_name    = "stagenticaimfg"
cae_name   = "cae-agentic-ai-mfg"
ca_name    = "ca-agentic-ai-backend"
mi_name    = "mi-agentic-ai-mfg"

storage_container_name = "snapshots"

# Container Configuration
api_port         = 8000
min_replicas     = 0  # Scale-to-Zero aktiviert
max_replicas     = 5
container_cpu    = 0.5
container_memory = "1Gi"
image_tag        = "0.1.0"

# Azure OpenAI Configuration
azure_openai_endpoint             = "https://agentic-ai-mfg.openai.azure.com"
azure_openai_deployment           = "gpt-4o"
azure_openai_api_version          = "2025-01-01-preview"
azure_openai_embeddings_deployment = "text-embedding-3-small"

# Azure AI Search Configuration
azure_search_endpoint = "https://ai-search-mfg.search.windows.net"
azure_search_index    = "process-docs-index"

# Azure Speech Configuration
azure_speech_region = "swedencentral"

# Allowed origins - wird durch Static Web App ergänzt
allowed_origins = []
