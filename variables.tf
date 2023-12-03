variable "app_name" {
  default     = "myapp"
  description = "Name for the application."
  type        = string
}

variable "app_domains" {
  description = "Application domains to serve"
  type = list(object({
    domain   = string
    hostname = string
  }))
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "kubernetes_config" {
  description = "Kubernetes config path"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
}
