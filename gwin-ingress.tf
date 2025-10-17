locals {
  gwin_security_group_id = var.gwin_enabled ? yandex_vpc_security_group.gwin[0].id : ""
  gwin_annotations = {
    "gwin.yandex.cloud/groupName" : "ingress"
#    "gwin.yandex.cloud/subnets" : "${join(",", local.k8s_node_subnet_ids)}"
    "gwin.yandex.cloud/externalIPv4Address" : "${local.ip_addr}"
    "gwin.yandex.cloud/securityGroups" : "${local.gwin_security_group_id}"
    "gwin.yandex.cloud/redirect.my-redirect.replaceScheme" : "https"
  }
}

resource "yandex_iam_service_account" "k8s_cluster_gwin" {
  count       = var.gwin_enabled ? 1 : 0
  name        = "k8s-cluster-gwin${local.name_suffix}"
  description = "service account for gwin ingress controller"
  folder_id   = local.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_gwin" {
  for_each  = toset(var.gwin_enabled ? ["alb.editor", "load-balancer.admin", "vpc.user", "k8s.viewer", "certificate-manager.certificates.downloader", "compute.viewer"] : [])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.k8s_cluster_gwin[0].id}"
}

resource "yandex_iam_service_account_key" "k8s_cluster_gwin" {
  count              = var.gwin_enabled ? 1 : 0
  service_account_id = yandex_iam_service_account.k8s_cluster_gwin[0].id
  description        = "k8s cluster gwin sa key"
  key_algorithm      = "RSA_2048"
}

resource "helm_release" "gwin" {
  count            = var.gwin_enabled ? 1 : 0
  name             = "gwin"
  namespace        = "gwin"
  repository       = "oci://cr.yandex/yc-marketplace/yandex-cloud/gwin"
  chart            = "gwin-chart"
  version          = "v1.0.1"
  create_namespace = true

  values = [<<-EOF
    controller:
      folderId: ${local.folder_id}
      defaultBalancerSubnets: '${jsonencode(local.k8s_node_subnet_ids)}'
      ycServiceAccount:
        secret:
          value: |
            ${jsonencode({
              "id" : yandex_iam_service_account_key.k8s_cluster_gwin[0].id,
              "service_account_id" : yandex_iam_service_account_key.k8s_cluster_gwin[0].service_account_id,
              "created_at" : yandex_iam_service_account_key.k8s_cluster_gwin[0].created_at,
              "key_algorithm" : yandex_iam_service_account_key.k8s_cluster_gwin[0].key_algorithm,
              "public_key" : yandex_iam_service_account_key.k8s_cluster_gwin[0].public_key,
              "private_key" : yandex_iam_service_account_key.k8s_cluster_gwin[0].private_key
            })} 
  EOF
  ]

  depends_on = [
    null_resource.kubernetes,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_gwin,
    yandex_iam_service_account_key.k8s_cluster_gwin,
    yandex_vpc_security_group.gwin,
  ]
}

resource "yandex_vpc_security_group" "gwin" {
  count       = var.gwin_enabled ? 1 : 0
  name        = "k8s-gwin-ingress${local.name_suffix}"
  description = "gwin ingress controller security group"
  network_id  = local.network_id
  folder_id   = local.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "Availability checks of load balancer"
    predefined_target = "loadbalancer_healthchecks"
#    v4_cidr_blocks = [ "198.18.235.0/24", "198.18.248.0/24" ]
    port              = -1
  }


  egress {
    protocol       = "TCP"
    description    = "Enable traffic from GWIN to K8s services"
    v4_cidr_blocks = local.k8s_node_cidr_blocks
    from_port      = 30000
    to_port        = 32767
  }

  egress {
    protocol       = "TCP"
    description    = "Enable probes from GWIN to K8s"
    v4_cidr_blocks = local.k8s_node_cidr_blocks
    port           = 10501
  }
}

###################################################################
############################ Variables ############################
###################################################################

variable "gwin_enabled" {
  type        = bool
  description = "Setup of the GWIN ingress controller"
  default     = true
}
