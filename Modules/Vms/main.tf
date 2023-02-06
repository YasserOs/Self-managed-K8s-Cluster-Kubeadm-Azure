resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}_nic_rke"
  location            = var.location
  resource_group_name = var.resourceGrp

  ip_configuration {
    name                          = "${var.vm_name}_internal"
    subnet_id                     = var.nic_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.nic_public_ip
  }
}
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nsg_id
}
resource "azurerm_linux_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = var.resourceGrp
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin
  # admin_password      = var.vm_password
  # disable_password_authentication = "false"
  admin_ssh_key {
    username   = "adminuser"
    public_key = var.pubkey
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "${var.os_version}"
    version   = "latest"
  }
}