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