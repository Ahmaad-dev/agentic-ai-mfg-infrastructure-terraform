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

# Netzwerk fuer die Smart-Planning-Anbindung (04.08.2026), siehe network.tf.
# 10.113.0.0/22 ist gegen alle am Hub vnet-p-weu-ccadmm-hub sichtbaren
# Peerings kollisionsfrei. Vor dem ersten Apply gegen das IPAM gegenpruefen.
# Das Peering nach vnet-t-weu-ccadmm-idp ist ein GLOBAL Peering
# (swedencentral <-> westeurope) — hoeherer Preis je GB, ~20 ms Latenz.
vnet_name          = "vnet-agentic-ai-mfg"
vnet_address_space = "10.113.0.0/22"
cae_subnet_name    = "snet-cae-infrastructure"
cae_subnet_prefix  = "10.113.0.0/23"

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
api_port = 8000
# Scale-to-Zero DEAKTIVIERT (02.08.2026, Nutzerentscheidung): das Backend faehrt die
# Korrektur-Pipeline in mehrminuetigen Subprozessen. Ein Kaltstart mitten im Ablauf ist
# nicht zumutbar, und die Wartezeit beim ersten Request entfaellt damit ebenfalls.
# ACHTUNG: max_replicas bleibt 1 — ein langer Pipeline-Lauf belegt die einzige Instanz
# weiterhin fuer die gesamte Dauer.
min_replicas     = 1
max_replicas     = 1
container_cpu    = 0.5
container_memory = "1Gi"
# 08.08.2026 von 0.2.1 auf 0.3.1 gehoben. 0.2.1 stammt vom 18.02.2026 — also aus
# der Zeit VOR dem Dockerfile-Umbau (Requirements system-weit statt `pip install
# --user`, plus `USER appuser`). In diesem alten Image liegt gunicorn unter
# /root/.local/bin/, worauf appuser nicht zugreifen darf. Der Container startete
# daher gar nicht:
#   can't open file '/root/.local/bin/gunicorn': [Errno 13] Permission denied
# 0.3.1 wurde am 04.08.2026 aus dem korrigierten Dockerfile gebaut.
image_tag = "0.3.1"

# Azure OpenAI Configuration
# 02.08.2026 von gpt-4o auf gpt-4.1 umgestellt. Diese EINE Zeile speist ueber das
# Key-Vault-Secret azure-openai-deployment alle drei Alias-Variablen (CHAT, RAG,
# ORCHESTRATION) — sie stellt also das gesamte Backend um.
azure_openai_deployment            = "gpt-4.1"
azure_openai_api_version           = "2025-01-01-preview"
azure_openai_embeddings_deployment = "text-embedding-3-small"

# Azure AI Search Configuration
azure_search_index = "process-docs-index"

# Azure Speech Configuration
azure_speech_region = "swedencentral"

# Pending-review notification recipient
notification_recipient_email = "ahmad.alsayad@cancom.com"

# Allowed origins - wird durch Static Web App ergänzt
allowed_origins = []
