locals {
  target_host_a    = split(".", var.target_host)
  dns_hostname_idx = length(local.target_host_a) > 2 ? 1 : 0
  dns_hostname_t   = length(local.target_host_a) > 2 ? slice(local.target_host_a, 0, 1) : ["@"]
  dns_domain_t     = var.dns_domain == null ? join(".", slice(local.target_host_a, local.dns_hostname_idx, length(local.target_host_a))) : var.dns_domain
  dns_domain       = trimsuffix(local.dns_domain_t, ".")
  dns_hostnames    = var.dns_hostnames == null ? local.dns_hostname_t : var.dns_hostnames
  dns_zone_id      = var.dns_zone_id == null ? yandex_dns_zone.dns_zone[0].id : var.dns_zone_id
  dns_folder_id    = var.dns_folder_id == null ? local.folder_id : var.dns_folder_id
}

resource "yandex_dns_zone" "dns_zone" {
  count       = var.dns_zone_id == null ? 1 : 0
  name        = var.dns_zone_name == null ? replace(local.dns_domain, ".", "-") : var.dns_zone_name
  description = var.dns_zone_description == null ? "Zone ${local.dns_domain}" : var.dns_zone_description
  folder_id   = local.dns_folder_id
  zone        = "${local.dns_domain}."
  public      = true
}

resource "yandex_dns_recordset" "dns_rec_a" {
  for_each = toset(local.dns_hostnames)
  zone_id  = local.dns_zone_id
  name     = each.key
  type     = "A"
  ttl      = 600
  data     = [local.ip_addr]
}

resource "yandex_dns_recordset" "dns_rec_a_wildcard" {
  count   = var.dns_wildcard_enable == true ? 1 : 0
  zone_id = local.dns_zone_id
  name    = "*"
  type    = "A"
  ttl     = 600
  data    = [local.ip_addr]
}

resource "yandex_dns_recordset" "validation_dns_rec" {
  zone_id = local.dns_zone_id
  name    = yandex_cm_certificate.le_cert.challenges[0].dns_name
  type    = yandex_cm_certificate.le_cert.challenges[0].dns_type
  data    = [yandex_cm_certificate.le_cert.challenges[0].dns_value]
  ttl     = 600
}

resource "time_sleep" "wait_dns" {
  depends_on = [
    yandex_dns_recordset.dns_rec_a,
  ]

  create_duration  = "60s"
  destroy_duration = "0s"
}

resource "null_resource" "dns" {
  depends_on = [
    time_sleep.wait_dns,
  ]
}

###################################################################
############################ Variables ############################
###################################################################

variable "dns_zone_id" {
  type        = string
  description = "Existing dns zone id"
  default     = null
}

variable "dns_folder_id" {
  type        = string
  description = "Exiting dns zone folder"
  default     = null
}

variable "dns_zone_name" {
  type        = string
  description = "dns_zone_name"
  default     = null
}

variable "dns_zone_description" {
  type        = string
  description = "dns_zone_description"
  default     = null
}

variable "dns_domain" {
  type        = string
  description = "dns domain"
  default     = null
}

variable "dns_hostnames" {
  type        = list(string)
  description = "dns hostnames"
  default     = null
}

variable "dns_wildcard_enable" {
  type        = bool
  description = "add wildcard recornd to dns zone?"
  default     = false
}
