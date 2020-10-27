output "ctrl_nic" {
  description = "Controller NIC and it's attributes"
  value = azurerm_network_interface.main
}

output "ctrl_pub_ip" {
  description = "Controller Public IP and it's attributes"
  value = azurerm_public_ip.main
}

output "copilot_nic" {
  description = "CoPilot NIC and it's attributes"
  value = azurerm_network_interface.avx-copilot-nic
}

output "copilot_pub_ip" {
  description = "CoPilot Public IP and it's attributes"
  value = azurerm_public_ip.avx-copilot-pub
}