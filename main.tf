# Provider設定
provider "aws" {
  region = "ap-northeast-1"
}

variable "DB_NAME" {
  type = string
}

variable "DB_MASTER_NAME" {
  type = string
}

variable "DB_MASTER_PASS" {
  type = string
}

variable "LOKI_USER" {
  type = string
}

variable "LOKI_PASS" {
  type = string
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

module "elb" {
  source = "./elb"

  app_name = var.app_name

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  zone              = var.zone
  domain            = var.domain
  acm_id            = module.acm.acm_id
}

module "rds" {
  source = "./rds"

  app_name = var.app_name

  vpc_id     = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  database_name   = var.DB_NAME
  master_username = var.DB_MASTER_NAME
  master_password = var.DB_MASTER_PASS
}

module "elasticache" {
  source = "./elasticache"

  app_name = var.app_name

  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}

module "ecs_cluster" {
  source = "./ecs_cluster"
  app_name = var.app_name
}

module "ecs_service" {
  source = "ecs_service"

  app_name = var.app_name

  cluster_name       = module.ecs_cluster.cluster_name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  https_listener_arn = module.elb.https_listener_arn
  iam_role_task_execution_arn = module.iam.iam_role_task_execution_arn

  loki_user = var.LOKI_USER
  loki_pass = var.LOKI_PASS
}

module "ec2" {
  source = "./ec2"
  app_name = var.app_name

  vpc_id    = module.network.vpc_id
  subnet_id = module.network.ec2_subnet_id
}