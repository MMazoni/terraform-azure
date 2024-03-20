# Module: ssh_public_key.tf

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Default location for SSH public key
}

variable "azurerm_resource_group_name" {}
variable "azurerm_resource_group_location" {}
variable "azurerm_subnet_id" {}
variable "resource_group" {}

resource "azurerm_ssh_public_key" "example" {
  name                = "exampleSSHKey"
  resource_group_name = var.azurerm_resource_group_name
  location            = var.azurerm_resource_group_location
  public_key          = file(var.ssh_public_key_path)
  depends_on          = [var.resource_group]
}


variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "vm_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "vm"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_username" {
  description = "Username for SSH access"
  type        = string
  default     = "sshuser"
}

resource "azurerm_linux_virtual_machine" "control_plane" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-control-plane-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name
  size                = var.vm_size
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_username = var.ssh_username
  admin_ssh_key {
    username   = var.ssh_username
    public_key = azurerm_ssh_public_key.example.public_key
  }
  network_interface_ids = [azurerm_network_interface.control_plane[count.index].id]
  source_image_reference {
    publisher = "Canonical"
	offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  provisioner "file" {
    source      = "modules/vm/install cluster.sh"
    destination = "/tmp/install_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_cluster.sh",
      "/tmp/install_cluster.sh"
    ]
  }

  connection {
    type     = "ssh"
    user     = var.ssh_username
    private_key = file("~/.ssh/id_rsa")
    host     = self.public_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "worker" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-worker-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name
  size                = var.vm_size
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_username = var.ssh_username
  admin_ssh_key {
    username   = var.ssh_username
    public_key = azurerm_ssh_public_key.example.public_key
  }
  network_interface_ids = [azurerm_network_interface.worker[count.index].id]
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  provisioner "file" {
    source      = "modules/vm/install cluster.sh"
    destination = "/tmp/install_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_cluster.sh",
      "/tmp/install_cluster.sh"
    ]
  }

  connection {
    type     = "ssh"
    user     = var.ssh_username
    private_key = file("~/.ssh/id_rsa")
    host     = self.public_ip_address
  }
}

resource "azurerm_network_interface" "control_plane" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-control-plane-nic-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name

  ip_configuration {
    name                          = "${var.vm_prefix}-control-plane-ipconfig-${count.index}"
    subnet_id                     = var.azurerm_subnet_id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = azurerm_public_ip.control_plane[count.index].id
  }
  lifecycle {
	create_before_destroy = true
  }
}

resource "azurerm_network_interface" "worker" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-worker-nic-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name

  ip_configuration {
    name                          = "${var.vm_prefix}-worker-ipconfig-${count.index}"
    subnet_id                     = var.azurerm_subnet_id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id		  = azurerm_public_ip.worker[count.index].id
  }
  lifecycle {
	create_before_destroy = true
  }
}

resource "azurerm_public_ip" "control_plane" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-control-plane-public-ip-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name
  allocation_method   = "Dynamic"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_public_ip" "worker" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-worker-public-ip-${count.index}"
  location            = var.azurerm_resource_group_location
  resource_group_name = var.azurerm_resource_group_name
  allocation_method   = "Dynamic"
  lifecycle {
    create_before_destroy = true
  }
}

output "ssh_username" {
  value = var.ssh_username
}

output "control_plane_ips" {
  value = [azurerm_linux_virtual_machine.control_plane[*].public_ip_address]
}

output "worker_ips" {
  value = [azurerm_linux_virtual_machine.worker[*].public_ip_address]
}

