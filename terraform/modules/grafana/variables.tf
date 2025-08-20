variable "env_name" {
  type = string
}

variable "app_name" {
  type    = string
  default = "grafana"
}

variable "dev_mode" {
  type        = bool
  description = "Enable to disable any type of deletion protection"
}

# VPC
variable "vpc_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "alb_subnet_ids" {
  type = list(string)
}

variable "asg_subnet_ids" {
  type = list(string)
}

# ALB
variable "monitoring_source_cidrs" {
  type = map(object({
    name = string
    cidr = string
  }))
  description = "List of source CIDR blocks that are allowed to input Loki and Prometheus monitoring data"
}

# EC2
variable "ec2_instance_type" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "ssh_sg_id" {
  type = string
}

## Provisioner

