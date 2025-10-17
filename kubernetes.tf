locals {
  k8s_node_metadata = local.os_user_pubkey == null ? null : { "ssh-keys" : "${var.os_user}:${local.os_user_pubkey}" }
  k8s_node_cidr_blocks = flatten([
    yandex_vpc_subnet.k8s_subnet_1.v4_cidr_blocks,
    yandex_vpc_subnet.k8s_subnet_2.v4_cidr_blocks,
    yandex_vpc_subnet.k8s_subnet_3.v4_cidr_blocks,
  ])
  k8s_node_subnet_ids = flatten([
    yandex_vpc_subnet.k8s_subnet_1.id,
    yandex_vpc_subnet.k8s_subnet_2.id,
    yandex_vpc_subnet.k8s_subnet_3.id,
  ])
}

resource "yandex_iam_service_account" "k8s_cluster_sa" {
  name        = "${var.k8s_cluster_name}-cluster-sa${local.name_suffix}"
  description = "service account for kubernetes cluster"
  folder_id   = local.folder_id
}

resource "yandex_iam_service_account" "k8s_node_sa" {
  name        = "${var.k8s_cluster_name}-node-sa${local.name_suffix}"
  description = "service account for kubernetes nodes"
  folder_id   = local.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_sa_compute" {
  for_each  = toset(["k8s.clusters.agent"])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_sa_vpc" {
  for_each = toset([
    "vpc.publicAdmin",
    "vpc.privateAdmin",
    "vpc.bridgeAdmin",
    "vpc.user",
    "load-balancer.admin",
    "logging.writer"
  ])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_cr_puller" {
  for_each  = toset(["container-registry.images.puller"])
  folder_id = local.folder_id

  role   = each.key
  member = "serviceAccount:${yandex_iam_service_account.k8s_node_sa.id}"
}

resource "yandex_kms_symmetric_key" "k8s_key" {
  name              = "${var.k8s_cluster_name}-key${local.name_suffix}"
  description       = "k8s cluster key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  folder_id         = local.folder_id
}

resource "yandex_kubernetes_cluster" "cluster" {
  name        = "${var.k8s_cluster_name}${local.name_suffix}"
  description = var.k8s_cluster_description

  network_id = local.network_id
  folder_id  = local.folder_id

  cluster_ipv4_range = var.k8s_cluster_ipv4_range
  service_ipv4_range = var.k8s_service_ipv4_range

  master {
    version = var.k8s_version

    master_location {
      subnet_id = yandex_vpc_subnet.k8s_subnet_1.id
      zone      = var.zone_1
    }

    master_location {
      subnet_id = yandex_vpc_subnet.k8s_subnet_2.id
      zone      = var.zone_2
    }

    master_location {
      subnet_id = yandex_vpc_subnet.k8s_subnet_3.id
      zone      = var.zone_3
    }

    public_ip = true

    security_group_ids = [yandex_vpc_security_group.k8s_cluster.id]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "4:00"
        duration   = "2h"
      }
    }

    master_logging {
      enabled                    = true
      folder_id                  = local.folder_id
      kube_apiserver_enabled     = true
      cluster_autoscaler_enabled = true
      events_enabled             = true
      audit_enabled              = false
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_node_sa.id

  release_channel = "RAPID"

  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s_key.id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_sa_compute,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_sa_vpc,
    yandex_resourcemanager_folder_iam_member.k8s_node_sa_cr_puller,
    null_resource.sg_k8s_cluster,
    null_resource.sg_k8s_nodes,
  ]
}

resource "yandex_kubernetes_node_group" "cluster_node_group_1" {
  cluster_id  = yandex_kubernetes_cluster.cluster.id
  name        = "${var.k8s_node_name_prefix}${local.name_suffix}-1"
  description = "${var.k8s_node_name_prefix} nodes in ${var.zone_1}"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = var.k8s_node_nat
      subnet_ids         = [yandex_vpc_subnet.k8s_subnet_1.id]
      security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
    }

    resources {
      memory = var.k8s_node_mem
      cores  = var.k8s_node_cores
    }

    boot_disk {
      type = var.k8s_node_disk_type
      size = var.k8s_node_disk_size
    }

    scheduling_policy {
      preemptible = var.k8s_node_preemptible
    }

    container_runtime {
      type = "containerd"
    }

    metadata = local.k8s_node_metadata
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_nodes_count
    }
  }

  allocation_policy {
    location {
      zone = yandex_vpc_subnet.k8s_subnet_1.zone
    }
  }

  deploy_policy {
    max_expansion   = 0
    max_unavailable = 1
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "5:00"
      duration   = "2h"
    }
  }
}

