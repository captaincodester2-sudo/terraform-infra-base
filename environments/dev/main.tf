terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.16.4"

  backend "s3" {
    bucket         = "pochipa-tfstate-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "pochipa-tfstate-locks-dev"
  }
}

provider "aws" {
  region = var.region
}

module "network" {
  source      = "../../modules/network"
  region      = var.region
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "identity" {
  source      = "../../modules/identity"
  environment = var.environment
  bucket_name = var.bucket_name
  prefix      = var.prefix
}

module "kinesis" {
  source      = "../../modules/kinesis"
  shard_count = var.shard_count
  environment = var.environment
}

module "storage" {
  source        = "../../modules/storage"
  bucket_name   = var.bucket_name
  force_destroy = var.force_destroy
}