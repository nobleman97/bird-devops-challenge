name_prefix             = "lifi"
log_bucket_name         = "s3-access-logs-dev-1"
vpc_cidr                = "10.0.0.0/16"
enable_internet_gateway = true
domain_name             = "osose.xyz"

vpc_subnets = {
  "AZ-1-pub_sub-1" = {
    cidr_block        = "10.0.10.0/24"
    availability_zone = "us-east-1a"
    routes = [
      {
        name                   = "AZ-1-pub_sub-1-to-internet"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id             = "activated"
      }
    ]
    map_public_ip_on_launch = true
    is_private              = false
  }

  "AZ-2-pub_sub-1" = {
    cidr_block        = "10.0.12.0/24"
    availability_zone = "us-east-1b"
    routes = [
      {
        name                   = "AZ-2-pub_sub-1-to-internet"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id             = "activated"
      }
    ]
    map_public_ip_on_launch = true
    is_private              = false
  }

  "AZ-1-priv_sub-1" = {
    cidr_block              = "10.0.20.0/24"
    availability_zone       = "us-east-1a"
    enable_nat              = true
    is_private              = true
    map_public_ip_on_launch = false
    nat_public_subnet_key   = "AZ-1-pub_sub-1"
    routes = [
      {
        name                   = "AZ-1-priv_sub-1-to-NAT"
        destination_cidr_block = "0.0.0.0/0"
        # gateway_id             = "activated"
        nat_gateway_ref = "AZ-1-priv_sub-1"
      }
    ]
  }

  "AZ-1-priv_sub-2" = {
    cidr_block              = "10.0.30.0/24"
    availability_zone       = "us-east-1a"
    enable_nat              = false
    shared_route_table_ref  = "AZ-1-priv_sub-1"
    is_private              = true
    map_public_ip_on_launch = false
    # nat_public_subnet_key   = "AZ-1-pub_sub-1"
    routes = [
      {
        name                   = "AZ-1-priv_sub-2-to-NAT"
        destination_cidr_block = "0.0.0.0/0"
        # gateway_id             = "activated"
        nat_gateway_ref = "AZ-1-priv_sub-1"
      }
    ]
  }
}

security_groups = {

  "alb-sg" = {
    sg_name        = "alb-sg"
    sg_description = "Security group for Application Load Balancer"

    security_group_rules = {
      "alb_http" = {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "alb_https" = {
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "alb_egress" = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  "bastion_sg" = {
    sg_name        = "bastion_sg"
    sg_description = "Security group for Bastion Instances"

    security_group_rules = {
      "bastion_kube_api" = {
        type        = "ingress"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks =  ["102.0.0.0/8", "197.210.0.0/16" ]
      }

      "bastion_ssh" = {
        type        = "ingress"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["102.0.0.0/8", "197.210.0.0/16" ]
      }

      "bastion_http" = {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["102.0.0.0/8", "197.210.0.0/16" ]
      }

      "bastion_egress" = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  "cluster_sg" = {
    sg_name        = "app-sg"
    sg_description = "Security group for App Instances"

    security_group_rules = {

      "cluster_coredns_udp" = {
        type        = "ingress"
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_coredns_tcp" = {
        type        = "ingress"
        from_port   = 53
        to_port     = 53
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_http" = {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        # source_security_group_id = ["alb-sg"]
      }

      "cluster_https" = {
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_kube_api" = {
        type        = "ingress"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_kubelet" = {
        type        = "ingress"
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_healthchecks" = {
        type        = "ingress"
        from_port   = 10255
        to_port     = 10255
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_vxlan" = {
        type        = "ingress"
        from_port   = 8472
        to_port     = 8472
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      "cluster_ssh" = {
        type        = "ingress"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
      }

      "cluster_egress" = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}

### --- Machines ----
machines = {
  "machine_1" = {
    instance_type        = "t3.medium"
    instance_name        = "master"
    network_object_name  = "primary"
    subnet_object_name   = "AZ-1-priv_sub-1"
    sg_identifier        = "cluster_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size          = 30
    volume_type          = "gp2"
    user_data            = "../scripts/k3s_master.sh"
  }

  "machine_2" = {
    instance_type        = "t3.medium"
    instance_name        = "slave_1"
    network_object_name  = "primary"
    subnet_object_name   = "AZ-1-priv_sub-2"
    sg_identifier        = "cluster_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size          = 30
    volume_type          = "gp2"
    user_data            = "../scripts/k3s_worker.sh"
  }

  "jumpbox" = {
    instance_type       = "t2.micro"
    instance_name       = "jumpbox"
    network_object_name = "primary"
    subnet_object_name  = "AZ-1-pub_sub-1"
    sg_identifier       = "bastion_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size         = 30
    volume_type         = "gp2"
    user_data           = "../scripts/apt_update.sh"
  }
}

albs = [
  {
    name                = "app-alb"
    internal            = false
    load_balancer_type  = "application"
    security_group_tags = ["alb-sg"]

    target_groups = [
      {
        name        = "app"
        port        = 80
        protocol    = "HTTP"
        machine_ref = "machine_1"
        health_check = {
          path                = "/"
          interval            = 30
          timeout             = 5
          healthy_threshold   = 5
          unhealthy_threshold = 2
        }

        listeners = [
          {
            id       = "http"
            port     = 80
            protocol = "HTTP"
            rules = [{
              path_pattern = "/*"
              priority     = 1
            }]
          }
        ]
      }
    ]
  }
]