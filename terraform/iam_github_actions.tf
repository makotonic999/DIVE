###############################################################################
# terraform/iam_github_actions.tf
# GitHub Actions (OIDC) 用 IAM ロール — DIVE の CI/CD 用
#
# 方針:
#   - OIDCプロバイダは既存（ポートフォリオ構築時に作成済み）を data で参照
#   - このロールは DIVE リポジトリ（makotonic999/DIVE）からのみ引き受け可能
#   - 権限は「DIVEのデプロイ」「Terraform操作」「管理アカウントのRoute53ロールをassume」
#     に必要な最小限。S3バケット名はサフィックス変更に耐えるようワイルドカード。
###############################################################################

# 既存の GitHub OIDC プロバイダを参照（新規作成しない）
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 現在のdevアカウントID取得（ARN組み立て用）
data "aws_caller_identity" "current" {}

###############################################################################
# GitHub Actions が引き受けるロール
###############################################################################
resource "aws_iam_role" "github_actions_dive" {
  name = "GitHubActionsDiveDeployRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        # AssumeRoleWithWebIdentity に加え TagSession も許可。
        # configure-aws-credentials がセッションタグを付与する場合に必要。
        Action = [
          "sts:AssumeRoleWithWebIdentity",
          "sts:TagSession"
        ]
        Condition = {
          StringLike = {
            # DIVE リポジトリからのアクセスを許可。
            # 大文字小文字やref表記の揺れを吸収するため、前後をワイルドカードで囲む
            # （ポートフォリオで実績のあるパターンに合わせる）。
            "token.actions.githubusercontent.com:sub" = "repo:makotonic999/*DIVE*:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

###############################################################################
# 権限ポリシー
###############################################################################
resource "aws_iam_role_policy" "github_actions_dive" {
  name = "DiveDeployAndTerraformPolicy"
  role = aws_iam_role.github_actions_dive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ----- コンテンツデプロイ: S3（DIVEバケット。サフィックス変化に対応しワイルドカード） -----
      {
        Sid    = "S3Deploy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-site-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-site-*/*"
        ]
      },
      # ----- コンテンツデプロイ: CloudFront invalidation -----
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "*"
      },
      # ----- Terraform: state用S3バケットへのアクセス -----
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::okadachikuro-dev-tfstate",
          "arn:aws:s3:::okadachikuro-dev-tfstate/*"
        ]
      },
      # ----- Terraform: インフラ管理に必要なサービス群 -----
      # DIVEのインフラ（S3/CloudFront/OAC/CloudFront Function/IAM）を plan/apply するための権限
      {
        Sid    = "TerraformManage"
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudfront:*",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:GetOpenIDConnectProvider",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      # ----- クロスアカウント: 管理アカウントのRoute53ロールをassume -----
      {
        Sid    = "AssumeRoute53CrossAccount"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = var.route53_cross_account_role_arn
      }
    ]
  })
}

###############################################################################
# 出力
###############################################################################
output "github_actions_role_arn" {
  description = "GitHub Actions が引き受けるIAMロールのARN。GitHub Secrets (AWS_ROLE_ARN) に登録する。"
  value       = aws_iam_role.github_actions_dive.arn
}
