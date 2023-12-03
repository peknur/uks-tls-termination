data "cloudflare_zone" "lb" {
  for_each = { for d in var.app_domains : d.domain => d... }
  name     = each.key
}


resource "cloudflare_record" "lb" {
  count           = length(var.app_domains)
  zone_id         = data.cloudflare_zone.lb[var.app_domains[count.index].domain].zone_id
  name            = var.app_domains[count.index].hostname
  value           = resource.kubernetes_service.lb.status.0.load_balancer.0.ingress.0.hostname
  type            = "CNAME"
  ttl             = 600
  allow_overwrite = true
  proxied         = false
  tags            = []
  comment         = substr(format("UKS %s/service/%s (Terraform)", var.kubernetes_namespace, var.app_name), 0, 100)
}
