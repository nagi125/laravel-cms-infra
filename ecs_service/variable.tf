variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "https_listener_arn" {
  type = string
}

variable "iam_role_task_execution_arn" {
  type = string
}

variable "loki_user" {
  type = string
}

variable "loki_pass" {
  type = string
}