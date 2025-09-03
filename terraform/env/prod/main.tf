terraform {
  required_version = "~> 1.12"

  cloud {
    organization = "Philadelphia"

    workspaces {
      name = "grafana-prd"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = ">= 1.1.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "secretsmanager" {
}

module "grafana" {
  source = "../../modules/grafana"

  env_name = "prd"
  dev_mode = false
  # *.phila.gov
  acm_cert_arn = "arn:aws:acm:us-east-1:975050025792:certificate/dc0c25c0-84e6-45aa-90b5-590f8bd8296c"
  domain_name  = "citygeo-grafana.phila.gov"
  # Prod vpc
  vpc_id = "vpc-047bfd23682f9582f"
  # Prod subnet private zone A then B
  db_subnet_ids  = ["subnet-0d0d5a4bdbaf916d1", "subnet-00eb4cfd73abefd2e"]
  alb_subnet_ids = ["subnet-0d0d5a4bdbaf916d1", "subnet-00eb4cfd73abefd2e"]
  asg_subnet_ids = ["subnet-0d0d5a4bdbaf916d1", "subnet-00eb4cfd73abefd2e"]
  # Citygeo test vpc, citygeo prod vpc, mulesoft dev vpc, mulesoft prod vpc
  monitoring_source_cidrs = {
    citygeotestvpc = {
      name = "CityGeo Test VPC"
      cidr = "10.30.102.0/23"
    },
    citygeoprodvpc = {
      name = "CityGeo Prod VPC"
      cidr = "10.30.100.0/23"
    },
    mulesofttestvpc = {
      name = "Mulesoft Test VPC"
      cidr = "10.30.80.0/21"
    },
    mulesoftprodvpc = {
      name = "Mulesoft Prod VPC"
      cidr = "10.30.72.0/21"
    }
  }
  # EC2
  ec2_instance_type = "t3.large"
  ssh_key_name      = "eks-grafana"
  build_branch      = "nginx"
  # prod remote SG
  ssh_sg_id = "sg-0ef9b74fa74804bcb"
}
