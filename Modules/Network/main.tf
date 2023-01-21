resource "azurerm_virtual_network" "test-vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGrp
  address_space       = var.address_space

  subnet {
    name           = "subnet-1"
    address_prefix = var.address_space[0]
  }
  tags = {
    environment = "test"
  }
}