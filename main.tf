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
# Create a Public IP to assign to the VM
resource "azurerm_public_ip" "public_ip" {
  allocation_method = "Static"
  location = azurerm_resource_group.nomadserver.location
  name = "nomad_public_ip"
  resource_group_name = azurerm_resource_group.nomadserver.name
}

# Create a network interface connected to the VNet, and with a Public IP
resource "azurerm_network_interface" "demo" {
  name                = "demo-nic"
  location            = azurerm_resource_group.nomadserver.location
  resource_group_name = azurerm_resource_group.nomadserver.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# A security group is required to forward traffic from public IP to VM
resource "azurerm_network_security_group" "nomad_nsg" {
  name                = "nomad_nsg"
  location            = azurerm_resource_group.nomadserver.location
  resource_group_name = azurerm_resource_group.nomadserver.name

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

}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.demo.id
  network_security_group_id = azurerm_network_security_group.nomad_nsg.id
}

# We want to login to the VM so we need a SSH private key
resource "tls_private_key" "adminuser" {
  algorithm   = "RSA"
  rsa_bits = 2048
}

# Now provision the actual VM
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
    version   = "7.7.2020062401"
  }

  custom_data = base64encode(local.cloudinit)
}

# Output some useful information about what we just created
# This is totally insecure but who cares, it's a demo.
output "privatekey" {
  value = tls_private_key.adminuser.private_key_pem
}
output "ip" {
  value = azurerm_linux_virtual_machine.nomad_server.public_ip_addresses
}
output "ip2" {
  value = azurerm_public_ip.public_ip.ip_address
}