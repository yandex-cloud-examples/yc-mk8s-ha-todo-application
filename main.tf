data "yandex_client_config" "client" {}

locals {
  existing_folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  folder_id          = var.folder_create == true ? yandex_resourcemanager_folder.folder[0].id : local.existing_folder_id
  uniq_suffix        = var.uniq_suffix == null ? random_string.uniq[0].result : var.uniq_suffix
  name_suffix        = var.uniq_names == true ? "-${local.uniq_suffix}" : ""
  folder_name        = var.folder_name
  os_user_pubkey     = var.os_user_pubkey_file == null ? var.os_user_pubkey : file(var.os_user_pubkey_file)
}

resource "random_string" "uniq" {
  count   = var.uniq_suffix == null && var.uniq_names == true ? 1 : 0
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "yandex_resourcemanager_folder" "folder" {
  count       = var.folder_create == true ? 1 : 0
  name        = "${local.folder_name}${local.name_suffix}"
  description = var.folder_description
  timeouts {
    create = "10m"
    delete = "2h"
  }
}

resource "time_sleep" "wait_infra" {
  depends_on = [
    null_resource.kubernetes,
    yandex_mdb_postgresql_cluster.this,
    helm_release.alb_ingress,
    helm_release.node_local_dns,
    yandex_cm_certificate.le_cert
  ]

  # create_duration = "60s"
  destroy_duration = "180s"
}

resource "null_resource" "infra" {
  depends_on = [
    time_sleep.wait_infra,
  ]
}
