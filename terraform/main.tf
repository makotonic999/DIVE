###############################################################################
# terraform/main.tf
# DIVE インフラ本体
#
# 構成:
#   - S3バケット（静的サイトホスティング用。パブリックアクセスは完全ブロック）
#   - CloudFront OAC（Origin Access Control）
#   - CloudFrontディストリビューション（S3をオリジンとしてOACで接続）
#   - S3バケットポリシー（CloudFrontからのGetObjectのみ許可）
#
# セキュリティ方針:
#   - S3バケットポリシーでCloudFrontサービスプリンシパルのみGetObjectを許可
#   - S3のパブリックアクセスは全てブロック（バケットはプライベート）
#   - OACはSigV4で署名。OAIより安全でAWSが推奨する最新方式
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  # リモートステート管理を使う場合はこのブロックを有効化して設定する
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "dive/production/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
    })
  }
}

###############################################################################
# ローカル変数
###############################################################################

locals {
  # バケット名: 指定がなければ "${project_name}-${environment}-site" を使用
  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.project_name}-${var.environment}-site"

  # OACの識別名
  oac_name = "${var.project_name}-${var.environment}-oac"
}

###############################################################################
# S3 バケット
###############################################################################

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  # 誤削除防止: productionでは terraform destroy を保護する
  lifecycle {
    prevent_destroy = false # true に変更すると本番保護になる
  }
}

# バージョニング（ロールバック対応。コスト増に注意）
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Suspended" # 必要に応じて "Enabled" に変更
  }
}

# サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスブロック（全てのパブリックアクセスを遮断）
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ACL設定: OACを使うためACLはprivateで十分
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced" # ACLを完全無効化
  }
}

###############################################################################
# CloudFront OAC (Origin Access Control)
# OAIより新しくAWS推奨。S3へのアクセスをSigV4で署名・制御する。
###############################################################################

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.oac_name
  description                       = "OAC for DIVE static site (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################################
# CloudFront ディストリビューション
###############################################################################

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.cloudfront_default_root_object
  price_class         = var.cloudfront_price_class
  comment             = "DIVE static site distribution (${var.environment})"

  # オリジン: S3バケット（OAC経由）
  origin {
    origin_id                = "s3-${local.bucket_name}"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # デフォルトキャッシュビヘイビア
  default_cache_behavior {
    target_origin_id       = "s3-${local.bucket_name}"
    viewer_protocol_policy = "redirect-to-https" # HTTP → HTTPSへリダイレクト

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true # gzip/Brotli圧縮を有効化

    # マネージドキャッシュポリシー: CachingOptimized
    # TTL: デフォルト86400秒（24時間）
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # マネージドオリジンリクエストポリシー: CORS-S3Origin
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  # カスタムエラーレスポンス（404.htmlのフォールバックなど）
  dynamic "custom_error_response" {
    for_each = var.cloudfront_custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = 10
    }
  }

  # 地理的制限なし（全世界に配信）
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS証明書: CloudFrontデフォルト証明書を使用
  # カスタムドメインを使う場合は aws_acm_certificate を追加して viewer_certificate を変更する
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # CloudFrontアクセスログ（有効化する場合）
  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logging ? [1] : []
    content {
      bucket          = aws_s3_bucket.logs[0].bucket_domain_name
      include_cookies = false
      prefix          = "cloudfront/"
    }
  }

  depends_on = [
    aws_s3_bucket_public_access_block.site,
  ]
}

###############################################################################
# S3 バケットポリシー
# CloudFrontサービスプリンシパルからの GetObject のみ許可
###############################################################################

data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.site.arn}/*"]

    # 特定のCloudFrontディストリビューションのみ許可（セキュリティ強化）
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket_policy.json

  # パブリックアクセスブロックを先に設定してからポリシーを適用
  depends_on = [aws_s3_bucket_public_access_block.site]
}

###############################################################################
# CloudFrontアクセスログ用S3バケット（オプション）
###############################################################################

resource "aws_s3_bucket" "logs" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = "${local.bucket_name}-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.enable_cloudfront_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
