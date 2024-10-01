resource "aws_iam_policy" "kubernetes_s3_policy" {
  name        = "KubernetesS3BucketPolicy"
  description = "Policy for Kubernetes nodes to manage AWS S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::infra-shakazu-bucket"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          
        ]
        Resource = "arn:aws:s3:::infra-shakazu-bucket/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:305406349585:table/lifi_tf_lock"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "kubernetes_nodes_role" {
  name = "KubernetesNodesRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "kubernetes_nodes_policy_attachment" {
  role       = aws_iam_role.kubernetes_nodes_role.name
  policy_arn = aws_iam_policy.kubernetes_s3_policy.arn
}


resource "aws_iam_instance_profile" "kubernetes_nodes_instance_profile" {
  name = "KubernetesNodesInstanceProfile"
  role = aws_iam_role.kubernetes_nodes_role.name
}
