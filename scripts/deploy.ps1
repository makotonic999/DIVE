# =============================================================================
# scripts/deploy.ps1
# DIVE デプロイスクリプト
#
# 処理:
#   1. Astroをビルド (npm run build)
#   2. dist/ を S3 に同期（静的アセットは長期キャッシュ、HTMLは都度再検証）
#   3. CloudFront キャッシュを無効化
#
# バケット名・ディストリビューションIDは terraform output から動的に取得するため、
# バケット名にランダムサフィックスが付いていても常に正しい宛先へデプロイされる。
#
# 前提:
#   - dev プロファイルでログイン済み (aws sso login --profile dev)
#   - terraform apply 済み（outputが取得できる状態）
#
# 使い方:
#   .\scripts\deploy.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$RepoRoot     = Split-Path -Parent $PSScriptRoot
$TerraformDir = Join-Path $RepoRoot "terraform"
$DistDir      = Join-Path $RepoRoot "dist"
$AwsProfile   = "dev"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " DIVE デプロイ開始" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ----- 1. Terraform output から宛先を取得 -----
Write-Host "`n[1/4] Terraform output から宛先を取得中..." -ForegroundColor Yellow
Push-Location $TerraformDir
$BucketName     = (terraform output -raw s3_bucket_name).Trim()
$DistributionId = (terraform output -raw cloudfront_distribution_id).Trim()
Pop-Location

if (-not $BucketName -or -not $DistributionId) {
    Write-Host "バケット名またはディストリビューションIDを取得できませんでした。terraform apply 済みか確認してください。" -ForegroundColor Red
    exit 1
}
Write-Host "  Bucket:       $BucketName" -ForegroundColor Green
Write-Host "  Distribution: $DistributionId" -ForegroundColor Green

# ----- 2. Astro ビルド -----
Write-Host "`n[2/4] Astro をビルド中 (npm run build)..." -ForegroundColor Yellow

# npm が PATH に無い場合、一般的なインストール先を PATH に追加する
# （素のPowerShellにはNode.jsのPATHが通っていないことがあるため）
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    $NodePath = "C:\Program Files\nodejs"
    if (Test-Path (Join-Path $NodePath "npm.cmd")) {
        Write-Host "  npm が PATH にないため、$NodePath を一時的に追加します。" -ForegroundColor DarkGray
        $env:Path = "$NodePath;$env:Path"
    } else {
        Write-Host "npm が見つかりません。Node.js がインストールされているか確認してください。" -ForegroundColor Red
        exit 1
    }
}

Push-Location $RepoRoot
npm run build
Pop-Location

if (-not (Test-Path $DistDir)) {
    Write-Host "dist/ が生成されませんでした。ビルドに失敗した可能性があります。" -ForegroundColor Red
    exit 1
}

# ----- 3. S3 へ同期 -----
Write-Host "`n[3/4] S3 へ同期中..." -ForegroundColor Yellow

# 静的アセット: 長期キャッシュ（immutable）。index.html は後で上書きする。
aws s3 sync $DistDir "s3://$BucketName" --delete `
    --cache-control "public,max-age=31536000,immutable" `
    --profile $AwsProfile

# HTML ファイルは都度再検証（no-cache）で上書き。
# index.html
aws s3 cp (Join-Path $DistDir "index.html") "s3://$BucketName/index.html" `
    --cache-control "no-cache,no-store,must-revalidate" `
    --content-type "text/html" `
    --profile $AwsProfile

# ----- 4. CloudFront キャッシュ無効化 -----
Write-Host "`n[4/4] CloudFront キャッシュを無効化中..." -ForegroundColor Yellow
aws cloudfront create-invalidation `
    --distribution-id $DistributionId `
    --paths "/*" `
    --profile $AwsProfile `
    --query "Invalidation.{Id:Id,Status:Status}" `
    --output table

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " デプロイ完了" -ForegroundColor Cyan
Write-Host " https://dive.okada-chikuro-kougyousyo.com" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " ※ CloudFrontの無効化反映まで数分かかる場合があります。" -ForegroundColor DarkGray
