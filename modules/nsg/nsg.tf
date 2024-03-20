variable "nsg_name" {
  description = "Name of the NSG"
  type        = string
  default     = "myNSG"
}

variable "azurerm_resource_group_name" {}
variable "azurerm_resource_group_location" {}

resource "azurerm_network_security_group" "example" {
  name                = var.nsg_name
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubernetesPorts"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6443", "10250-10255", "30000-32767", "2379-2380"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
