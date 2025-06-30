locals {
  alb_ip_addr = local.ip_addr
  app_values  = <<-EOF
    ingress:
      enabled: true
      className: ""
      annotations:
        ingress.alb.yc.io/group-name: ingress
        ingress.alb.yc.io/subnets: "${join(",", local.k8s_node_subnet_ids)}"
        ingress.alb.yc.io/external-ipv4-address: "${local.alb_ip_addr}"
        ingress.alb.yc.io/security-groups: ${yandex_vpc_security_group.alb.id}
      hosts:
        - host: ${var.target_host}
          paths:
            - path: /api/
              pathType: Prefix
              serviceName: "todo-backend"
              servicePort: "8080"
            - path: /
              pathType: Prefix
              serviceName: "todo-frontend"
              servicePort: "80"
      tls:
        - secretName: yc-certmgr-cert-id-${local.cert_id}
          hosts:
            - ${var.target_host}
    backend: 
      replicaCount: ${length(local.k8s_node_subnet_ids)}
      image:
        repository: ${var.app_backend_image}
        tag: "${var.app_backend_tag}"
      service:
        externalTrafficPolicy: Local
        type: NodePort
        port: 8080
      db:
        host: "c-${yandex_mdb_postgresql_cluster.this.id}.rw.mdb.yandexcloud.net"
        port: "6432"
        database: "${yandex_mdb_postgresql_database.db1.name}"
        user: "${yandex_mdb_postgresql_user.user1.name}"
        password: "${yandex_mdb_postgresql_user.user1.password}"
        tz: "Europe/Moscow"
      roDb:
        host: "c-${yandex_mdb_postgresql_cluster.this.id}.rw.mdb.yandexcloud.net"
    frontend: 
      replicaCount: ${length(local.k8s_node_subnet_ids)}
      image:
        repository: ${var.app_frontend_image}
        tag: "${var.app_frontend_tag == null ? var.app_backend_tag : var.app_frontend_tag}"
      service:
        externalTrafficPolicy: Local
        type: NodePort
        port: 80
  EOF
}

resource "helm_release" "application" {
  count            = var.app_enabled == true ? 1 : 0
  name             = "todo"
  namespace        = "todo"
  repository       = "oci://cr.yandex/docs-registry/helm/todo"
  chart            = "todo"
  version          = "0.1.0"
  create_namespace = true
  values = [
    local.app_values
  ]
  depends_on = [
    resource.null_resource.infra
  ]

  timeout = 180
  wait    = false
}

###################################################################
############################ Variables ############################
###################################################################

variable "app_enabled" {
  type        = bool
  description = "Enable application deploy"
  default     = true
}

variable "app_backend_image" {
  type        = string
  description = "backend registry path"
  default     = "cr.yandex/docs-registry/app/todo-backend"
}

variable "app_backend_tag" {
  type        = string
  description = "backend tag"
  default     = "v0.0.1"
}

variable "app_frontend_image" {
  type        = string
  description = "backend registry path"
  default     = "cr.yandex/docs-registry/app/todo-frontend"
}

variable "app_frontend_tag" {
  type        = string
  description = "frontend tag"
  default     = "v0.0.1"
}
