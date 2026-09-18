# DIVE (Deep Interactive Virtual Encyclopedia)
> **0と1の物理からAIまでを繋ぐ、フルスタック技術全史**

「非エンジニアが読めば、すべてのブラックボックスを消し去り最強のエンジニアになれる技術エンタメ小説」

---

## 🌊 コンセプト
単なる用語辞典やコマンド集ではなく、技術が生まれた**「歴史の必然」**と**「物理的限界」**を軸に、すべての「おまじない」を解体するWebメディアプロジェクトです。

- **歴史の必然**: 「当時のエンジニアがどんな壁にぶつかり、どう克服したか」というドラマで語る
- **物理構造の解体**: 電気信号、レジスタ、パケット、カーネルからTransformerまで全解剖
- **厨房のアナロジー**: 複雑な概念を直感的に掴む日常的な比喩モデルの採用

---

## 🛠️ 技術構成

| レイヤ | 使用技術 |
|---|---|
| **Frontend** | Astro 5 + MDX（Shiki: シンタックスハイライト / KaTeX: 数式 / Tailwind CSS） |
| **Infrastructure** | AWS S3 + CloudFront + OAC、Route 53、ACM（Terraform管理） |
| **CI/CD** | GitHub Actions（OIDC認証・シークレットレス） |
| **公開URL** | https://dive.okada-chikuro-kougyousyo.com |

---

## 🏗️ アーキテクチャと設計判断

このプロジェクトは、コンテンツだけでなく **インフラと運用自動化そのものを学習・実践の対象** としています。以下は主要な設計判断です。

### 静的配信基盤（S3 + CloudFront + OAC）
- S3バケットは**パブリックアクセスを完全遮断**し、CloudFront経由（OAC / Origin Access Control、SigV4署名）でのみ配信。オリジンへの直接アクセスを排除。
- Astroが出力するディレクトリ形式（`/about/` → `/about/index.html`）を **CloudFront Function** で解決し、静的MPAを正しくルーティング。

### マルチアカウント / クロスアカウント構成
- **リソース用アカウント（dev）** と **DNS管理アカウント** を分離。
- Terraformの複数プロバイダ + `assume_role` により、CloudFront等はdevに、Route 53 レコードは管理アカウントに、**一つのコードベースから横断的にプロビジョニング**。
- 既存のACMワイルドカード証明書を再利用し、独自サブドメインをHTTPS化。

### シークレットレスなCI/CD（GitHub Actions + OIDC）
- 長期AWSアクセスキーを持たず、**OIDCでIAMロールを引き受け**る方式。
- `git push` を起点に「**Terraform apply → ビルド → S3同期 → CloudFrontキャッシュ無効化**」を自動実行。
- **CI用IAMロールは最小権限**とし、**IAM自体の管理はブートストラップ用の別ステートに分離**。CIが自身の権限を書き換えられる状態（権限昇格リスク）を排除。

### Terraform運用
- ステートは **S3バックエンド**（ネイティブロックによる排他制御）で管理。
- リソース名の衝突を防ぐ **ランダムサフィックス**、providerのプロファイル明示によるアカウント誤操作防止など、再現性と安全性を重視。

---

## 📁 リポジトリ構成

```
.
├── src/                 # Astro ソース（pages / layouts / content:章のMDX）
├── terraform/           # アプリインフラ（S3 / CloudFront / Route53 / DNS）
│   └── bootstrap/       # CI用IAMロール（別ステート・手元管理）
├── scripts/             # デプロイ・運用スクリプト
└── .github/workflows/   # CI/CD（deploy.yml）
```

---

## 🚀 デプロイ

CI/CDにより `main` への push で自動デプロイされる。手動デプロイも可能：

```bash
npm run build              # Astro をビルド
./scripts/deploy.ps1       # build → S3同期 → CloudFront無効化（出力から宛先を動的取得）
```

---

## 🗺️ シラバス（全7Part / 21章）

- **Part 1: 物理・電子・論理回路**（トランジスタ / クロックとレジスタ / 自作CPU）
- **Part 2: アセンブリ・実行モデル**（機械語・C / スタックとヒープ / ポインタの真実）
- **Part 3: カーネルと仮想化**（UNIXとシステムコール / 仮想メモリ / namespaces・cgroups）
- **Part 4: 高並列・DB・ランタイム**（C10Kとepoll / B-TreeとWAL / GCの裏側）
- **Part 5: ネットワーク・SRE**（TCP/IP / TLS 1.3 / CAP定理とカオスエンジニアリング）
- **Part 6: 並列ハード・数学基盤**（GPU超並列 / 行列演算とベクトル空間 / 偏微分・勾配降下法）
- **Part 7: 確率とAI・LLM**（自作ニューラルネット / 言語の分散表現 / TransformerとSelf-Attention）
