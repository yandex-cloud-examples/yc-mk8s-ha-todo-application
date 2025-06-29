provider "helm" {
  debug = true
  kubernetes {
    host                   = yandex_kubernetes_cluster.cluster.master[0].external_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.cluster.master[0].cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
  #  registry {
  #    url      = "oci://cr.yandex"
  #    username = "iam"
  #    password = data.yandex_client_config.client.iam_token
  #  }
}

provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.cluster.master[0].external_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.cluster.master[0].cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}
