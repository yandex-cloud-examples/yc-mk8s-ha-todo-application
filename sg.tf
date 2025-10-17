resource "yandex_vpc_security_group" "k8s_cluster" {
  folder_id   = local.folder_id
  name        = "k8s-cluster${local.name_suffix}"
  description = "Access to Kubernetes API"
  network_id  = local.network_id
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_api_icmp" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "ICMP"
  description            = "Allow ICMP to Kubernetes API"
  v4_cidr_blocks         = var.k8s_cluster_allowed_ips
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_api_icmp" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "ICMP"
  description            = "Allow ICMP to Kubernetes API"
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_api_443" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Access to Kubernetes API via port 443 from internet"
  v4_cidr_blocks         = var.k8s_cluster_allowed_ips
  port                   = 443
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_api_443" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Access to Kubernetes API via port 443 from nodes"
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
  port                   = 443
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_api_6443" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Access to Kubernetes API via port 6443 from internet"
  v4_cidr_blocks         = var.k8s_cluster_allowed_ips
  port                   = 6443
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_api_6443" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Access to Kubernetes API via port 6443 from nodes"
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
  port                   = 6443
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_nlb_hc" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Availability checks from nlb address range"
  predefined_target      = "loadbalancer_healthchecks"
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_kublet" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Access to kubelet on nodes"
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
  port                   = 10250
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_node_kube_proxy" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Access to kube-proxy healthchecks on nodes"
  security_group_id      = yandex_vpc_security_group.k8s_nodes.id
  port                   = 10256
}

resource "yandex_vpc_security_group_rule" "k8s_cluster_pods" {
  security_group_binding = yandex_vpc_security_group.k8s_cluster.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Access to pods"
  v4_cidr_blocks         = [var.k8s_cluster_ipv4_range]
  port                   = -1
}

resource "yandex_vpc_security_group" "k8s_nodes" {
  folder_id   = local.folder_id
  name        = "k8s-nodes${local.name_suffix}"
  description = "K8s nodes security group"
  network_id  = local.network_id
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_self" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "ANY"
  description            = "node-node communication inside a security group"
  predefined_target      = "self_security_group"
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_pod_service" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "ANY"
  description            = "Allows pod-pod and pod-service communication inside"
  v4_cidr_blocks         = [var.k8s_cluster_ipv4_range, var.k8s_service_ipv4_range]
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_hc_nlb" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Availability checks from nlb address range"
  predefined_target      = "loadbalancer_healthchecks"
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_nodeports" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Incomming traffic from the Internet to the NodePort port range"
  v4_cidr_blocks         = ["0.0.0.0/0"]
  from_port              = 30000
  to_port                = 32767
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_hc_alb" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Heathchecks from ALB"
  v4_cidr_blocks         = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  port                   = 10501
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_kubelet" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Traffic to kubelet form controlplane"
  security_group_id      = yandex_vpc_security_group.k8s_cluster.id
  port                   = 10250
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_kubeproxy_hc" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Traffic to kube-proxy healthchecks"
  security_group_id      = yandex_vpc_security_group.k8s_cluster.id
  port                   = 10256
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_icmp" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "ICMP"
  description            = "Allows ICMP packets"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_ssh" {
  count                  = var.k8s_nodes_ssh_allowed_ips == null ? 0 : 1
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "ingress"
  protocol               = "TCP"
  description            = "Allow access to worker nodes via ssh"
  v4_cidr_blocks         = var.k8s_nodes_ssh_allowed_ips
  port                   = 22
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_outgoing_tcp" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "All outgoing traffic"
  v4_cidr_blocks         = ["0.0.0.0/0"]
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_outgoing_icmp" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "ICMP"
  description            = "ICMP outgoing traffic"
  v4_cidr_blocks         = ["0.0.0.0/0"]
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_self" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "ANY"
  description            = "Allow node-node communication inside a security group"
  predefined_target      = "self_security_group"
  port                   = -1
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_master_443" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Allows traffic to master 443"
  security_group_id      = yandex_vpc_security_group.k8s_cluster.id
  port                   = 443
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_master_6443" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Allows traffic to master 6443"
  security_group_id      = yandex_vpc_security_group.k8s_cluster.id
  port                   = 6443
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_pod_service" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "ANY"
  description            = "pod-pod and pod-service communication inside"
  v4_cidr_blocks         = [var.k8s_cluster_ipv4_range, var.k8s_service_ipv4_range]
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_dns_udp" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "UDP"
  description            = "Allows access to DNS (UDP)"
  v4_cidr_blocks         = local.k8s_node_cidr_blocks
  port                   = 53
}

