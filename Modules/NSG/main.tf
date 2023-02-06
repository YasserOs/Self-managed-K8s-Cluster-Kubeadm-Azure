resource "azurerm_network_security_group" "example" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGrp

  security_rule {
    name                       = var.rule_name
    priority                   = 100
    direction                  = var.rule_direction
    access                     = var.rule_access
    protocol                   = var.rule_protocol
    destination_port_ranges     = var.rule_dest_ports
    source_address_prefix      = "*"
    source_port_range = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "test"
  }
}