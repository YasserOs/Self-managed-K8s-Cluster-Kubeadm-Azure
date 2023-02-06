variable "location" {
  type = string
}

variable "resourceGrp" {
  type = string
}
/////// vm variables ///////
variable "vm_name" {
  type = string
}

variable "vm_size" {
  type = string
}
variable "vm_admin" {
  type = string
}

variable "pubkey" {
  type = string
}
# variable "vm_password" {
#   type = string
# }
variable "os_version" {
  type = string
}
variable "os_disk_type" {
  type = string
}
///// nic variables //////

variable "nic_subnet_id" {
  type = string
}

variable "nic_public_ip" {
  type = string
  default = ""
}

variable "nsg_id" {
  type = string
}