resource "yandex_kubernetes_node_group" "cluster_node_group_2" {
  cluster_id  = yandex_kubernetes_cluster.cluster.id
  name        = "${var.k8s_node_name_prefix}${local.name_suffix}-2"
  description = "${var.k8s_node_name_prefix} nodes in ${var.zone_2}"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = var.k8s_node_nat
      subnet_ids         = [yandex_vpc_subnet.k8s_subnet_2.id]
      security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
    }

    resources {
      memory = var.k8s_node_mem
      cores  = var.k8s_node_cores
    }

    boot_disk {
      type = var.k8s_node_disk_type
      size = var.k8s_node_disk_size
    }

    scheduling_policy {
      preemptible = var.k8s_node_preemptible
    }

    container_runtime {
      type = "containerd"
    }

    metadata = local.k8s_node_metadata
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_nodes_count
    }
  }

  allocation_policy {
    location {
      zone = yandex_vpc_subnet.k8s_subnet_2.zone
    }
  }

  deploy_policy {
    max_expansion   = 0
    max_unavailable = 1
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "3:00"
      duration   = "2h"
    }
  }
}

resource "yandex_kubernetes_node_group" "cluster_node_group_3" {
  cluster_id  = yandex_kubernetes_cluster.cluster.id
  name        = "${var.k8s_node_name_prefix}${local.name_suffix}-3"
  description = "${var.k8s_node_name_prefix} nodes in ${var.zone_3}"
  version     = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = var.k8s_node_nat
      subnet_ids         = [yandex_vpc_subnet.k8s_subnet_3.id]
      security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
    }

    resources {
      memory = var.k8s_node_mem
      cores  = var.k8s_node_cores
    }

    boot_disk {
      type = var.k8s_node_disk_type
      size = var.k8s_node_disk_size
    }

    scheduling_policy {
      preemptible = var.k8s_node_preemptible
    }

    container_runtime {
      type = "containerd"
    }

    metadata = local.k8s_node_metadata
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_nodes_count
    }
  }

  allocation_policy {
    location {
      zone = yandex_vpc_subnet.k8s_subnet_3.zone
    }
  }

  deploy_policy {
    max_expansion   = 0
    max_unavailable = 1
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "1:00"
      duration   = "2h"
    }
  }
}

resource "null_resource" "kubernetes" {
  depends_on = [
    yandex_kubernetes_cluster.cluster,
    yandex_kubernetes_node_group.cluster_node_group_1,
    yandex_kubernetes_node_group.cluster_node_group_2,
    yandex_kubernetes_node_group.cluster_node_group_3
  ]
}

###################################################################
############################ Variables ############################
###################################################################

variable "k8s_cluster_name" {
  type        = string
  description = "Kubernetes cluster name"
  default     = "main"
}

variable "k8s_cluster_description" {
  type        = string
  description = "Kubernetes cluster description"
  default     = "Main kubernetes cluster"
}

variable "k8s_subnet_cidr_1" {
  type        = string
  description = "subnet cidr 1"
  default     = "10.0.1.0/24"
}

variable "k8s_subnet_cidr_2" {
  type        = string
  description = "subnet cidr 2"
  default     = "10.0.2.0/24"
}

variable "k8s_subnet_cidr_3" {
  type        = string
  description = "subnet cidr 3"
  default     = "10.0.3.0/24"
}

variable "k8s_cluster_ipv4_range" {
  type        = string
  description = "Kubernetes cluster pod ipv4 range"
  default     = "10.208.0.0/16"
}

variable "k8s_service_ipv4_range" {
  type        = string
  description = "Kubernetes cluster service ipv4 range"
  default     = "10.224.0.0/16"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes cluster version"
  default     = "1.30"
}

variable "k8s_nodes_ssh_allowed_ips" {
  type        = list(string)
  description = "Networks with ssh access to kubernetes cluster"
  default     = null
}

variable "k8s_cluster_allowed_ips" {
  type        = list(string)
  description = "Networks with ssh access to kubernetes cluster"
  default     = ["0.0.0.0/0"]
}

variable "k8s_node_cores" {
  type        = string
  description = "Kubernetes node cpu capacity"
  default     = "4"
}

variable "k8s_node_mem" {
  type        = string
  description = "Kubernetes node memory capacity"
  default     = "8"
}

variable "k8s_node_disk_type" {
  type        = string
  description = "Kubernetes node disk type"
  default     = "network-ssd-nonreplicated"
}

variable "k8s_node_disk_size" {
  type        = string
  description = "Kubernetes node disk size"
  default     = "93"
}

variable "k8s_node_preemptible" {
  type        = bool
  description = "Kubernetes node preemptible"
  default     = false
}

variable "k8s_node_name_prefix" {
  type        = string
  description = "Kubernetes node name prefix"
  default     = "wrk"
}

variable "k8s_nodes_count" {
  type        = string
  description = "Kubernetes nodes count in each zone"
  default     = "1"
}

variable "k8s_node_nat" {
  type        = bool
  description = "Kubernetes nodes public ip address allocation"
  default     = false
}
