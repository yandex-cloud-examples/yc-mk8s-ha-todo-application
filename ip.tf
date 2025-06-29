locals {
  ip_addr = var.ip_addr == null ? yandex_vpc_address.addr[0].external_ipv4_address[0].address : var.ip_addr
}

resource "yandex_vpc_address" "addr" {
  count     = var.ip_addr == null ? 1 : 0
  name      = "${var.ip_addr_name}${local.name_suffix}"
  folder_id = local.folder_id

  external_ipv4_address {
    zone_id = var.ip_addr_zone
  }
}

################################################################### 
############################ Variables ############################ 
################################################################### 

variable "ip_addr" {
  type        = string
  description = "ip address"
  default     = null
}

variable "ip_addr_name" {
  type        = string
  description = "primary project ip address"
  default     = "primary-address"
}

variable "ip_addr_zone" {
  type        = string
  description = "ip address zone (for new addresses)"
  default     = "ru-central1-a"
}
