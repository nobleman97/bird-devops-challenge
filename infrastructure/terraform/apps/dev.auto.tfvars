
dns_records = {
  "birdy" = {
    prefix = "birdy"
    type = "CNAME"
    proxied = false
    load_balancer_ref = "app-alb"
  }

  "kibana" = {
    prefix = "kib"
    type = "CNAME"
    proxied = false
    load_balancer_ref = "app-alb"
  }

  "prometheus" = {
    prefix = "prom"
    type = "CNAME"
    proxied = false
    load_balancer_ref = "app-alb"
  }

  "grafana" = {
    prefix = "graf"
    type = "CNAME"
    proxied = false
    load_balancer_ref = "app-alb"
  }

  "birdimage" = {
    prefix = "birdimage"
    type = "CNAME"
    proxied = false
    load_balancer_ref = "app-alb"
  }
}

k8s_namespaces = {
  "birdy" = "birdy2"
  "monitoring" = "monitoring"
  "nginx-nginx" = "nginx-nginx"
  "externaldns" = "externaldns"
}