###############################################################################
# terraform/bootstrap/main.tf
# ブートストラップ — CI/CDの「土台」を管理する（アプリインフラとは別ステート）
#
# 目的:
#   GitHub Actions が引き受ける IAM ロールを定義する。
#   このディレクトリは「人間が手元でのみ apply する」もので、CIからは触らない。
#   （CIロールが自分自身の権限を書き換えられる状態は権限昇格リスクになるため、
#    IAM管理はアプリインフラ(../)から分離する。）
#
# ステート:
#   共有バケット okadachikuro-dev-tfstate の別キー dive/bootstrap/terraform.tfstate
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "s3" {
    bucket       = "okadachikuro-dev-tfstate"
    key          = "dive/bootstrap/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    profile      = "dev"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.dev_account_profile != "" ? var.dev_account_profile : null

  default_tags {
    tags = {
      Project   = "DIVE"
      ManagedBy = "Terraform"
      Component = "bootstrap"
    }
  }
}

# 既存の GitHub OIDC プロバイダを参照（新規作成しない）
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

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
        # AssumeRoleWithWebIdentity に加え TagSession も許可
        # （configure-aws-credentials がセッションタグを付与する場合に必要）。
        Action = [
          "sts:AssumeRoleWithWebIdentity",
          "sts:TagSession"
        ]
        Condition = {
          StringLike = {
            # GitHubの新しいsub形式に対応:
            #   repo:makotonic999@<ownerID>/DIVE@<repoID>:ref:refs/heads/main
            # 名前直後の "@<数値ID>" をワイルドカードで吸収（CloudTrailで確認済み）。
            "token.actions.githubusercontent.com:sub" = "repo:makotonic999*/DIVE*:*"
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
# 権限ポリシー — アプリインフラ(../)の管理とデプロイに必要な分のみ。
# IAMの書き込み権限は与えない（IAMはこのbootstrapで手元管理するため）。
###############################################################################
resource "aws_iam_role_policy" "github_actions_dive" {
  name = "DiveDeployAndTerraformPolicy"
  role = aws_iam_role.github_actions_dive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ----- S3: DIVEコンテンツバケット + Terraform管理（バケット作成/設定含む） -----
      # アプリ側 terraform が S3バケットやポリシー等を管理するため s3:* を許可。
      # バケットはDIVE命名に限定してスコープを絞る。
      {
        Sid    = "S3DiveBucket"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::dive-production-site-*",
          "arn:aws:s3:::dive-production-site-*/*"
        ]
      },
      # ----- S3: Terraformステートバケット -----
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
      # ----- CloudFront: ディストリビューション/OAC/Function の管理 + invalidation -----
      {
        Sid      = "CloudFront"
        Effect   = "Allow"
        Action   = ["cloudfront:*"]
        Resource = "*"
      },
      # ----- ACM: 証明書の参照（CloudFrontに紐付ける証明書をdataで読む） -----
      {
        Sid    = "AcmRead"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates"
        ]
        Resource = "*"
      },
      # ----- クロスアカウント: 管理アカウントのRoute53ロールをassume（DNS操作） -----
      {
        Sid      = "AssumeRoute53CrossAccount"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.route53_cross_account_role_arn
      }
    ]
  })
}

output "github_actions_role_arn" {
  description = "GitHub Actions が引き受けるIAMロールのARN。GitHub Secrets (AWS_ROLE_ARN) に登録する。"
  value       = aws_iam_role.github_actions_dive.arn
}
