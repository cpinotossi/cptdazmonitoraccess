# ==============================================================================
# Variables for Multi-Tenant Log Analytics Access Control Demo
# ==============================================================================

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    Purpose     = "LAW-Access-Control-Test"
    ManagedBy   = "Terraform"
  }
}

# ==============================================================================
# Subscription IDs
# ==============================================================================

variable "central_subscription_id" {
  description = "Subscription ID for central Log Analytics Workspace"
  type        = string
  default     = "4b353dc5-a216-485d-8f77-a0943546b42c"
}

variable "user1_subscription_id" {
  description = "Subscription ID for User1's resources"
  type        = string
  default     = "d3856ecd-977c-4651-ab8a-8208fe79dfac"
}

variable "user2_subscription_id" {
  description = "Subscription ID for User2's resources"
  type        = string
  default     = "a2745aeb-191e-4edf-8971-8c51691259c4"
}

# ==============================================================================
# Service Principal Object IDs (for RBAC assignments)
# ==============================================================================

variable "user1_principal_id" {
  description = "Object ID of User1's Service Principal"
  type        = string
}

variable "user2_principal_id" {
  description = "Object ID of User2's Service Principal"
  type        = string
}

# ==============================================================================
# Resource naming
# ==============================================================================

variable "central_resource_group_name" {
  description = "Resource group name for central LAW"
  type        = string
  default     = "rg-central-monitoring"
}

variable "law_name" {
  description = "Name of the central Log Analytics Workspace"
  type        = string
  default     = "law-central-shared"
}

variable "user1_resource_group_name" {
  description = "Resource group name for User1's resources"
  type        = string
  default     = "rg-user1-resources"
}

variable "user2_resource_group_name" {
  description = "Resource group name for User2's resources"
  type        = string
  default     = "rg-user2-resources"
}

# ==============================================================================
# Portal Users (für Tests via Azure Portal)
# ==============================================================================

variable "portal_user1_object_id" {
  description = "Object ID of Portal User 1 (for Reader access on User1's Storage)"
  type        = string
  default     = ""
}

variable "portal_user2_object_id" {
  description = "Object ID of Portal User 2 (for Reader access on User2's Storage)"
  type        = string
  default     = ""
}

# ==============================================================================
# Optional Features
# ==============================================================================

variable "enable_law_minimal_access" {
  description = "Enable minimal LAW permissions for workspace enumeration. When false, users can only access logs via Storage Account context."
  type        = bool
  default     = false
}

variable "allowed_ip_addresses" {
  description = "List of public IP addresses allowed to access the Storage Accounts"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Service Principal Credentials (for Notebook tests only)
# ==============================================================================
# These are NOT used by Terraform, only by the Jupyter Notebook
# for testing log access with Service Principals.
# ==============================================================================

variable "tenant_id" {
  description = "Azure AD Tenant ID (used by Notebook for SP login)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sp1_client_id" {
  description = "Service Principal 1 Client/App ID (used by Notebook for SP login)"
  type        = string
  default     = ""
}

variable "sp1_client_secret" {
  description = "Service Principal 1 Client Secret (used by Notebook for SP login)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sp2_client_id" {
  description = "Service Principal 2 Client/App ID (used by Notebook for SP login)"
  type        = string
  default     = ""
}

variable "sp2_client_secret" {
  description = "Service Principal 2 Client Secret (used by Notebook for SP login)"
  type        = string
  default     = ""
  sensitive   = true
}
