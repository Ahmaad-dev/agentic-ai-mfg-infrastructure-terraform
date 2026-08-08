# Anbindung der Container App an Smart Planning (ESAROM)

Stand 2026-08-04.

Ziel: Die Container App in der DEV-Subscription erreicht die Smart-Planning-VM
`vm-t-weu-ccadmm-idp-test02.internal.idp.cca-dev.com` (`10.112.19.8`).
Die VM hat **keine öffentliche IP** und liegt in einer anderen Subscription.

---

## Die Ausgangslage

```
vnet-agentic-ai-mfg-<suffix>   10.113.0.0/22    swedencentral
  └─ snet-cae-infrastructure   10.113.0.0/23    ← Container App Environment
        │
        │  (2 Peerings, manuell — Schritt 2+3)
        ▼
vnet-t-weu-ccadmm-idp          10.112.16.0/22   westeurope
  └─ vm-t-weu-ccadmm-idp-test02  →  10.112.19.8   (keine Public IP)

Private DNS Zone  internal.idp.cca-dev.com
  in  rg-p-weu-ccadmm-hub-dns,  Sub 9b942b89-…      ← Link, manuell (Schritt 4)
```

Der Hub `vnet-p-weu-ccadmm-hub` bleibt **außen vor**. Er bedient weiterhin nur
das lokale P2S-VPN. Das Peering geht direkt von Spoke zu Spoke.

### Subscriptions

| Rolle | Name | ID |
|---|---|---|
| DEV (Terraform) | `subscr-s-ccadm-dev` | `17b4807c-05a1-4c15-b35e-1a6b20bc37b3` |
| IDP (VM) | `subscr-ccadmm-idp` | `40e08bde-e349-4ac5-8299-6c6e2f5c33f6` |
| Hub (DNS-Zone) | — | `9b942b89-e1d1-454e-a11c-18531063ef2d` |

---

## Warum drei Schritte manuell sind

Azure verlangt zum Anlegen eines Peerings die Berechtigung
`Microsoft.Network/virtualNetworks/peer/action` auf dem **Ziel**-VNet.
Auch die DEV-seitige Hälfte des Peerings bräuchte also eine Rolle in der
IDP-Subscription.

Damit die Deploy-Identity **keine einzige Berechtigung außerhalb von DEV**
erhält, werden Peering und DNS-Link manuell mit dem Benutzerkonto angelegt.

> **Zur Laufzeit berührt die Managed Identity die IDP-Subscription ohnehin nie.**
> ACR, Key Vault und Azure OpenAI liegen in DEV; die Anmeldung an ESAROM läuft
> über Keycloak mit `SMART_PLANNING_CLIENT_SECRET`, nicht über Entra ID.
> Netzwerkverkehr braucht keine Azure-Berechtigung.

---

## Reihenfolge — zwingend

Das VNet muss existieren, bevor gepeert werden kann. Andersherum geht es nicht.

### Schritt 1 — Terraform (automatisch, DEV)

```bash
cd infra
terraform plan     # ZUERST LESEN, siehe Warnung unten
terraform apply
```

> **Der Plan wird die Container App Environment und die Container App zum
> Ersetzen vorschlagen.** Das ist beabsichtigt: `infrastructure_subnet_id` ist
> unveränderlich und nur bei der Erstellung setzbar. Es gibt keinen Weg, die
> VNet-Integration nachzurüsten.
>
> **Folge: die Backend-FQDN ändert sich.** Es entsteht eine kurze Nichtverfüg-
> barkeit. Prüfe im Plan, dass **nur** `azurerm_container_app_environment.cae`
> und `azurerm_container_app.api` ersetzt werden — SQL, Key Vault, Storage und
> ACR dürfen **nicht** in der Ersetzungsliste stehen.

Danach die Ausgabe `network_manual_steps` ablesen:

```bash
terraform output network_manual_steps
```

Daraus brauchst du `vnet_name` und `vnet_resource_group` für die nächsten Schritte.

---

### Schritt 2 — Peering DEV → IDP (manuell, Portal)

Portal → **Virtuelle Netzwerke** → `vnet-agentic-ai-mfg-<suffix>` → **Peerings** → **Hinzufügen**

| Feld | Wert |
|---|---|
| Name dieses Peerings | `peer-agenticai-to-idp` |
| Bereitstellungsmodell | Resource Manager |
| Abonnement | `subscr-ccadmm-idp` |
| Virtuelles Netzwerk | `vnet-t-weu-ccadmm-idp` |
| Zugriff zulassen | **Ja** |
| Weitergeleiteten Datenverkehr zulassen | Nein |
| Gatewaytransit / Remote Gateways | **Nein** |

Das Portal legt beim Anlegen üblicherweise **beide Richtungen zugleich** an,
sofern dein Konto in beiden Subscriptions schreiben darf — das ist hier der
Fall. Prüfe danach trotzdem Schritt 3.

**Wichtig zu „Remote Gateways": auf Nein lassen.** Das IDP-VNet nutzt das
Hub-Gateway für dein VPN. Ein zweiter Gateway-Bezug würde kollidieren.

---

### Schritt 3 — Gegenrichtung IDP → DEV prüfen (manuell, Portal)

Portal → `vnet-t-weu-ccadmm-idp` (Sub `subscr-ccadmm-idp`) → **Peerings**

