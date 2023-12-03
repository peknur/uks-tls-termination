resource "upcloud_loadbalancer_dynamic_certificate_bundle" "lb" {
  name      = var.app_name
  hostnames = [for _, d in var.app_domains : d.hostname]
  key_type  = "rsa"
}
