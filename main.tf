module "V-net" {
    source = "./Modules/Network"
    name = var.v_net_name
    location = var.region
    resourceGrp = var.resourceGrp
    address_space = var.Vnet_address_space
}

module "default_NSG" {
  source = "./Modules/NSG"
  name = "default_nsg"
  location = var.region
  resourceGrp = var.resourceGrp
  rule_name = var.rule_name
  rule_access = var.rule_access
  rule_direction = var.rule_direction
  rule_protocol = var.rule_protocol
  rule_dest_ports = ["0-65535"]
}
module "ssh_NSG" {
  source = "./Modules/NSG"
  name = var.NSG_name
  location = var.region
  resourceGrp = var.resourceGrp
  rule_name = var.rule_name
  rule_access = var.rule_access
  rule_direction = var.rule_direction
  rule_protocol = var.rule_protocol
  rule_dest_ports = var.rule_dest_ports
}

module "Bastion_Public_ip"{
    source = "./Modules/PublicIP"
    name = "Mgmt_pub_ip"
    location = var.region
    resourceGrp = var.resourceGrp
}


# data "azurerm_public_ips" "available_ips" {
#   depends_on = [
#     module.Public_ips
#   ]
#   resource_group_name = var.resourceGrp

# }
resource "tls_private_key" "linux_pv_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkey" {
  depends_on = [
    tls_private_key.linux_pv_key
  ]
  filename = "linuxkey.pem"
  content = tls_private_key.linux_pv_key.private_key_pem
  
}
module "Prv_VMs"{
    source = "./Modules/Vms"
    depends_on = [
      module.default_NSG
    ]
    count = 6
    location = var.region
    resourceGrp = var.resourceGrp
    vm_name = "${var.vm_name}${count.index+1}-rke"
    vm_admin = var.vm_admin
    vm_size = var.vm_size
    pubkey = tls_private_key.linux_pv_key.public_key_openssh
    os_disk_type = var.os_disk_type
    os_version = var.os_version
    nsg_id = "${module.default_NSG.nsg_id}"
    nic_subnet_id = "${module.V-net.default_subnet_id}"
}

module "Bastion"{
    source = "./Modules/Vms"
    depends_on = [
      module.Bastion_Public_ip,
      module.ssh_NSG,
      tls_private_key.linux_pv_key
    ]
    location = var.region
    resourceGrp = var.resourceGrp
    vm_name = "${var.vm_name}-Bastion"
    vm_admin = var.vm_admin
    vm_size = var.vm_size
    pubkey = tls_private_key.linux_pv_key.public_key_openssh
    os_disk_type = var.os_disk_type
    os_version = var.os_version
    nsg_id = "${module.ssh_NSG.nsg_id}"
    nic_subnet_id = "${module.V-net.default_subnet_id}"
    nic_public_ip = "${module.Bastion_Public_ip.ip}"
}

module "Proxy_Public_ip"{
    source = "./Modules/PublicIP"
    name = "Proxy_pub_ip"
    location = var.region
    resourceGrp = var.resourceGrp
}
module "Proxy_VM"{
    source = "./Modules/Vms"
    depends_on = [
      module.Proxy_Public_ip,
      module.default_NSG,
      tls_private_key.linux_pv_key
    ]

    location = var.region
    resourceGrp = var.resourceGrp
    vm_name = "proxy"
    vm_admin = var.vm_admin
    vm_size = var.vm_size
    pubkey = tls_private_key.linux_pv_key.public_key_openssh
    os_disk_type = var.os_disk_type
    os_version = var.os_version
    nsg_id = "${module.default_NSG.nsg_id}"
    nic_subnet_id = "${module.V-net.default_subnet_id}"
    nic_public_ip = "${module.Proxy_Public_ip.ip}"
}



# module "Public_ip_win"{
#     source = "./Modules/PublicIP"
#     name = "Windows_pub_ip"
#     location = var.region
#     resourceGrp = var.resourceGrp
# }
# resource "azurerm_network_interface" "example" {
#   name                = "example-nic"
#   location            = var.region
#   resource_group_name = var.resourceGrp

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = "${module.V-net.default_subnet_id}"
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id = "${module.Public_ip_win.ip}"
#   }
# }

# resource "azurerm_windows_virtual_machine" "example" {
#   name                = "windows-machine"
#   resource_group_name = var.resourceGrp
#   location            = var.region
#   size                = "Standard_F2"
#   admin_username      = "adminuser"
#   admin_password      = "P@$$w0rd1234!"
#   network_interface_ids = [
#     azurerm_network_interface.example.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2016-Datacenter"
#     version   = "latest"
#   }
# }
