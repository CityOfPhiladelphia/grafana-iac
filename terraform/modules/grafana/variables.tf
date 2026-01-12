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

variable "domain_name" {
  type = string
}

variable "bootstrap" {
  type        = bool
  description = "Set this to true on initial cluster creation to create an initial managed node group just for bootstrapping, then set to false after Flux is set-up"
}


# VPC
variable "vpc_id" {
  type = string
}

variable "eks_subnet_ids" {
  type = list(string)
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

variable "acm_cert_arn" {
  type = string
}

# ALB
variable "monitoring_source_cidrs" {
  type = map(object({
    name = string
    cidr = string
  }))
  description = "List of source CIDR blocks that are allowed to input Loki and Prometheus monitoring data"
}

# RDS
variable "rds_multi_az" {
  type    = bool
  default = false
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

variable "ec2_ami_id" {
  type = string
}

variable "build_branch" {
  type        = string
  default     = "main"
  description = "What git branch to checkout before running the build script. Defaults to `main`."
}

# EKS
variable "kubernetes_version" {
  type = string
}

variable "eks_admins_iam_arns" {
  type = list(string)
}

## Provisioner

