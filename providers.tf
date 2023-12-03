terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubernetes_config
}

provider "upcloud" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
