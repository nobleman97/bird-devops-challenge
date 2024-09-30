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

    backend "s3" {
      bucket         = "infra-shakazu-bucket"
      key            = "state_files/lifi/development_infra.tfstate"
      region         = "us-east-1"
      dynamodb_table = "lifi_tf_lock"
      encrypt        = true
    }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


