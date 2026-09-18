###############################################################################
# terraform/outputs.tf
# DIVE インフラ出力値
# terraform apply 後に確認できる重要な値をまとめて出力する。
# GitHub ActionsのCI/CDパイプラインやデプロイスクリプトから参照することを想定。
###############################################################################

###############################################################################
# S3 バケット出力
###############################################################################

output "s3_bucket_name" {
  description = "Astroビルド成果物をアップロードするS3バケット名。\nCI/CD例: aws s3 sync ./dist s3://$S3_BUCKET_NAME --delete"
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "S3バケットのARN。IAMポリシーや他のTerraformモジュールとの連携に使用。"
  value       = aws_s3_bucket.site.arn
}

output "s3_bucket_region" {
  description = "S3バケットが存在するリージョン。"
  value       = aws_s3_bucket.site.region
}

output "s3_bucket_regional_domain_name" {
  description = "S3バケットのリージョナルドメイン名。CloudFrontオリジン設定の確認用。"
  value       = aws_s3_bucket.site.bucket_regional_domain_name
}

###############################################################################
# CloudFront 出力
###############################################################################

output "cloudfront_distribution_id" {
  description = "CloudFrontディストリビューションID。\nデプロイ後のキャッシュ無効化に使用: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFrontディストリビューションのARN。"
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "CloudFrontのデフォルトドメイン名（例: d1234abcdef.cloudfront.net）。\nカスタムドメインを設定するまでは、このURLでサイトにアクセスできる。"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFrontのホストゾーンID。Route53でカスタムドメインのAliasレコードを設定する際に使用。"
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}

output "cloudfront_etag" {
  description = "CloudFrontディストリビューションの現在のETag。設定変更時に必要になる場合がある。"
  value       = aws_cloudfront_distribution.site.etag
}

###############################################################################
# OAC 出力
###############################################################################

output "cloudfront_oac_id" {
  description = "CloudFront OAC（Origin Access Control）のID。"
  value       = aws_cloudfront_origin_access_control.site.id
}

###############################################################################
# サイトURL（使いやすい形でまとめて出力）
###############################################################################

output "site_url" {
  description = "DIVEサイトにアクセスするためのURL（カスタムドメイン）。"
  value       = "https://${var.domain_name}"
}

output "cloudfront_default_url" {
  description = "CloudFrontデフォルトドメインのURL。DNS伝播前の疎通確認や、カスタムドメイン設定のトラブルシュートに使用。"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

###############################################################################
# CI/CD用コマンドサンプル出力
###############################################################################

output "deploy_commands" {
  description = "デプロイに使用するAWS CLIコマンドのサンプル。GitHub Actionsのワークフローに組み込む際の参考にしてください。"
  value       = <<-EOT
    # 1. Astroビルド
    npm run build

    # 2. S3へアップロード（dist/ディレクトリをs3://バケット名に同期）
    aws s3 sync ./dist s3://${aws_s3_bucket.site.id} --delete --cache-control "public,max-age=31536000,immutable"

    # 3. index.htmlはキャッシュなし（常に最新を返す）
    aws s3 cp ./dist/index.html s3://${aws_s3_bucket.site.id}/index.html --cache-control "no-cache,no-store,must-revalidate"

    # 4. CloudFrontキャッシュ無効化
    aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths "/*"
  EOT
}
