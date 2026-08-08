# ---------------------------------------------------------------------------
# Netzwerk fuer die Anbindung an Smart Planning (ESAROM)
# ---------------------------------------------------------------------------
# Zweck: Die Container App muss die Smart-Planning-VM erreichen
#   vm-t-weu-ccadmm-idp-test02.internal.idp.cca-dev.com -> 10.112.19.8
# Die VM hat KEINE oeffentliche IP und liegt in einer anderen Subscription
# (subscr-ccadmm-idp, 40e08bde-e349-4ac5-8299-6c6e2f5c33f6) im VNet
# vnet-t-weu-ccadmm-idp (10.112.16.0/22, westeurope).
#
# Ohne VNet-Integration geht die Container App ausschliesslich ueber die
# geteilte Azure-Egress ins oeffentliche Internet und hat damit KEINEN Weg
# in ein privates Netz. Dieses File schafft die DEV-seitige Voraussetzung.
#
# ABGRENZUNG — was hier bewusst NICHT steht:
#   * Das VNet-Peering (beide Richtungen)
#   * Der Private-DNS-Zonen-Link
# Beides wird MANUELL im Portal mit dem Benutzerkonto angelegt. Grund:
# Azure verlangt fuer das Anlegen eines Peerings die Berechtigung
# Microsoft.Network/virtualNetworks/peer/action auf dem ZIEL-VNet. Selbst die
# DEV-seitige Haelfte braucht also eine Rolle in der IDP-Subscription. Damit
# die Deploy-Identity keine einzige Berechtigung ausserhalb von DEV bekommt,
# bleiben diese Schritte manuell. Siehe docs/NETWORK_SETUP.md.
# ---------------------------------------------------------------------------

# ACHTUNG — STILLE FALLE:
# Peering und DNS-Link sind NICHT in diesem Terraform-State. Wird dieses VNet
# jemals ersetzt (z.B. durch eine Aenderung des Adressraums), verschwinden
# beide, ohne dass Terraform es meldet. Die Container App verliert dann
# wortlos die Verbindung zu Smart Planning. Nach jedem Ersetzen dieses VNets
# muessen die drei manuellen Schritte erneut ausgefuehrt werden.
resource "azurerm_virtual_network" "main" {
  name                = "${var.vnet_name}-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet_address_space]
  tags                = local.common_tags

  # KEINE dns_servers setzen. Die Namensaufloesung von
  # *.internal.idp.cca-dev.com laeuft ueber einen Private-DNS-Zonen-Link
  # (manueller Schritt 3), und der greift NUR bei Azure-eigenem DNS.
  # Ein custom DNS-Server hier wuerde den Link wirkungslos machen.
}

# Infrastruktur-Subnetz der Container App Environment.
#
# Groesse /23: Workload-Profile-Environments verlangen mindestens /27. Der
# grosszuegigere /23-Zuschnitt bleibt bestehen — er kostet nichts und deckt
# auch eine spaetere Consumption-only Environment ab.
#
# Das Subnetz gehoert EXKLUSIV der Environment. Hier darf nichts anderes rein.
resource "azurerm_subnet" "cae" {
  name                 = var.cae_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.cae_subnet_prefix]

  # PFLICHT — nachgetragen am 04.08.2026, nachdem der erste Apply hier scheiterte:
  #   ManagedEnvironmentSubnetDelegationError: The subnet of the environment
  #   must be delegated to the service 'Microsoft.App/environments'.
  #
  # Azure laesst eine VNet-integrierte Environment ohne diese Delegation nicht
  # zu. Die urspruengliche Annahme, eine Consumption-only Environment komme
  # ohne Delegation aus, war fuer diesen Weg falsch. Konsequenz in main.tf:
  # die Environment wird eine Workload-Profiles-Environment — mit AUSSCHLIESSLICH
  # dem Profil "Consumption", die Abrechnung bleibt also verbrauchsbasiert.
  delegation {
    name = "Microsoft.App-environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
