# Main EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.app_name}-${var.env_name}"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    subnet_ids              = var.eks_subnet_ids
    security_group_ids      = [aws_security_group.eks_control.id]
  }

  access_config {
    authentication_mode = "API"
  }

  encryption_config {
    provider {
      key_arn = data.aws_ssm_parameter.kms_arn.value
    }
    resources = ["secrets"]
  }

  version = var.kubernetes_version

  depends_on = [aws_iam_role_policy_attachments_exclusive.eks]
}

resource "aws_eks_access_entry" "admins" {
  for_each      = toset(var.eks_admins_iam_arns)
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
}

# Gives access to an arbitrary list of IAM roles,
# used mainly to allow viewing EKS resources in the AWS
# console
resource "aws_eks_access_policy_association" "admins" {
  for_each      = toset(var.eks_admins_iam_arns)
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}

# Source: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon#example-iam-role-for-eks-addon-vpc-cni-with-aws-managed-policy
data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
// These 3 addons simply have to be installed via Terraform,
// they are required for any core component of Kubernetes to work.
// There are other addons available that we do use, but we install
// those through Flux for more consistent DevOps tooling.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.eks_addon_vpc_cni.arn
  addon_version            = "v1.20.4-eksbuild.2"

  depends_on = [aws_iam_role_policy_attachments_exclusive.eks_addon_vpc_cni]
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = "v1.12.1-eksbuild.2"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.3-eksbuild.4"
}

# Allows creating EBS PVC
#resource "aws_eks_addon" "ebs_csi_driver" {
#  cluster_name             = aws_eks_cluster.main.name
#  addon_name               = "aws-ebs-csi-driver"
#  addon_version            = "v1.29.1-eksbuild.1"
#  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn
#}
#
## Allows creating EFS PVC
#resource "aws_eks_addon" "efs_csi_driver" {
#  cluster_name             = aws_eks_cluster.main.name
#  addon_name               = "aws-efs-csi-driver"
#  addon_version            = "v2.1.12-eksbuild.1"
#  service_account_role_arn = aws_iam_role.eks_efs_csi_driver.arn
#}

# Tag the builtin security group
#resource "aws_ec2_tag" "eks_cluster_sg" {
#  resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
#  key         = "karpenter.sh/discovery-${var.app_name}-${var.env_name}"
#  value       = "yes"
#}

# Tags the subnets that Karpenter will use
resource "aws_ec2_tag" "eks_subnets_karpenter" {
  for_each = toset(var.eks_subnet_ids)

  resource_id = each.value
  key         = "karpenter.sh/discovery-${var.app_name}-${var.env_name}"
  value       = "yes"
}
#
## Tags the subnets that the AWS load balancer controller
## can use for the ingress ALB
#resource "aws_ec2_tag" "eks_subnets_elb_internal" {
#  for_each = toset(var.eks_subnet_ids)
#
#  resource_id = each.value
#  key         = "kubernetes.io/role/internal-elb"
#  value       = "1"
#}
#
## Tells the AWS load balancer controller that
## these subnets are not solely used by it
#resource "aws_ec2_tag" "eks_subnets_elb_cluster" {
#  for_each = toset(var.eks_subnet_ids)
#
#  resource_id = each.value
#  key         = "kubernetes.io/cluster/${var.app_name}-${var.env_name}"
#  value       = "shared"
#}

# Karpenter runs in Fargate, so it needs a Fargate profile
resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${var.app_name}-${var.env_name}-karpenter"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.eks_subnet_ids

  selector {
    namespace = "karpenter"
  }
}
