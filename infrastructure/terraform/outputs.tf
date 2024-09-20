output "public_ip_addresses" {
  value = {
    for ip in module.ec2 :
    ip.instance.tags.Name => ip.instance.public_ip
    if ip.instance.public_ip != ""
  }
}

output "private_ip_addresses" {
  value = {
    for ip in module.ec2 :
    ip.instance.tags.Name => ip.instance.private_ip
    if ip.instance.public_ip == ""
  }
}

# output "elk_helm_output" {
#   value = helm_release.elk.metadata[0].notes
# }