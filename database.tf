resource "random_password" "user1_password" {
  length           = 32
  special          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "-_()[]{}!%^"
}

resource "yandex_mdb_postgresql_cluster" "this" {
  name               = "${var.db_cluster_name}${local.name_suffix}"
  description        = var.db_cluster_desc
  environment        = var.db_cluster_env
  network_id         = local.network_id
  folder_id          = local.folder_id
  security_group_ids = [yandex_vpc_security_group.db.id]

  config {
    version = var.db_cluster_version
    postgresql_config = {
      #max_connections                = 795
      #enable_parallel_hash           = true
      #autovacuum_vacuum_scale_factor = 0.34
      default_transaction_isolation = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries      = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }

    resources {
      disk_size          = var.db_disk_size
      disk_type_id       = var.db_disk_type_id
      resource_preset_id = var.db_resource_preset_id
    }

    access {
      data_lens     = true
      web_sql       = true
      serverless    = false
      data_transfer = false
    }

    performance_diagnostics {
      enabled                      = true
      sessions_sampling_interval   = 60
      statements_sampling_interval = 600
    }

    backup_window_start {
      hours   = 3
      minutes = 0
    }
  }

  host {
    subnet_id        = yandex_vpc_subnet.db_subnet_1.id
    zone             = yandex_vpc_subnet.db_subnet_1.zone
    assign_public_ip = false
  }

  host {
    subnet_id        = yandex_vpc_subnet.db_subnet_2.id
    zone             = yandex_vpc_subnet.db_subnet_2.zone
    assign_public_ip = false
  }

  host {
    subnet_id        = yandex_vpc_subnet.db_subnet_3.id
    zone             = yandex_vpc_subnet.db_subnet_3.zone
    assign_public_ip = false
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = "02"
  }
}

resource "yandex_mdb_postgresql_user" "user1" {
  cluster_id = yandex_mdb_postgresql_cluster.this.id
  name       = var.db_user_name
  password   = random_password.user1_password.result
  login      = true
  conn_limit = var.db_user_conn_limit
  settings = {
    default_transaction_isolation = "read committed"
    log_min_duration_statement    = 5000
  }
}

resource "yandex_mdb_postgresql_database" "db1" {
  cluster_id = yandex_mdb_postgresql_cluster.this.id
  name       = var.db_database_name
  owner      = yandex_mdb_postgresql_user.user1.name
  lc_collate = "ru_RU.UTF-8"
  lc_type    = "ru_RU.UTF-8"

  extension {
    name = "pg_repack"
  }
}

###################################################################
############################ Variables ############################
###################################################################

variable "db_cluster_name" {
  type        = string
  description = "Database cluster name"
  default     = "main"
}

variable "db_cluster_desc" {
  type        = string
  description = "Database cluster description"
  default     = "Main database"
}

variable "db_cluster_env" {
  type        = string
  description = "Database cluster environment"
  default     = "PRODUCTION"
}

variable "db_cluster_version" {
  type        = string
  description = "Database cluster version"
  default     = "17"
}

variable "db_subnet_cidr_1" {
  type        = string
  description = "db subnet cidr 1"
  default     = "10.1.1.0/28"
}

variable "db_subnet_cidr_2" {
  type        = string
  description = "db subnet cidr 2"
  default     = "10.1.2.0/28"
}

variable "db_subnet_cidr_3" {
  type        = string
  description = "db subnet cidr 3"
  default     = "10.1.3.0/28"
}

variable "db_resource_preset_id" {
  type        = string
  description = "Database node preset"
  default     = "s3-c2-m8"
}

variable "db_user_conn_limit" {
  type        = string
  description = "Main db user connection limit (must be less than cpu count * 200)"
  default     = "350"
}

variable "db_disk_type_id" {
  type        = string
  description = "Database node disk type"
  default     = "network-ssd" # network-ssd-io-m3
}

variable "db_disk_size" {
  type        = string
  description = "Database node disk size"
  default     = "33"
}

variable "db_user_name" {
  type        = string
  description = "Main db user name"
  default     = "todo"
}

variable "db_database_name" {
  type        = string
  description = "Main db database name"
  default     = "todo"
}
