module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.15.1"

  cluster_name = aws_eks_cluster.main.name

  # Names
  iam_policy_name    = "${var.app_name}-${var.env_name}-karpenter-controller"
  iam_role_name      = "${var.app_name}-${var.env_name}-karpenter-controller"
  node_iam_role_name = "${var.app_name}-${var.env_name}-karpenter-node"
  queue_name         = "${var.app_name}-${var.env_name}-karpenter"
  # They don't let you disable the name prefix for rules
  rule_name_prefix              = "${substr(var.app_name, 0, 6)}-${var.env_name}-karp-"
  iam_policy_use_name_prefix    = false
  iam_role_use_name_prefix      = false
  node_iam_role_use_name_prefix = false
  # Attach additional IAM policies to the Karpenter node and controller IAM role
  node_iam_role_additional_policies = {
    KMS = aws_iam_policy.kms.arn
  }
  iam_role_policies = {
    KMS = aws_iam_policy.kms.arn
  }

  queue_managed_sse_enabled       = false
  queue_kms_master_key_id         = data.aws_ssm_parameter.kms_arn.value
  create_pod_identity_association = false
  iam_role_override_assume_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowClusterToAssume"
          Action = "sts:AssumeRoleWithWebIdentity"
          Effect = "Allow"
          Principal = {
            Federated = aws_iam_openid_connect_provider.main.arn
          }
          Condition = {
            StringEquals = {
              "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
            }
          }
        }
      ]
    })
  ]
  enable_spot_termination         = true
  node_iam_role_attach_cni_policy = true

  tags = local.default_tags
}
