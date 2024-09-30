variable "dns_records" {
  description = "DNS records"
  type = map(object({
    prefix = string
    type = string
    proxied = bool
    load_balancer_ref = string
   }))
}

variable "k8s_namespaces" {
  description = "Namespaces for Kubernetes"
  type = map(string)
  default = {}
}

variable "cloudflare_api_token" {
  description = "An API token for CloudFlare"
  type        = string
  default     = ""
}

variable "cloudflare_api_key" {
  description = "An API key for CloudFlare"
  type        = string
  default     = ""
}

variable "cloudflare_email" {
  description = "An Email for CloudFlare"
  type        = string
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Zone ID for CloudFlare"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for External DNS"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = ""
  type = string
}


