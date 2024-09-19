terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  #   backend "s3" {
  #     bucket         = "infra-shakazu-bucket"
  #     key            = "state_files/lifi/development.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "lifi_tf_lock-dynamo-table"
  #     encrypt        = true
  #   }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Located in a different tfvars file
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

