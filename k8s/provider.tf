terraform {
  backend "http" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}


provider "tls" {}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "aws" {
  region = var.region
  # shared_credentials_files = ["~/.aws/credentials"]
  # profile                  = "tty8747"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

provider "null" {}
