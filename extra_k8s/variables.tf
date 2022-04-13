variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "k8s_name" {
  type    = string
  default = "myk8s"
}
