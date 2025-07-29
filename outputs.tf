output "cluster_id" {
  description = <<EOF
    Kubernetes Cluster ID
  EOF
  value       = yandex_kubernetes_cluster.cluster.id
}

output "db_user" {
  description = "Database username"
  value       = yandex_mdb_postgresql_user.user1.name
}

output "db_database" {
  description = "Database name"
  value       = yandex_mdb_postgresql_database.db1.name
}

output "db_password" {
  description = "Database password"
  sensitive   = true
  value       = yandex_mdb_postgresql_user.user1.password
}

output "db_master_fqdn" {
  description = "Database master fqdn"
  value       = "c-${yandex_mdb_postgresql_cluster.this.id}.rw.mdb.yandexcloud.net"
}
