# CityGeo Grafana

## Components

### Containerized

* Grafana - Web Dashboard
* Loki - Log collection and analysis
* Mimir - Metric collection and analysis

### Uncontainerized

* Alloy - Meta monitoring tool. Installed on the base ec2 for maximum metric collection information

## Design Choices

### Server Infrastructure

#### Kubernetes vs. docker-compose

As of now, this project utilizes `docker-compose` on a single ec2 instance instead of a Kubernetes cluster. This is a small internal tool in which we can handle planned outages for maintenance, so we chose to avoid Kubernetes due to the control plane costs. In the future, if this tool continues to be utilized, we will migrate to Kubernetes.

Downsides of using `docker-compose` over Kubernetes

* No HA (Mimir is difficult to cluster without Kubernetes pod networking)
* Grafana, Mimir, and Loki all have to share the same resources on the same machine

Upsides of using `docker-compose` over Kubernetes:

* No EKS control plane costs
* Can run on just one EC2

#### Server provisioning

Upon launching an EC2 from the autoscaling group (or directly from the launch template), a short userdata script runs which downloads this Git repository and then executes the `server/build.sh` script.

The `servers/build.sh` script is a bit longer, it takes about 3 minutes to run and mostly just involves installing the required tools (mainly Docker), then parameterizes the docker configuration with values from the AWS infrastructure, then starts the docker-compose stack.

### AWS Infrastructure

AWS infrastructure is deployed with Terraform. Although the application stack is currently deployed as a monolithic server, the AWS infrastructure was still designed in a way to enable future migration to a clustered Kuberenetes stack.

#### Architecture Diagram

![architecture diagram](docs/arch_diagram.svg)

### Terraform infrastructure

Although there is only one environment of Grafana (prod), the terraform infrastructure was designed to enable multiple environments if the need arises. There is a primary module in [terraform/modules/grafana](terraform/modules/grafana) which essentially includes the entire core infrastructure. The environments in the [terraform/env](terraform/env) folder each use this module with variables relevant to that environment. There is also an inline project in [terraform/common](terraform/common) which creates the common KMS. Any parameters that may be needed by the server (such as secrets, s3 name, rds url) are also deployed as SSM (systems manager) parameters.