Es muss ein Eintrag auf `vnet-agentic-ai-mfg-<suffix>` zeigen, Status
**Verbunden / Connected**.

> **Ein einseitiges Peering trägt keinen Verkehr.** Steht dort `Initiated`
> statt `Connected`, fehlt die Gegenrichtung — dann hier von Hand anlegen,
> mit denselben Einstellungen wie in Schritt 2.

Das bestehende Peering zum Hub bleibt unangetastet.

---

### Schritt 4 — Private-DNS-Zonen-Link (manuell, Portal)

Portal → Subscription `9b942b89-…` → Ressourcengruppe `rg-p-weu-ccadmm-hub-dns`
→ Private DNS-Zone **`internal.idp.cca-dev.com`**
→ **Verknüpfungen virtueller Netzwerke** → **Hinzufügen**

| Feld | Wert |
|---|---|
| Linkname | `link-agentic-ai-mfg` |
| Abonnement | `subscr-s-ccadm-dev` |
| Virtuelles Netzwerk | `vnet-agentic-ai-mfg-<suffix>` |
| Automatische Registrierung | **AUS** |

**Automatische Registrierung muss aus bleiben** — sonst würden sich Ressourcen
aus deinem VNet in eine fremde, produktive DNS-Zone eintragen.

Der Vorgang ist rein additiv; die bestehende Verknüpfung bleibt unberührt.

---

## Verifikation

### a) Netzwerkpfad

Portal → Container App → **Konsole**, oder per Log:

```bash
# Namensauflösung — muss 10.112.19.8 liefern
python -c "import socket; print(socket.gethostbyname('vm-t-weu-ccadmm-idp-test02.internal.idp.cca-dev.com'))"
```

Liefert das einen Fehler, ist **Schritt 4** die Ursache, nicht das Peering.
Liefert es die richtige IP, aber die Verbindung läuft in einen Timeout, ist es
**Schritt 2/3**.

### b) Fachlicher Nachweis

Ein echter Aufruf gegen ESAROM aus der Container App — am ehrlichsten über die
Anwendung selbst: einen Snapshot validieren lassen. Erst wenn eine
Validierungsmeldung vom Server zurückkommt, ist die Kette bewiesen.

### c) Frontend nachziehen

Nach dem Apply zeigt die Static Web App noch auf die **alte** Backend-URL.
`deploy-frontend.yml` einmal laufen lassen — der Workflow ersetzt
`BACKEND_URL_PLACEHOLDER` in `app/ui/scripts/config.js`.

---

## Die stille Falle

Peering und DNS-Link liegen **nicht** im Terraform-State.

Wird das VNet jemals ersetzt — etwa durch eine Änderung von
`vnet_address_space` —, verschwinden beide **ohne Meldung**. Terraform
berichtet Erfolg, und die Container App verliert wortlos die Verbindung zu
Smart Planning.

**Nach jedem Ersetzen des VNets sind die Schritte 2 bis 4 zu wiederholen.**

---

## Kosten

| Position | Kosten |
|---|---|
| VNet, Subnetz | 0 € |
| Peering-Verbindung | 0 € |
| Peering-Datenverkehr (global, swedencentral ↔ westeurope) | pro GB, beide Richtungen |
| Private-DNS-Zonen-Link | 0 € |
| VPN Gateway, Firewall, NAT Gateway | entfallen |

Snapshots liegen bei ~5,7 MB. Selbst tausend Übertragungen im Monat sind ~6 GB
— Centbereich. Die dominierende Position bleibt `min_replicas = 1` mit
0,5 vCPU / 1 GiB rund um die Uhr, und die ist von diesem Umbau **nicht**
betroffen.

**Geklärt am 04.08.2026:** Azure erzwingt für eine VNet-integrierte Environment
die Subnetz-Delegation an `Microsoft.App/environments` — der erste Apply
scheiterte daran (`ManagedEnvironmentSubnetDelegationError`). Ein delegiertes
Subnetz bedingt eine **Workload-Profiles-Environment**. Sie enthält hier
ausschließlich das Profil `Consumption` und **kein Dedicated-Profil**, die
Abrechnung bleibt damit verbrauchsbasiert.

> Wer ein Dedicated-Profil ergänzt, ändert das Kostenmodell: es wird rund um die
> Uhr pro Instanz berechnet, unabhängig von der Auslastung.

---

## Wenn etwas schiefgeht

| Symptom | Ursache |
|---|---|
| `terraform apply` scheitert mit Berechtigungsfehler auf ein VNet in IDP | Es wurde versehentlich eine Peering-Ressource in Terraform aufgenommen. Gehört ins Portal. |
| DNS löst nicht auf | Schritt 4 fehlt — oder am VNet wurden `dns_servers` gesetzt. Private-DNS-Links greifen nur bei Azure-eigenem DNS. |
| DNS ok, Verbindung im Timeout | Peering einseitig (`Initiated` statt `Connected`) → Schritt 3. |
| Weboberfläche nicht mehr erreichbar | `internal_load_balancer_enabled` steht auf `true`. Muss `false` sein. |
| Frontend zeigt Fehler nach dem Apply | Alte Backend-URL. `deploy-frontend.yml` laufen lassen. |
