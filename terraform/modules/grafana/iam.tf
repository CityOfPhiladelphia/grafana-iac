resource "aws_iam_policy" "kms" {
  name        = "${var.app_name}-${var.env_name}-kms"
  description = "Enables use of common KMS key"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:GenerateDataKeyPair*",
        ]
        Effect   = "Allow"
        Resource = data.aws_ssm_parameter.kms_arn.value
      },
      {
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Effect   = "Allow"
        Resource = data.aws_ssm_parameter.kms_arn.value
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = true
          }
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_policy" "s3" {
  name        = "${var.app_name}-${var.env_name}-s3"
  description = "Enables read write to s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_policy" "s3_eks" {
  name        = "${var.app_name}-${var.env_name}-s3-eks"
  description = "Enables read write to s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.eks.arn,
          "${aws_s3_bucket.eks.arn}/*"
        ]
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_policy" "ssm" {
  name        = "${var.app_name}-${var.env_name}-ssm"
  description = "Get SSM Parameters"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = local.default_tags
}

# Role for ESO to retrieve parameters from ParameterStore
resource "aws_iam_role" "external_secrets" {
  name = "${var.app_name}-${var.env_name}-external-secrets-irsa"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachments_exclusive" "external_secrets" {
  role_name = aws_iam_role.external_secrets.name
  policy_arns = [
    aws_iam_policy.ssm.arn,
    aws_iam_policy.kms.arn
  ]
}

module "aws_load_balancer_controller_policy" {
  source      = "git::https://github.com/CityOfPhiladelphia/citygeo-terraform-eks-helpers.git//aws-load-balancer-controller-policy?ref=502744b80a1661607121a80c3561f879555d6c30"
  policy_name = "${var.app_name}-${var.env_name}-eks-alb-controller"
}

resource "aws_iam_role" "eks_alb_controller" {
  name = "${var.app_name}-${var.env_name}-eks-alb-controller"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_alb_controller" {
  role_name = aws_iam_role.eks_alb_controller.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    module.aws_load_balancer_controller_policy.arn
  ]
}
resource "aws_iam_role" "eks" {
  name = "${var.app_name}-${var.env_name}-eks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "eks" {
  role_name = aws_iam_role.eks.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}


resource "aws_iam_role" "eks_addon_vpc_cni" {
  name = "${var.app_name}-${var.env_name}-eks-addon-vpc-cni"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_addon_vpc_cni" {
  role_name = aws_iam_role.eks_addon_vpc_cni.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

// Create the service role that mimir assumes
resource "aws_iam_role" "mimir" {
  name = "${var.app_name}-${var.env_name}-mimir-irsa"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:mimir:mimir-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "mimir" {
  role_name = aws_iam_role.mimir.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    aws_iam_policy.s3_eks.arn
  ]
}

// Create the service role that loki assumes
resource "aws_iam_role" "loki" {
  name = "${var.app_name}-${var.env_name}-loki-irsa"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:loki:loki-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "loki" {
  role_name = aws_iam_role.loki.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    aws_iam_policy.s3_eks.arn
  ]
}

// Create the service role that EBS CSI driver assumes
resource "aws_iam_role" "eks_ebs_csi_driver" {
  name = "${var.app_name}-${var.env_name}-eks-ebs-csi-driver"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_ebs_csi_driver" {
  role_name = aws_iam_role.eks_ebs_csi_driver.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

// Source: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_fargate_profile#example-iam-role-for-eks-fargate-profile
resource "aws_iam_role" "eks_fargate" {
  name = "${var.app_name}-${var.env_name}-eks-fargate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_fargate" {
  role_name = aws_iam_role.eks_fargate.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
    # Todo: something better than this
    # "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/KarpenterControllerPolicy-airflow-test"
  ]
}

// Assume role
resource "aws_iam_policy" "sts" {
  name        = "${var.app_name}-${var.env_name}-sts-assume-role"
  description = "Assumes a role in CityGeo AWS account"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::880708401960:role/GrafanaMonitoringAssumedRole"
      }
    ]
  })

  tags = local.default_tags
}

// Create the service role that grafana web assumes
resource "aws_iam_role" "grafana" {
  name = "${var.app_name}-${var.env_name}-grafana-irsa"

  assume_role_policy = jsonencode({
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
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:grafana:grafana-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "grafana" {
  role_name = aws_iam_role.grafana.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    aws_iam_policy.sts.arn,
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  ]
}

// EC2 role
resource "aws_iam_role" "ec2" {
  name = "${var.app_name}-${var.env_name}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.app_name}-${var.env_name}-ec2"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachments_exclusive" "ec2" {
  role_name = aws_iam_role.ec2.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    aws_iam_policy.s3.arn,
    aws_iam_policy.ssm.arn,
    aws_iam_policy.sts.arn,
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  ]
}
