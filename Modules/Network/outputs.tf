output "default_subnet_id" {
  value = azurerm_virtual_network.test-vnet.subnet.*.id[0]
}