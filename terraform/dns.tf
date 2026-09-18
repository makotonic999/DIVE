###############################################################################
# terraform/dns.tf
# DIVE DNS設定（クロスアカウント）
#
# 構成:
#   - Route53 Aliasレコード（A / AAAA）を管理アカウント側のホストゾーンに作成
#   - alias先はdevアカウントのCloudFrontディストリビューション
#
# クロスアカウント方針:
#   - CloudFront等のリソースはdevアカウント（デフォルトprovider）で作成
#   - DNSレコードは管理アカウント（provider aws.management）で作成
#   - 親ゾーン okada-chikuro-kougyousyo.com は管理アカウントのRoute53に存在
#
# 注意:
#   - CloudFrontのAliasターゲットzone_idは全世界共通の固定値 Z2FDTNDATAQYW2
#   - evaluate_target_health は CloudFront では false 推奨
###############################################################################

# CloudFront の Route53 Alias 用固定ホストゾーンID（AWSグローバル共通）
locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}

# Aレコード（IPv4）: dive.okada-chikuro-kougyousyo.com → CloudFront
resource "aws_route53_record" "site_a" {
  provider = aws.management

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAAレコード（IPv6）: dive.okada-chikuro-kougyousyo.com → CloudFront
# CloudFrontは is_ipv6_enabled = true なのでIPv6も配信する
resource "aws_route53_record" "site_aaaa" {
  provider = aws.management

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
