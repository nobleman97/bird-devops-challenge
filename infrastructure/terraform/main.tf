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
resource "cloudflare_record" "birdy_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "birdy.${var.domain_name}"
  type    = "CNAME"                
  proxied = false
  content = aws_lb.this["app-alb"].dns_name

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

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"
  chart = "ingress-nginx/ingress-nginx"
  namespace = kubernetes_namespace.nginx.id
  version = "4.11.2"

  depends_on = [ kubernetes_namespace.nginx ]
}

resource "kubernetes_namespace" "birdy" {
  metadata {
    name = "birdy"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx-nginx"
  }
}

resource "kubernetes_namespace" "externaldns" {
  metadata {
    name = "externaldns"
  }
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

  depends_on = [ kubernetes_namespace.nginx ]
}

resource "helm_release" "bird" {
  name = "bird-api"
  chart = "../k8s/charts/bird"
  namespace = kubernetes_namespace.birdy.id
  version = "0.1.0"
  # upgrade_install = false

  # replace = true

  depends_on = [ kubernetes_namespace.birdy ]
}

resource "helm_release" "birdimage" {
  name = "bird-image-api"
  chart = "../k8s/charts/birdimage"
  namespace = kubernetes_namespace.birdy.id
  version = "0.1.0"

  replace = true

  depends_on = [ kubernetes_namespace.birdy ]
}

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
    namespace = kubernetes_namespace.externaldns.id
  }

  data = {
    "apiKey" = var.cloudflare_api_key
    "apiToken" = var.cloudflare_api_token
    "email" = var.cloudflare_email
    "zone_id" = var.cloudflare_zone_id
  }
}




# resource "helm_release" "externaldns" {
#   name       = "externaldns"
#   chart      = "bitnami/external-dns"
#   # namespace  = kubernetes_namespace.nginx.id
#   version = "8.3.8"

#   values = [ 
#     file("../k8s/values/external-dns-values.yaml")
#    ]
# }

# resource "helm_release" "externaldns" {
#   name       = "externaldns"
#   chart      = "external-dns/external-dns"
#   namespace  = kubernetes_namespace.externaldns.id
#   version = "1.15.0"

#   values = [ 
#     file("../k8s/values/sigs-values.yaml")
#    ]

#    depends_on = [ kubernetes_secret.cloudflare_api ]
# }


############################
# Monitoring
############################
# resource "helm_release" "elk" {
#   name = "elk"
#   chart = "../k8s/charts/elk"

#   namespace = kubernetes_namespace.monitoring.id
#   dependency_update = true
#   upgrade_install = false

#   depends_on = [ kubernetes_namespace.monitoring ]
# }

# output "elk_helm_output" {
#   value = helm_release.elk.metadata[0].notes
# }

