module "V-net" {
    source = "./Modules/Network"
    name = var.v_net_name
    location = var.region
    resourceGrp = var.resourceGrp
    address_space = var.Vnet_address_space
}

module "NSG" {
  source = "./Modules/NSG"
  name = var.NSG_name
  location = var.region
  resourceGrp = var.resourceGrp
  rule_name = var.rule_name
  rule_access = var.rule_access
  rule_direction = var.rule_direction
  rule_protocol = var.rule_protocol
  rule_dest_port = var.rule_dest_port
}

module "Public_ips"{
    source = "./Modules/PublicIP"
    count = 3
    name = "pub_ip_${count.index+1}"
    location = var.region
    resourceGrp = var.resourceGrp
}


data "azurerm_public_ips" "available_ips" {
  depends_on = [
    module.Public_ips
  ]
  resource_group_name = var.resourceGrp

}

module "VMs"{
    source = "./Modules/Vms"
    depends_on = [
      module.Public_ips ,
      module.NSG
    ]
    count = 3
    location = var.region
    resourceGrp = var.resourceGrp
    vm_name = "${var.vm_name}${count.index+1}"
    vm_admin = var.vm_admin
    vm_password = var.vm_password
    vm_size = var.vm_size
    os_disk_type = var.os_disk_type
    os_version = var.os_version
    nsg_id = "${module.NSG.nsg_id}"
    nic_subnet_id = "${module.V-net.default_subnet_id}"
    nic_public_ip = data.azurerm_public_ips.available_ips.public_ips[count.index].id
}

module "Public_ip_Mgmt"{
    source = "./Modules/PublicIP"
    name = "pub_ip__mgmt"
    location = var.region
    resourceGrp = var.resourceGrp
}

module "Managment_VM"{
    source = "./Modules/Vms"
    depends_on = [
      module.Public_ip_Mgmt ,
      module.NSG
    ]
    location = var.region
    resourceGrp = var.resourceGrp
    vm_name = "${var.vm_name}-Mgmt"
    vm_admin = var.vm_admin
    vm_password = var.vm_password
    vm_size = var.vm_size
    os_disk_type = var.os_disk_type
    os_version = var.os_version
    nsg_id = "${module.NSG.nsg_id}"
    nic_subnet_id = "${module.V-net.default_subnet_id}"
    nic_public_ip = module.Public_ip_Mgmt.ip
}