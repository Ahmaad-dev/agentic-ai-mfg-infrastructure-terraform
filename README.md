# agentic-ai-mfg — Infrastruktur (Terraform)

Verwaltet die gesamte Azure-Umgebung für das PT4-Projekt *Agentic AI for Manufacturing*.
Die Anwendung liegt in einem eigenen Repository (`agentic-ai-mfg`); hier steht ausschließlich
Infrastruktur.

> **Grundregel:** Das Backend codiert keine Endpunkte, Schlüssel oder Ressourcennamen fest.
> Alles, was es zur Laufzeit braucht, kommt aus den Umgebungsvariablen, die hier gesetzt
> werden. Wer eine neue Konfiguration einführt, ergänzt sie im `env`-Block der Container App —
> sonst greift im Backend stillschweigend ein Standardwert aus dem Code.

---

## Aufbau

```
infra/
├─ main.tf            Kernressourcen (siehe unten)
├─ variables.tf       Eingabewerte, teils mit Validierung
├─ terraform.tfvars   Nicht-sensitive Werte dieses Projekts
├─ outputs.tf         Ausgaben (FQDN, ACR, Key Vault, …)
├─ provider.tf        AzureRM-Provider
├─ backend.tf(.tfvars) Remote-State in Azure Storage
├─ imports.tf         Bestehende Ressourcen, die übernommen wurden
└─ modules/manual_resources/
                      Ressourcen, die vor Terraform von Hand angelegt wurden und
                      nachträglich in die Verwaltung übernommen sind
```

### Zwei Ressourcengruppen — Absicht, kein Versehen

| Gruppe | Inhalt |
|---|---|
| `rg-agentic-ai-mfg-environment` | Von Terraform erzeugt: ACR, Key Vault, Storage, Container App (Environment), Log Analytics, Static Web App, Azure SQL, Managed Identity |
| `rg-agentic-ai-mfg` | Modul `manual_resources`: AI Foundry + Projekt, Speech, AI Search, Dokumenten-Storage, Communication/Email Services |

Die zweite Gruppe entstand, weil diese Dienste ursprünglich von Hand angelegt wurden. Sie sind
inzwischen übernommen, bleiben aber bewusst getrennt — eine Neuanlage würde Foundry-Projekt
und Email-Domain neu erzeugen und damit Endpunkte ändern.

---

## Erstmalige Einrichtung

```bash
cd infra
terraform init -backend-config=backend.tfvars

export TF_VAR_subscription_id=<abo-id>
export TF_VAR_smart_planning_client_secret=<esarom-client-secret>

terraform plan
terraform apply
```

`subscription_id` und `smart_planning_client_secret` haben bewusst **keinen Standardwert**.
Ein leeres Smart-Planning-Secret bricht bereits im `plan` ab, statt eine Anwendung
auszurollen, die sich nicht authentifizieren kann.

In GitHub Actions heißt das Secret **`SMART_PLANNING_CLIENT_SECRET`**; im Container kommt es
als **`CLIENT_SECRET`** an. Es ist ausschließlich das ESAROM-Client-Secret — **kein**
Azure-Service-Principal-Secret.

---

## Was die Anwendung an Konfiguration bekommt

Die Container App erhält rund 35 Umgebungsvariablen. Sensible Werte laufen über Key-Vault-
Referenzen und die Managed Identity, nicht als Klartext.

### Azure OpenAI / Foundry

`AZURE_OPENAI_ENDPOINT` · `AZURE_OPENAI_API_KEY` · `AZURE_OPENAI_API_VERSION` ·
`AZURE_OPENAI_DEPLOYMENT` · `AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT`

Dazu je Agent ein eigener Satz — `AZURE_OPENAI_CHAT_*`, `_RAG_*`, `_ORCHESTRATION_*` mit
jeweils `ENDPOINT`, `KEY`, `API_VERSION`, `DEPLOYMENT`. Aktuell zeigen alle drei auf dasselbe
Deployment; die Trennung existiert, damit einzelne Agenten später ein anderes Modell bekommen
können, ohne dass am Code etwas geändert werden muss.

Verfügbare Deployments: `gpt-4.1`, `gpt-4o`, `gpt-4o-mini`, `gpt-5.1`, `gpt-5.2-chat`,
`text-embedding-3-small`.

### Datenbank

`DATABASE_URL` — vollständige SQLAlchemy-URL, aus dem Key Vault. Das Backend setzt sie NICHT
aus Einzelteilen zusammen und braucht **kein** separates SQL-Passwort. Das Passwort erzeugt
Terraform (`random_password`) und legt es als `SQL-ADMIN-PASSWORD` im Key Vault ab.

Das Container-Image muss den **Microsoft ODBC Driver 18** enthalten — ohne ihn startet der
Container zwar, scheitert aber bei der ersten Datenbankabfrage. Migrationen laufen im
Entrypoint des Images (`alembic upgrade head`) vor dem Start des Webservers.

### Speicher — zwei Container mit unterschiedlicher Rolle

| Variable | Wert | Inhalt |
|---|---|---|
| `AZURE_STORAGE_CONTAINER` | `snapshots` | Snapshot-Nutzdaten (JSON), von der Anwendung geschrieben |
| `AZURE_SKILLS_CONTAINER` | `skills` | **Lernkarten** — Konfiguration, von Menschen gepflegt |
| `RULEBOOK_SKILLS_PREFIX` | *(leer)* | Karten liegen direkt in der Wurzel ihres Containers |