resource "yandex_vpc_security_group_rule" "k8s_nodes_to_dns_tcp" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes.id
  direction              = "egress"
  protocol               = "TCP"
  description            = "Allows access to DNS (TCP)"
  v4_cidr_blocks         = local.k8s_node_cidr_blocks
  port                   = 53
}

resource "yandex_vpc_security_group" "db" {
  name        = "db${local.name_suffix}"
  description = "database security group"
  network_id  = local.network_id
  folder_id   = local.folder_id
}

resource "yandex_vpc_security_group_rule" "db_icmp" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "ingress"
  protocol               = "ICMP"
  description            = "icmp"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

resource "yandex_vpc_security_group_rule" "db_self" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 6432
  description            = "Allows node-to-node communication inside a security group"
  predefined_target      = "self_security_group"
}

resource "yandex_vpc_security_group_rule" "db_from_k8s" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 6432
  description            = "Allows from k8s"
  v4_cidr_blocks         = local.k8s_node_cidr_blocks
}

resource "yandex_vpc_security_group_rule" "db_healthcheck" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = -1
  description            = "Allows availability checks. It is required"
  predefined_target      = "loadbalancer_healthchecks"
}

resource "null_resource" "sg_k8s_cluster" {
  depends_on = [
    yandex_vpc_security_group.k8s_cluster,
    yandex_vpc_security_group_rule.k8s_cluster_api_icmp,
    yandex_vpc_security_group_rule.k8s_cluster_node_api_icmp,
    yandex_vpc_security_group_rule.k8s_cluster_api_443,
    yandex_vpc_security_group_rule.k8s_cluster_node_api_443,
    yandex_vpc_security_group_rule.k8s_cluster_api_6443,
    yandex_vpc_security_group_rule.k8s_cluster_node_api_6443,
    yandex_vpc_security_group_rule.k8s_cluster_node_nlb_hc,
    yandex_vpc_security_group_rule.k8s_cluster_node_kublet,
    yandex_vpc_security_group_rule.k8s_cluster_node_kube_proxy,
    yandex_vpc_security_group_rule.k8s_cluster_pods,
  ]
}

resource "null_resource" "sg_k8s_nodes" {
  depends_on = [
    yandex_vpc_security_group.k8s_nodes,
    yandex_vpc_security_group_rule.k8s_nodes_self,
    yandex_vpc_security_group_rule.k8s_nodes_pod_service,
    yandex_vpc_security_group_rule.k8s_nodes_hc_nlb,
    yandex_vpc_security_group_rule.k8s_nodes_nodeports,
    yandex_vpc_security_group_rule.k8s_nodes_hc_alb,
    yandex_vpc_security_group_rule.k8s_nodes_kubelet,
    yandex_vpc_security_group_rule.k8s_nodes_kubeproxy_hc,
    yandex_vpc_security_group_rule.k8s_nodes_icmp,
    yandex_vpc_security_group_rule.k8s_nodes_ssh,
    yandex_vpc_security_group_rule.k8s_nodes_outgoing_tcp,
    yandex_vpc_security_group_rule.k8s_nodes_outgoing_icmp,
    yandex_vpc_security_group_rule.k8s_nodes_to_self,
    yandex_vpc_security_group_rule.k8s_nodes_to_master_443,
    yandex_vpc_security_group_rule.k8s_nodes_to_master_6443,
    yandex_vpc_security_group_rule.k8s_nodes_to_pod_service,
    yandex_vpc_security_group_rule.k8s_nodes_to_dns_udp,
    yandex_vpc_security_group_rule.k8s_nodes_to_dns_tcp,
  ]
}

resource "null_resource" "sg_db" {
  depends_on = [
    yandex_vpc_security_group.db,
    yandex_vpc_security_group_rule.db_icmp,
    yandex_vpc_security_group_rule.db_self,
    yandex_vpc_security_group_rule.db_from_k8s,
    yandex_vpc_security_group_rule.db_healthcheck,
    yandex_vpc_security_group_rule.k8s_cluster_node_kube_proxy,
  ]
}

resource "null_resource" "sg" {
  depends_on = [
    null_resource.sg_k8s_cluster,
    null_resource.sg_k8s_nodes,
    null_resource.sg_db,
  ]
}
