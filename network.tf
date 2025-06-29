locals {
  network_name           = var.network_id == null ? yandex_vpc_network.thenetwork[0].name : data.yandex_vpc_network.thenetwork[0].name
  network_id             = var.network_id == null ? yandex_vpc_network.thenetwork[0].id : var.network_id
  default_route_table_id = var.network_id == null ? yandex_vpc_route_table.default_route_table[0].id : data.yandex_vpc_route_table.default_route_table[0].id
}

resource "yandex_vpc_network" "thenetwork" {
  count       = var.network_id == null ? 1 : 0
  name        = "${var.network_name}${local.name_suffix}"
  description = var.network_description
  folder_id   = local.folder_id
  timeouts {
    create = "10m"
    delete = "2h"
  }
}

data "yandex_vpc_network" "thenetwork" {
  count      = var.network_id == null ? 0 : 1
  network_id = var.network_id
  folder_id  = local.folder_id
}

resource "yandex_vpc_subnet" "k8s_subnet_1" {
  name           = "${local.network_name}-k8s1"
  description    = "${var.k8s_subnet_desc}${var.zone_1}"
  v4_cidr_blocks = [var.k8s_subnet_cidr_1]
  zone           = var.zone_1
  network_id     = local.network_id
  folder_id      = local.folder_id
  route_table_id = local.default_route_table_id
}

resource "yandex_vpc_subnet" "k8s_subnet_2" {
  name           = "${local.network_name}-k8s2"
  description    = "${var.k8s_subnet_desc}${var.zone_2}"
  v4_cidr_blocks = [var.k8s_subnet_cidr_2]
  zone           = var.zone_2
  network_id     = local.network_id
  folder_id      = local.folder_id
  route_table_id = local.default_route_table_id
}

resource "yandex_vpc_subnet" "k8s_subnet_3" {
  name           = "${local.network_name}-k8s3"
  description    = "${var.k8s_subnet_desc}${var.zone_3}"
  v4_cidr_blocks = [var.k8s_subnet_cidr_3]
  zone           = var.zone_3
  network_id     = local.network_id
  folder_id      = local.folder_id
  route_table_id = local.default_route_table_id
}

resource "yandex_vpc_subnet" "db_subnet_1" {
  name           = "${local.network_name}-db1"
  description    = "${var.db_subnet_desc}${var.zone_1}"
  v4_cidr_blocks = [var.db_subnet_cidr_1]
  zone           = var.zone_1
  network_id     = local.network_id
  folder_id      = local.folder_id
}

resource "yandex_vpc_subnet" "db_subnet_2" {
  name           = "${local.network_name}-db2"
  description    = "${var.db_subnet_desc}${var.zone_2}"
  v4_cidr_blocks = [var.db_subnet_cidr_2]
  zone           = var.zone_2
  network_id     = local.network_id
  folder_id      = local.folder_id
}

resource "yandex_vpc_subnet" "db_subnet_3" {
  name           = "${local.network_name}-db3"
  description    = "${var.db_subnet_desc}${var.zone_3}"
  v4_cidr_blocks = [var.db_subnet_cidr_3]
  zone           = var.zone_3
  network_id     = local.network_id
  folder_id      = local.folder_id
}

resource "yandex_vpc_gateway" "egress_gateway" {
  count       = var.network_id == null ? 1 : 0
  name        = "${local.network_name}-egress-nat"
  description = "The egress gateway for ${local.network_name}"
  folder_id   = local.folder_id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "default_route_table" {
  count      = var.network_id == null ? 1 : 0
  name       = "${local.network_name}-default-route-table"
  network_id = local.network_id
  folder_id  = local.folder_id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress_gateway[0].id
  }
}

data "yandex_vpc_route_table" "default_route_table" {
  count     = var.network_id == null ? 0 : 1
  name      = "${local.network_name}-default-route-table"
  folder_id = local.folder_id
}

###################################################################
############################ Variables ############################
###################################################################


variable "network_id" {
  type        = string
  description = "Existing network_id(vpc-id) where resources will be created"
  default     = null
}

variable "network_name" {
  type        = string
  description = "Network name"
  default     = "net"
}

variable "network_description" {
  type        = string
  description = "Network description"
  default     = "Main network"
}

variable "k8s_subnet_desc" {
  type        = string
  description = "K8s subnet description"
  default     = "K8s in zone "
}

variable "db_subnet_desc" {
  type        = string
  description = "Database subnet description"
  default     = "DB in zone "
}
