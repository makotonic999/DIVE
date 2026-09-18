# =============================================================================
# scripts/cleanup-oac.ps1
# 残存 OAC 削除スクリプト（dev アカウント）
#
# apply 中断で残った dive-production-oac (ID: EPC5OI5270MCJ) を削除する。
# OAC削除には ETag（If-Match）が必要なため、取得してから削除する。
#
# 使い方:
#   .\scripts\cleanup-oac.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$OacId = "EPC5OI5270MCJ"
$Profile = "dev"

Write-Host "OAC ($OacId) の ETag を取得中..." -ForegroundColor Yellow
$etag = aws cloudfront get-origin-access-control --id $OacId --profile $Profile --query "ETag" --output text

if (-not $etag) {
    Write-Host "ETag を取得できませんでした。OAC が既に存在しない可能性があります。" -ForegroundColor Red
    exit 1
}

Write-Host "ETag: $etag" -ForegroundColor Green
Write-Host "OAC ($OacId) を削除中..." -ForegroundColor Yellow

aws cloudfront delete-origin-access-control --id $OacId --if-match $etag --profile $Profile

Write-Host "削除完了。確認します..." -ForegroundColor Green
aws cloudfront list-origin-access-controls --profile $Profile --query "OriginAccessControlList.Items[?Name=='dive-production-oac'].{Id:Id,Name:Name}" --output table

Write-Host "上の表が空なら削除成功です。" -ForegroundColor Cyan
