# ==============================================================================
# Outputs
# ==============================================================================

output "central_law" {
  description = "Central Log Analytics Workspace details"
  value = {
    id                 = azurerm_log_analytics_workspace.central.id
    name               = azurerm_log_analytics_workspace.central.name
    resource_group     = azurerm_resource_group.central.name
    subscription_id    = var.central_subscription_id
    workspace_id       = azurerm_log_analytics_workspace.central.workspace_id
    primary_shared_key = nonsensitive(azurerm_log_analytics_workspace.central.primary_shared_key)
  }
  sensitive = true
}

output "user1_resources" {
  description = "User1's resources"
  value = {
    storage_account_id   = azurerm_storage_account.user1.id
    storage_account_name = azurerm_storage_account.user1.name
    resource_group       = azurerm_resource_group.user1.name
    subscription_id      = var.user1_subscription_id
    blob_endpoint        = azurerm_storage_account.user1.primary_blob_endpoint
  }
}

output "user2_resources" {
  description = "User2's resources"
  value = {
    storage_account_id   = azurerm_storage_account.user2.id
    storage_account_name = azurerm_storage_account.user2.name
    resource_group       = azurerm_resource_group.user2.name
    subscription_id      = var.user2_subscription_id
    blob_endpoint        = azurerm_storage_account.user2.primary_blob_endpoint
  }
}

output "test_instructions" {
  description = "Instructions for testing the access control"
  value       = <<-EOT

    ============================================================================
    TEST INSTRUCTIONS - Resource-Context Log Analytics Access Control
    ============================================================================

    1. GENERATE TEST LOGS
       ------------------
       Upload files to each storage account to generate logs:

       # As User1:
       az storage blob upload --account-name ${azurerm_storage_account.user1.name} \
         --container-name testcontainer --name test1.txt --data "Hello from User1"

       # As User2:
       az storage blob upload --account-name ${azurerm_storage_account.user2.name} \
         --container-name testcontainer --name test2.txt --data "Hello from User2"

    2. WAIT FOR LOGS
       --------------
       Wait 5-10 minutes for logs to appear in Log Analytics.

    3. TEST ACCESS AS USER1
       ---------------------
       Login as User1's Service Principal and query logs:

       # Option A: Query via Resource Context (recommended)
       az monitor log-analytics query \
         --workspace ${azurerm_log_analytics_workspace.central.workspace_id} \
         --analytics-query "StorageBlobLogs | take 10"

       # User1 should ONLY see logs from: ${azurerm_storage_account.user1.name}

    4. TEST ACCESS AS USER2
       ---------------------
       Login as User2's Service Principal and query logs:

       # User2 should ONLY see logs from: ${azurerm_storage_account.user2.name}

    5. VERIFY ISOLATION
       -----------------
       Run this KQL query to check _ResourceId filtering:

       StorageBlobLogs
       | summarize count() by _ResourceId
       | order by count_ desc

       Each user should only see their own _ResourceId in results!

    ============================================================================
  EOT
}

output "kql_test_queries" {
  description = "KQL queries for testing"
  value = {
    all_storage_logs      = "StorageBlobLogs | take 100"
    logs_by_resource      = "StorageBlobLogs | summarize count() by _ResourceId"
    user1_resource_id     = azurerm_storage_account.user1.id
    user2_resource_id     = azurerm_storage_account.user2.id
    verify_access_control = <<-EOT
      // This query shows which resources the current user can see
      StorageBlobLogs
      | summarize 
          LogCount = count(),
          FirstLog = min(TimeGenerated),
          LastLog = max(TimeGenerated)
        by _ResourceId
      | extend ResourceName = split(_ResourceId, "/")[-1]
    EOT
  }
}
