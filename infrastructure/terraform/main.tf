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
  key_name   = "lifi"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZqSEb+HU1fvJiLDmiZsPEAbFAhBC4onuB68X/kCqHr david@Ubuntu22"
}

######################
# EC2
######################
module "ec2" {
  source = "./modules/ec2"

  for_each = var.machines

  subnet_id       = module.network.subnets[each.value.subnet_object_name].id
  security_groups = [module.security_group[each.value.sg_identifier].security_groups.id]

  instance_type = each.value.instance_type
  instance_name = each.value.instance_name

  key_name = aws_key_pair.main.key_name

  user_data   = each.value.user_data
  volume_size = each.value.volume_size

  volume_type = each.value.volume_type
}






