#########################
# Networking
#########################
module "network" {
  source = "./modules/vpc"

  log_bucket_name         = var.log_bucket_name
  name_prefix             = var.name_prefix
  enable_internet_gateway = var.enable_internet_gateway
  vpc_cidr                = var.vpc_cidr

  subnets = var.vpc_subnets
}

#####################
# Security Group
#####################
module "security_group" {
  source = "./modules/security_groups"

  for_each = var.security_groups

  sg_name              = each.value.sg_name
  sg_description       = each.value.sg_description
  vpc_id               = module.network.vpc.id
  security_group_rules = each.value.security_group_rules
}

#####################
# Key Pair
#####################
resource "aws_key_pair" "main" {
  key_name   = var.instance_key.name
  public_key = var.instance_key.public_key
}

######################
# EC2
######################
module "ec2" {
  source = "./modules/ec2"

  for_each = var.machines

  subnet_id       = module.network.subnets[each.value.subnet_object_name].id
  security_groups = [module.security_group[each.value.sg_identifier].security_groups.id]

  instance_type        = each.value.instance_type
  instance_name        = each.value.instance_name
  iam_instance_profile = each.value.iam_instance_profile

  key_name = aws_key_pair.main.key_name

  user_data   = each.value.user_data
  volume_size = each.value.volume_size

  volume_type = each.value.volume_type
}

######################
# DNS
######################
resource "cloudflare_record" "app_dns" {
  for_each = var.dns_records 

  zone_id = var.cloudflare_zone_id
  name    = "${each.value.prefix}.${var.domain_name}"
  type    = each.value.type  
  proxied = each.value.proxied
  content = aws_lb.this[each.value.load_balancer_ref].dns_name

  timeouts {
    create = "5m"
  }

  lifecycle {
    ignore_changes = [proxied, ttl]
    create_before_destroy = false
  }
}


########################
# Kubernetes
########################


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
      file("../k8s/values/cm-values.yaml") 
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
  chart = "../k8s/charts/birdimage"
  namespace = kubernetes_namespace.this["birdy"].id
  version = "0.1.0"

  replace = true

  depends_on = [ kubernetes_namespace.this["birdy"] ]
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  chart = "prometheus-community/prometheus"
  namespace = kubernetes_namespace.this["monitoring"].id
  version = "25.27.0"

  values = [
    "${file("../k8s/values/prom-values.yaml")}"
  ]
}

resource "helm_release" "grafana" {
  name = "grafana"
  chart = "grafana/grafana"
  namespace = kubernetes_namespace.this["monitoring"].id
  version = "8.5.1"

  values = [
    "${file("../k8s/values/grafana-values.yaml")}"
  ]
}

# @Dev: Remove Kibana from chart when installing initially. Add back on second run
# resource "helm_release" "elk" {
#   name = "elk"
#   chart = "../k8s/charts/elk"

#   namespace = kubernetes_namespace.this["monitoring"].id
#   dependency_update = true
#   # upgrade_install = true

#   depends_on = [ kubernetes_namespace.this["monitoring"] ]
# }


# --------   Secrets  ---------

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






