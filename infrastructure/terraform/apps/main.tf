######################
# DNS
######################
data "aws_alb" "this" {
  name = "app-alb"
}

resource "cloudflare_record" "app_dns" {
  for_each = var.dns_records 

  zone_id = var.cloudflare_zone_id
  name    = "${each.value.prefix}.${var.domain_name}"
  type    = each.value.type  
  proxied = each.value.proxied
  content = data.aws_alb.this[each.value.load_balancer_ref].dns_name

  timeouts {
    create = "5m"
  }

  lifecycle {
    ignore_changes = [proxied, ttl]
    create_before_destroy = false
  }
}

# ########################
# # Kubernetes
# ########################

# ----- Namespaces  ----------
resource "kubernetes_namespace" "this" {
  for_each = var.k8s_namespaces

  metadata {
    name = each.key
  }
}

# -----  Helm Releases ---------
resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"
  chart = "ingress-nginx/ingress-nginx"
  namespace = kubernetes_namespace.this["nginx-nginx"].id
  version = "4.11.2"

  depends_on = [ kubernetes_namespace.this["nginx-nginx"] ]
}

resource "helm_release" "cert-manager" {
  name = "cert-manager"
  chart = "cert-manager/cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version = "1.15.3"

  values = [
      file("../../k8s/values/cm-values.yaml") 
  ]

  depends_on = [ kubernetes_namespace.this["nginx-nginx"] ]
}

resource "helm_release" "bird" {
  name = "bird-api"
  chart = "../k8s/charts/bird"
  namespace = kubernetes_namespace.this["birdy"].id
  version = "0.1.0"

  depends_on = [ kubernetes_namespace.this["birdy"] ]
}

resource "helm_release" "birdimage" {
  name = "bird-image-api"
  chart = "../../k8s/charts/birdimage"
  namespace = kubernetes_namespace.this["birdy"].id
  version = "0.1.0"

  replace = true

  depends_on = [ kubernetes_namespace.this["birdy"] ]
}

# resource "helm_release" "prometheus" {
#   name = "prometheus"
#   chart = "prometheus-community/prometheus"
#   namespace = kubernetes_namespace.this["monitoring"].id
#   version = "25.27.0"

#   values = [
#     "${file("../../k8s/values/prom-values.yaml")}"
#   ]
# }

# resource "helm_release" "grafana" {
#   name = "grafana"
#   chart = "grafana/grafana"
#   namespace = kubernetes_namespace.this["monitoring"].id
#   version = "8.5.1"

#   values = [
#     "${file("../../k8s/values/grafana-values.yaml")}"
#   ]

#   depends_on = [ kubernetes_secret.grafana_smtp_secret ]
# }

resource "helm_release" "elk" {
  name = "elk"
  chart = "../k8s/charts/elk"

  namespace = kubernetes_namespace.this["monitoring"].id
  dependency_update = true
  # upgrade_install = true

  depends_on = [ kubernetes_namespace.this["monitoring"] ]
}


## --------   Secrets  ---------

resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-key-secret"
    namespace = "cert-manager"
  }

  data = {
    "api-key" = var.cloudflare_api_key
    "api-token" = var.cloudflare_api_token
  }

  depends_on = [ helm_release.cert-manager ]
}

resource "kubernetes_secret" "cloudflare_api" {
  metadata {
    name      = "cloudflare-api-cred"
    namespace = kubernetes_namespace.this["externaldns"].id
  }

  data = {
    "apiKey" = var.cloudflare_api_key
    "apiToken" = var.cloudflare_api_token
    "email" = var.cloudflare_email
    "zone_id" = var.cloudflare_zone_id
  }
}

resource "kubernetes_secret" "grafana_smtp_secret" {
  metadata {
    name      = "grafana-smtp-secret"
    namespace = kubernetes_namespace.this["monitoring"].id
  }

  data = {
    password = var.smtp_password  
  }
}

