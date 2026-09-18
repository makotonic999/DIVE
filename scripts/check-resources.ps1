# =============================================================================
# scripts/check-resources.ps1
# DIVE 残存リソース棚卸しスクリプト（読み取り専用）
#
# dev / management 両アカウントに残っている dive 関連リソースを確認する。
# apply の中断で state と実態がずれた際の現状把握に使用。
#
# 使い方:
#   .\scripts\check-resources.ps1
# =============================================================================

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " DIVE リソース棚卸し（読み取り専用）" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ----- dev アカウント -----
Write-Host "`n[dev] dive を含む S3 バケット:" -ForegroundColor Yellow
aws s3api list-buckets --profile dev --query "Buckets[?contains(Name, 'dive')].Name" --output table

Write-Host "`n[dev] dive-production-oac という名前の OAC:" -ForegroundColor Yellow
aws cloudfront list-origin-access-controls --profile dev --query "OriginAccessControlList.Items[?Name=='dive-production-oac'].{Id:Id,Name:Name}" --output table

# ----- management アカウント -----
Write-Host "`n[management] dive を含む S3 バケット:" -ForegroundColor Yellow
aws s3api list-buckets --profile management --query "Buckets[?contains(Name, 'dive')].Name" --output table

Write-Host "`n[management] dive-production-oac という名前の OAC:" -ForegroundColor Yellow
aws cloudfront list-origin-access-controls --profile management --query "OriginAccessControlList.Items[?Name=='dive-production-oac'].{Id:Id,Name:Name}" --output table

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " 棚卸し完了" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
