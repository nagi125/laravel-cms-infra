variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "zone" {
  type = string
}

variable "domain" {
  type = string
}

variable "acm_id" {
  type = string
}