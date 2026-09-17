###############################################################################
# terraform/variables.tf
# DIVE インフラ変数定義
# S3 + CloudFront + OAC 構成のパラメータをまとめて管理する。
###############################################################################

variable "aws_region" {
  description = "AWSリージョン。S3バケットはCloudFrontとの相性上 us-east-1 以外も可だが、OACは全リージョン対応。"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名。リソース名のプレフィックスとして使用される。"
  type        = string
  default     = "dive"
}

variable "environment" {
  description = "デプロイ環境。リソース名・タグに使用される。"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment は 'production', 'staging', 'development' のいずれかを指定してください。"
  }
}

variable "s3_bucket_name" {
  description = "Astroのビルド成果物をホスティングするS3バケット名。グローバルで一意である必要がある。空文字の場合はプロジェクト名+環境名から自動生成される。"
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "CloudFrontの料金クラス。PriceClass_100は北米・欧州のみ。日本を含める場合は PriceClass_200 または PriceClass_All を指定。"
  type        = string
  default     = "PriceClass_200"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class は 'PriceClass_100', 'PriceClass_200', 'PriceClass_All' のいずれかを指定してください。"
  }
}

variable "cloudfront_default_root_object" {
  description = "CloudFrontのデフォルトルートオブジェクト（例: index.html）。"
  type        = string
  default     = "index.html"
}

variable "cloudfront_custom_error_responses" {
  description = "CloudFrontのカスタムエラーレスポンス設定。SPAルーティング対応のため 403/404 → index.html にリダイレクト。"
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/404.html"
    },
  ]
}

variable "enable_cloudfront_logging" {
  description = "CloudFrontアクセスログを有効化するか。有効化すると別途ログ用S3バケットが作成される。"
  type        = bool
  default     = false
}

variable "tags" {
  description = "全リソースに付与する共通タグ。"
  type        = map(string)
  default = {
    Project     = "DIVE"
    ManagedBy   = "Terraform"
    Description = "Deep Interactive Virtual Encyclopedia"
  }
}
