// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/image
// https://stackoverflow.com/questions/24418815/how-do-i-install-docker-using-cloud-init
// https://www.packer.io/docs/builders/azure/arm#custom_managed_image_name
// https://docs.microsoft.com/en-us/azure/virtual-machines/linux/imaging
variable "azure_location" {
  default = "West Europe"
}

resource "azurerm_resource_group" "nomadserver" {
  location = var.azure_location
  name = "nomadserver_rg"
}
resource "azurerm_virtual_network" "demo" {
  name                = "demo-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nomadserver.location
  resource_group_name = azurerm_resource_group.nomadserver.name
}
resource "azurerm_subnet" "demo" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.nomadserver.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_network_interface" "demo" {
  name                = "demo-nic"
  location            = azurerm_resource_group.nomadserver.location
  resource_group_name = azurerm_resource_group.nomadserver.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
  }
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}

resource "tls_private_key" "adminuser" {
  algorithm   = "RSA"
  rsa_bits = 2048
}

resource "azurerm_linux_virtual_machine" "nomad_server" {
  name                = "demo-machine"
  resource_group_name = azurerm_resource_group.nomadserver.name
  location            = azurerm_resource_group.nomadserver.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.demo.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.adminuser.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_7-gen2"
    version   = "latest"
  }
}
output "privatekey" {
  value = tls_private_key.adminuser.private_key_pem
}