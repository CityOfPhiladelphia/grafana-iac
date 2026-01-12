// This file organizes all resources for bootstrapping
// Since these resources are only created once at initial creation,
// I thought it would be easier to have them separate from the rest
// of the files

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.main.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
}

resource "aws_eks_node_group" "bootstrap" {
  count = var.bootstrap ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "bootstrap"
  version         = aws_eks_cluster.main.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_role_arn   = aws_iam_role.bootstrap[0].arn
  subnet_ids      = var.eks_subnet_ids
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachments_exclusive.bootstrap[0]
  ]
}

resource "aws_iam_role" "bootstrap" {
  count = var.bootstrap ? 1 : 0

  name = "${var.app_name}-${var.env_name}-bootstrap"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "bootstrap" {
  count     = var.bootstrap ? 1 : 0
  role_name = aws_iam_role.bootstrap[0].name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}


