output "public_ip_addresses" {
  value = {
    for ip in module.worker_servers :
    ip.instance.tags.Name => ip.instance.public_ip
    if ip.instance.public_ip != ""
  }
}

output "master_private_ip_addresses" {
  value = {
    for ip in module.master_servers :
    ip.instance.tags.Name => ip.instance.private_ip
    if ip.instance.public_ip == ""
  }
}

output "worker_private_ip_addresses" {
  value = {
    for ip in module.worker_servers :
    ip.instance.tags.Name => ip.instance.private_ip
    if ip.instance.public_ip == ""
  }
}

