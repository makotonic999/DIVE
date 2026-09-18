###############################################################################
# terraform/cloudfront-function.tf
# CloudFront Function — サブディレクトリのindex解決
#
# 目的:
#   Astroの静的サイト(MPA)は各ページを "about/index.html" のように出力する。
#   OAC経由のS3オリジンは、S3の「静的ウェブサイトホスティング」のような
#   ディレクトリindex自動解決を行わないため、"/about/" のリクエストが
#   そのままでは 403/404 になる。
#
#   このCloudFront Functionをビューワーリクエストに噛ませ、
#   URIを次のように書き換えることで、正しいオブジェクトを取得させる:
#     /about        -> /about/index.html
#     /about/       -> /about/index.html
#     /chapters/ch01 -> /chapters/ch01/index.html
#     /foo.css      -> そのまま（拡張子があるものは触らない）
###############################################################################

resource "aws_cloudfront_function" "rewrite_index" {
  name    = "${var.project_name}-${var.environment}-rewrite-index-${local.name_suffix}"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite directory-style URIs to index.html for the static site"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // 末尾がスラッシュ → index.html を付与
      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
      }
      // 拡張子（ドット）を含まないパス → /index.html を付与
      // 例: /about, /chapters/ch01
      else if (!uri.includes('.')) {
        request.uri = uri + '/index.html';
      }

      return request;
    }
  EOT
}
