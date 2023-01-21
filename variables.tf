////// Provider info //////
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

///// Common Values /////
variable region {
    type = string
}

variable resourceGrp {
    type = string
}

///// Vnet specific values
variable "v_net_name" {
  type = string
}

variable "Vnet_address_space" {
  type = list
}

//// NSG values ////
variable "NSG_name" {
  type = string
}
variable "rule_name" {
  type = string
}
variable "rule_direction" {
  type = string
}
variable "rule_protocol" {
  type = string
}

variable "rule_access" {
  type = string
}

variable "rule_dest_port" {
  type = string
}

///// VM variables ////

variable "vm_name" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "os_version" {
  type = string
}

variable "os_disk_type" {
  type = string
}
variable "vm_admin" {
  type = string
}
variable "vm_password" {
  type = string
}