Die Trennung ist Absicht: Lernkarten sind Konfiguration, keine Daten. Lägen sie im
Snapshot-Container, würde ein Aufräumen dort das Regelwerk mitlöschen.

**Der praktische Nutzen:** Eine Lernkarte im Portal zu bearbeiten ändert das Verhalten der
Korrektur-Pipeline sofort — ohne Deployment, ohne Zugriff auf das Anwendungs-Repository. Für
den Abgleich mit dem Repository gibt es dort `python -m tools.sync_skills`.

### Verhaltensschalter

| Variable | Standard | Bedeutung |
|---|---|---|
| `HUMAN_IN_THE_LOOP` | `true` | **Sicherheitsschalter.** `false` heißt: die KI wendet Korrekturen ohne menschliche Freigabe an. Nur mit ausdrücklicher Entscheidung umstellen. |
| `RULEBOOK_MODE` | `cards` | `cards` = Lernkarten aus dem Blob, `monolith` = die eine große Regeldatei aus dem Image |

Beide sind über `variables.tf` gesetzt und mit einem `validation`-Block abgesichert: ein
ungültiger Wert bricht im `plan` ab. **`terraform validate` prüft Variablenwerte nicht** —
dafür ist `terraform plan` nötig.

### Übrige

AI Search (`AZURE_SEARCH_ENDPOINT`, `_ADMIN_KEY`, `_INDEX`) · Speech (`AZURE_SPEECH_KEY`,
`_REGION`) · E-Mail (`NOTIFICATION_CHANNEL`, `ACS_CONNECTION_STRING`, `ACS_SENDER_EMAIL`,
`NOTIFICATION_RECIPIENT_EMAIL`) · `APP_BASE_URL` · `CLIENT_SECRET`

`ACS_SENDER_EMAIL` entsteht aus der von Azure verwalteten E-Mail-Domain und darf nirgends
fest codiert werden.

---

## Container App

Port 8000, Bindung an `0.0.0.0`, 0,5 CPU, 1 GiB, **min_replicas = 1** (kein Scale-to-Zero),
max_replicas = 1.

Aus `max_replicas = 1` folgt eine Einschränkung, die man kennen sollte: die
Korrektur-Pipeline ruft Skripte als Subprozess auf und läuft mehrere Minuten. Solange sie
läuft, belegt sie die einzige Instanz. Für regelmäßige Aufgaben eignen sich Container Apps
Jobs besser als Hintergrundthreads in der Anwendung.

---

## Deployment eines neuen Anwendungsstands

1. Im Anwendungs-Repository den Workflow **`deploy-backend`** starten und eine
   **neue Versionsnummer** angeben. Er baut aus `app/deploy/Dockerfile` mit Kontext `app/`
   und schiebt das Image in die ACR.
2. Hier `image_tag` in `terraform.tfvars` auf dieselbe Version setzen.
3. `terraform apply`.

> **Häufigste Fehlerquelle:** Wird Schritt 2 vergessen, zieht die Container App weiterhin das
> alte Image — der Deploy sieht erfolgreich aus, die Änderung fehlt trotzdem.

---

## Bekannte Baustellen

- **AI-Search-Index.** Terraform erzeugt den Search Service, aber **nicht** den Index
  `process-docs-index` und nicht dessen Dokumente. Bis beides angelegt ist, findet der
  RAG-Agent nichts. Der Free-SKU kann kein Semantic Ranking — beim Neuaufbau des Index also
  keine Semantic Configuration einbauen.
- **Dokumenten-Storage** (`saagenticaimfg/basic-ai-informations`) wird noch **nicht** als
  Umgebungsvariable an das Backend übergeben. Solange das fehlt, kann die Anwendung die PDFs
  weder lesen noch indizieren.
- **Kollation der SQL-Datenbank.** Ohne ausdrückliche Angabe gilt die Azure-Standardkollation;
  `VARCHAR`/`TEXT`-Spalten speichern dann nur CP1252. Deutsche Umlaute sind darin enthalten,
  Zeichen wie „→" oder Emoji nicht — die würden still zu „?". Solange die Datenbank leer ist,
  kostet eine UTF-8-Kollation eine Zeile.
- **Nach jedem `apply`, der Ressourcen neu anlegt oder Schlüssel rotiert**, sind lokale
  `.env`-Dateien im Anwendungs-Repository veraltet. Symptom: HTTP 401 mit der Meldung
  „invalid subscription key or wrong API endpoint" — obwohl der Endpunkt stimmt.

---

## Hinweise für Änderungen

- **Container niemals von Hand anlegen.** Die Anwendung erzeugt fehlende Blob-Container
  selbsttätig. Existiert ein Container bereits, scheitert `terraform apply` mit einem
  Konflikt. Abhilfe: `terraform import azurerm_storage_container.<name> <blob-url>`.
- **`terraform plan` statt `validate`** zum Prüfen von Variablenwerten.
- Sensible Werte gehören in den Key Vault und werden über Referenzen eingebunden, nicht als
  Klartext in `terraform.tfvars`.
