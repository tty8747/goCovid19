variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "id_rsa_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to public key"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for k8s vpc"
}

variable "priv_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "pub_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "k8s_name" {
  type    = string
  default = "myk8s"
}

variable "openid_list" {
  type    = list(string)
  default = ["sts.amazonaws.com"]
}

variable "domain" {
  type    = string
  default = "ubukubu.ru"
}

variable "cname_record" {
  type    = string
  default = "app"
}

variable "cloudflare_email" {
  type = string
}

variable "cloudflare_api_key" {
  type = string
}

variable "db_name" {
  type    = string
  default = "test"
}

variable "db_user" {
  type    = string
  default = "someuser"
}

variable "db_pass" {
  type    = string
  default = "somepass"
}

variable "db_environment" {
  type    = string
  default = "dev"
}

variable "environments" {
  type    = list(string)
  default = ["test", "dev", "release"]
}

variable "app_name" {
  type    = string
  default = "gocovid"
}

variable "enable_ecr" {
  type    = bool
  default = false
}
