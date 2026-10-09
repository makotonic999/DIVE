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

variable "dns_account_id" {
  description = "Route53 ホストゾーンを管理する AWS アカウントID（12桁）。実値は terraform.tfvars で渡す。"
  type        = string
}
