resource "kubernetes_namespace" "lb" {
  // Namespace depends on certificate bundle, because bundle needs to be removed after Kubernetes LB object. 
  // Bundle is referenced only in the kubernetes_annotations.lb which gets removed before LB object. 
  depends_on = [upcloud_loadbalancer_dynamic_certificate_bundle.lb]
  metadata {
    name   = var.kubernetes_namespace
    labels = { app = var.app_name }
  }
}

resource "kubernetes_annotations" "lb" {
  api_version = "v1"
  kind        = "Service"
  metadata {
    namespace = resource.kubernetes_namespace.lb.metadata[0].name
    name      = resource.kubernetes_service.lb.metadata[0].name
  }
  // Force to overwrite initial custom config.
  force = true
  annotations = {
    "service.beta.kubernetes.io/upcloud-load-balancer-config" = jsonencode({
      frontends : [
        {
          name : "http",
          mode : "http",
          rules : [
            {
              name : "http-to-https"
              actions : [
                {
                  "type" : "http_redirect",
                  "action_http_redirect" : {
                    "scheme" : "https"
                  }
                }
              ]
            }
          ]
        },
        {
          name : "https",
          mode : "http",
          properties : {
            http2_enabled : true
          }
          tls_configs : [
            {
              name : resource.upcloud_loadbalancer_dynamic_certificate_bundle.lb.name,
              certificate_bundle_uuid : resource.upcloud_loadbalancer_dynamic_certificate_bundle.lb.id
            }
          ]
        }
      ]
    })
  }
}

resource "kubernetes_service" "lb" {
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
  metadata {
    namespace = resource.kubernetes_namespace.lb.metadata[0].name
    name      = var.app_name
    labels    = { app = var.app_name }
    annotations = {
      "service.beta.kubernetes.io/upcloud-load-balancer-config" = jsonencode({
        frontends : [
          {
            name : "https"
            // Initially use TCP to prevent default TLS bundle creation.
            mode : "tcp",
            rules : [
              {
                // Block all traffic until TLS certificates are ready.
                name : "block-until-initialized"
                actions : [
                  {
                    "type" : "tcp_reject",
                    "action_tcp_reject" : {}
                  }
                ]
              }
            ]
          }
        ]
      })
    }
  }
  spec {
    type = "LoadBalancer"
    port {
      name        = "https"
      port        = 443
      protocol    = "TCP"
      target_port = "80"
    }
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
    selector = resource.kubernetes_deployment.app.spec[0].selector[0].match_labels
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    namespace = resource.kubernetes_namespace.lb.metadata[0].name
    name      = var.app_name
  }
  spec {
    replicas = "3"
    template {
      metadata { labels = { app = var.app_name } }
      spec {
        container {
          image             = "ghcr.io/upcloudltd/hello"
          image_pull_policy = "Always"
          name              = "hello"
        }
      }
    }
    selector {
      match_labels = { app = var.app_name }
    }
  }
}
