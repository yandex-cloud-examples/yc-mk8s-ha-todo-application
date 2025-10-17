terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "= 0.160.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 3.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
  }

  required_version = ">= 0.13"
}
