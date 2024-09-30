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
module "master_servers" {
  source = "./modules/ec2"

  for_each = var.master_servers

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

module "worker_servers" {
  source = "./modules/ec2"

  for_each = var.worker_servers

  subnet_id       = module.network.subnets[each.value.subnet_object_name].id
  security_groups = [module.security_group[each.value.sg_identifier].security_groups.id]

  instance_type        = each.value.instance_type
  instance_name        = each.value.instance_name
  iam_instance_profile = each.value.iam_instance_profile

  key_name = aws_key_pair.main.key_name

  user_data   = each.value.user_data
  volume_size = each.value.volume_size

  volume_type = each.value.volume_type

  depends_on = [ module.master_servers ]
}








