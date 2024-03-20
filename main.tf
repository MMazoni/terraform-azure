provider "azurerm" {
  features {}
}

module "resource_group" {
  source              = "./modules/resource_group"
  resource_group_name = var.resource_group_name
}

module "network" {
  source                          = "./modules/network"
  vnet_name                       = var.vnet_name
  subnet_name                     = var.subnet_name
  address_space                   = var.address_space
  azurerm_resource_group_location = module.resource_group.location
  azurerm_resource_group_name     = module.resource_group.name
}

module "nsg" {
  source                          = "./modules/nsg"
  nsg_name                        = var.nsg_name
  azurerm_resource_group_location = module.resource_group.location
  azurerm_resource_group_name     = module.resource_group.name
}

module "virtual_machines" {
  source                          = "./modules/vm"
  vm_count                        = var.vm_count
  azurerm_resource_group_location = module.resource_group.location
  azurerm_resource_group_name     = module.resource_group.name
  azurerm_subnet_id               = module.network.subnet_id
  resource_group                  = module.resource_group.resource_group
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "myResourceGroup"
}

variable "vnet_name" {
  description = "Name of the VNet"
  default     = "myVNet"
}

variable "subnet_name" {
  description = "Name of the Subnet"
  default     = "mySubnet"
}

variable "address_space" {
  description = "Address space for the VNet"
  default     = ["10.0.0.0/16"]
}

variable "nsg_name" {
  description = "Name of the NSG"
  default     = "myNSG"
}

variable "vm_count" {
  description = "Number of VMs to create"
  default     = 1
}

output "ssh_username" {
  value = module.virtual_machines.ssh_username
}

output "control_plane_ips" {
  value = module.virtual_machines.control_plane_ips
}

output "worker_ips" {
  value = module.virtual_machines.worker_ips
}
