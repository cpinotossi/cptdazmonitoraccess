# ==============================================================================
# Multi-Tenant Log Analytics Access Control Demo
# ==============================================================================

# ==============================================================================
# Automatische IP-Ermittlung
# ==============================================================================
# Ermittelt die aktuelle öffentliche IP-Adresse, falls keine IPs übergeben werden.
# ==============================================================================

data "http" "my_public_ip" {
  url = "https://ifconfig.io/ip"
}

locals {
  # Verwende übergebene IPs, oder ermittle automatisch die aktuelle IP
  allowed_ip_addresses = length(var.allowed_ip_addresses) > 0 ? var.allowed_ip_addresses : [trimspace(data.http.my_public_ip.response_body)]
}

# ==============================================================================
# CENTRAL SUBSCRIPTION - Log Analytics Workspace
# ==============================================================================

resource "azurerm_resource_group" "central" {
  provider = azurerm.central
  name     = var.central_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "central" {
  provider            = azurerm.central
  name                = var.law_name
  location            = azurerm_resource_group.central.location
  resource_group_name = azurerm_resource_group.central.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# ==============================================================================
# CRITICAL: Enable Resource-Context Access Control
# ==============================================================================
# This is the key setting that enables per-resource log access!
# When enabled, users can only see logs from resources they have 
# Azure RBAC read permissions on.
# ==============================================================================

resource "azurerm_resource_group_template_deployment" "law_access_control" {
  provider            = azurerm.central
  name                = "law-access-control-config"
  resource_group_name = azurerm_resource_group.central.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    resources = [
      {
        type       = "Microsoft.OperationalInsights/workspaces"
        apiVersion = "2022-10-01"
        name       = azurerm_log_analytics_workspace.central.name
        location   = var.location
        properties = {
          sku = {
            name = "PerGB2018"
          }
          retentionInDays = 30
          features = {
            # THIS IS THE KEY SETTING!
            # true = Resource-context (users see only their resource logs)
            # false = Workspace-context (users see all logs if they have workspace access)
            # https://learn.microsoft.com/en-us/azure/azure-monitor/logs/manage-access?tabs=portal#access-mode
            enableLogAccessUsingOnlyResourcePermissions = true
          }
        }
      }
    ]
  })

  depends_on = [azurerm_log_analytics_workspace.central]
}

# ==============================================================================
# USER1 SUBSCRIPTION - Storage Account
# ==============================================================================

resource "azurerm_resource_group" "user1" {
  provider = azurerm.user1
  name     = var.user1_resource_group_name
  location = var.location
  tags     = merge(var.tags, { Owner = "User1" })
}

resource "azurerm_storage_account" "user1" {
  provider                        = azurerm.user1
  name                            = "cptdazmonlogaccess1"
  resource_group_name             = azurerm_resource_group.user1.name
  location                        = azurerm_resource_group.user1.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = true

  # Netzwerk-Regeln: Nur erlaubte IPs können zugreifen
  network_rules {
    default_action             = "Deny"
    ip_rules                   = local.allowed_ip_addresses
    bypass                     = ["AzureServices"]  # Erlaube Azure-interne Dienste (z.B. Diagnostics)
  }

  tags = merge(var.tags, { Owner = "User1" })
}

# NOTE: Blob containers are created via Data Plane operations (Notebook)

# Diagnostic settings - send Storage Account logs to central LAW
resource "azurerm_monitor_diagnostic_setting" "user1_storage" {
  provider                   = azurerm.user1
  name                       = "send-to-central-law"
  target_resource_id         = azurerm_storage_account.user1.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  # Storage Account metrics
  metric {
    category = "Transaction"
    enabled  = true
  }

  # Note: For blob-specific logs, you need to target the blob service
  # target_resource_id = "${azurerm_storage_account.user1.id}/blobServices/default"
}

