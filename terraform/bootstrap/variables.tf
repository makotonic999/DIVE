###############################################################################
# terraform/bootstrap/variables.tf
# ブートストラップ用の変数定義
###############################################################################

variable "aws_region" {
  description = "AWSリージョン。"
  type        = string
  default     = "ap-northeast-1"
}

variable "dev_account_profile" {
  description = "devアカウント用のAWS CLIプロファイル（Identity Center経由）。ローカル実行時に使用。空ならアンビエント認証。"
  type        = string
  default     = "dev"
}

variable "route53_cross_account_role_arn" {
  description = "管理アカウントのRoute53操作用クロスアカウントロールARN。CIロールにassume権限を与える対象。"
  type        = string
  default     = "arn:aws:iam::761018859875:role/TerraformRoute53CrossAccountRole"
}
