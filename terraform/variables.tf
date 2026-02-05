variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to create."
  default     = "rg-insecure-test"
}

variable "location" {
  type        = string
  description = "The Azure location where resources should be created."
  default     = "australiaeast"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account. Must be globally unique."
  default     = "stinsecuretest001"
}

variable "account_tier" {
  type        = string
  description = "Defines the Tier to use for this storage account."
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  description = "Defines the type of replication to use for this storage account."
  default     = "LRS"
}

variable "account_kind" {
  type        = string
  description = "Defines the Kind of account."
  default     = "StorageV2"
}

variable "access_tier" {
  type        = string
  description = "Defines the access tier for the storage account."
  default     = "Hot"
}

variable "containers" {
  type = map(object({
    name                  = string
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
  }))
  description = "Map of blob containers to create."
  default = {
    public_data = {
      name                  = "public-data"
      container_access_type = "blob" # Public read access for blobs (insecure)
    }
  }
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to resources."
  default = {
    Environment = "Testing"
    Security    = "Insecure"
    Purpose     = "Testing-Only"
  }
}