# Diagnostic settings for Blob service specifically
resource "azurerm_monitor_diagnostic_setting" "user1_blob" {
  provider                   = azurerm.user1
  name                       = "blob-to-central-law"
  target_resource_id         = "${azurerm_storage_account.user1.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# ==============================================================================
# USER2 SUBSCRIPTION - Storage Account
# ==============================================================================

resource "azurerm_resource_group" "user2" {
  provider = azurerm.user2
  name     = var.user2_resource_group_name
  location = var.location
  tags     = merge(var.tags, { Owner = "User2" })
}

resource "azurerm_storage_account" "user2" {
  provider                        = azurerm.user2
  name                            = "cptdazmonlogaccess2"
  resource_group_name             = azurerm_resource_group.user2.name
  location                        = azurerm_resource_group.user2.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = true

  # Netzwerk-Regeln: Nur erlaubte IPs können zugreifen
  network_rules {
    default_action             = "Deny"
    ip_rules                   = local.allowed_ip_addresses
    bypass                     = ["AzureServices"]  # Erlaube Azure-interne Dienste (z.B. Diagnostics)
  }

  tags = merge(var.tags, { Owner = "User2" })
}

# NOTE: Blob containers are created via Data Plane operations (Notebook)

# Diagnostic settings - send Storage Account logs to central LAW
resource "azurerm_monitor_diagnostic_setting" "user2_storage" {
  provider                   = azurerm.user2
  name                       = "send-to-central-law"
  target_resource_id         = azurerm_storage_account.user2.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# Diagnostic settings for Blob service specifically
resource "azurerm_monitor_diagnostic_setting" "user2_blob" {
  provider                   = azurerm.user2
  name                       = "blob-to-central-law"
  target_resource_id         = "${azurerm_storage_account.user2.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# ==============================================================================
# RBAC ASSIGNMENTS - Key for Resource-Context Access Control
# ==============================================================================
# Each user gets Reader access ONLY on their own resources.
# They do NOT get any workspace-level permissions!
# ==============================================================================

# User1: Reader on their Storage Account
resource "azurerm_role_assignment" "user1_storage_reader" {
  provider             = azurerm.user1
  scope                = azurerm_storage_account.user1.id
  role_definition_name = "Reader"
  principal_id         = var.user1_principal_id
}

# User1: Reader on their Resource Group (optional, for better portal experience)
resource "azurerm_role_assignment" "user1_rg_reader" {
  provider             = azurerm.user1
  scope                = azurerm_resource_group.user1.id
  role_definition_name = "Reader"
  principal_id         = var.user1_principal_id
}

# User2: Reader on their Storage Account
resource "azurerm_role_assignment" "user2_storage_reader" {
  provider             = azurerm.user2
  scope                = azurerm_storage_account.user2.id
  role_definition_name = "Reader"
  principal_id         = var.user2_principal_id
}

# User2: Reader on their Resource Group (optional, for better portal experience)
resource "azurerm_role_assignment" "user2_rg_reader" {
  provider             = azurerm.user2
  scope                = azurerm_resource_group.user2.id
  role_definition_name = "Reader"
  principal_id         = var.user2_principal_id
}

# ==============================================================================
# OPTIONAL: Minimal LAW permissions for workspace enumeration only
# ==============================================================================
# If users need to see the workspace in the portal (not via resource context),
# they need minimal read permissions. This does NOT grant log access!
# ==============================================================================

# Custom role for minimal workspace access (read workspace, no log access)
resource "azurerm_role_definition" "law_minimal_reader" {
  count       = var.enable_law_minimal_access ? 1 : 0
  provider    = azurerm.central
  name        = "Log Analytics Minimal Reader"
  scope       = azurerm_resource_group.central.id
  description = "Can view workspace properties but cannot read any log data"

  permissions {
    actions = [
      "Microsoft.OperationalInsights/workspaces/read"
    ]
    not_actions = [
      "Microsoft.OperationalInsights/workspaces/query/*",
      "Microsoft.OperationalInsights/workspaces/sharedKeys/read"
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.central.id
  ]
}

# Assign minimal LAW access to User1
resource "azurerm_role_assignment" "user1_law_minimal" {
  count              = var.enable_law_minimal_access ? 1 : 0
  provider           = azurerm.central
  scope              = azurerm_log_analytics_workspace.central.id
  role_definition_id = azurerm_role_definition.law_minimal_reader[0].role_definition_resource_id
  principal_id       = var.user1_principal_id
}

# Assign minimal LAW access to User2
resource "azurerm_role_assignment" "user2_law_minimal" {
  count              = var.enable_law_minimal_access ? 1 : 0
  provider           = azurerm.central
  scope              = azurerm_log_analytics_workspace.central.id
  role_definition_id = azurerm_role_definition.law_minimal_reader[0].role_definition_resource_id
  principal_id       = var.user2_principal_id
}

# ==============================================================================
# SERVICE PRINCIPAL DATA PLANE ACCESS
# ==============================================================================
# Storage Blob Data Contributor für Data Plane Operationen im Notebook
# ==============================================================================

resource "azurerm_role_assignment" "sp1_storage_blob_contributor" {
  provider             = azurerm.user1
  scope                = azurerm_storage_account.user1.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user1_principal_id
}

resource "azurerm_role_assignment" "sp2_storage_blob_contributor" {
  provider             = azurerm.user2
  scope                = azurerm_storage_account.user2.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user2_principal_id
}

# ==============================================================================
# PORTAL USERS - RBAC Assignments (für Tests via Azure Portal)
# ==============================================================================

# Portal User1 → Reader auf User1's Storage Account
resource "azurerm_role_assignment" "portal_user1_storage_reader" {
  count                = var.portal_user1_object_id != "" ? 1 : 0
  provider             = azurerm.user1
  scope                = azurerm_storage_account.user1.id
  role_definition_name = "Reader"
  principal_id         = var.portal_user1_object_id
}

# Portal User2 → Reader auf User2's Storage Account
resource "azurerm_role_assignment" "portal_user2_storage_reader" {
  count                = var.portal_user2_object_id != "" ? 1 : 0
  provider             = azurerm.user2
  scope                = azurerm_storage_account.user2.id
  role_definition_name = "Reader"
  principal_id         = var.portal_user2_object_id
}
