variable "resource_group_name" {
  description = "CKA training"
  type        = string
}

variable "location" {
  description = "Location for the resource group"
  type        = string
  default     = "eastus"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

output "name" {
  value = var.resource_group_name
}

output "location" {
  value = var.location
}

output "resource_group" {
  value = azurerm_resource_group.example
}
