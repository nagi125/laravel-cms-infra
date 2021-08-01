# Provider設定
provider "aws" {
  region = "ap-northeast-1"
}

variable "app_name" {
  type = string
  default = "laravel-cms"
}

variable "zone" {
  type = string
  default = "nagi-dev.jp"
}

variable "domain" {
  type = string
  default = "laravel.nagi-dev.jp"
}

variable "azs" {
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

module "iam" {
  source = "./iam"
  app_name = var.app_name
}

module "network" {
  source   = "./network"
  app_name = var.app_name
  azs      = var.azs
}

module "acm" {
  source   = "./acm"
  app_name = var.app_name
  zone     = var.zone
  domain   = var.domain
}