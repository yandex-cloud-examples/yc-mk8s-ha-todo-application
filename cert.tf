locals {
  dns_domain_trim = trimsuffix(var.target_host, ".")
  cert_id         = yandex_cm_certificate.le_cert.id
}

resource "yandex_cm_certificate" "le_cert" {
  name      = replace(local.dns_domain_trim, ".", "-")
  domains   = [local.dns_domain_trim]
  folder_id = local.folder_id
  managed {
    challenge_type = "DNS_CNAME"
  }

  depends_on = [
    null_resource.dns
  ]
}
