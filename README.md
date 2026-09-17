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

## 🗺️ シラバス（全7Part / 21章）

- **Part 1: 物理・電子・論理回路**（トランジスタ / クロックとレジスタ / 自作CPU）
- **Part 2: アセンブリ・実行モデル**（機械語・C / スタックとヒープ / ポインタの真実）
- **Part 3: カーネルと仮想化**（UNIXとシステムコール / 仮想メモリ / namespaces・cgroups）
- **Part 4: 高並列・DB・ランタイム**（C10Kとepoll / B-TreeとWAL / GCの裏側）
- **Part 5: ネットワーク・SRE**（TCP/IP / TLS 1.3 / CAP定理とカオスエンジニアリング）
- **Part 6: 並列ハード・数学基盤**（GPU超並列 / 行列演算とベクトル空間 / 偏微分・勾配降下法）
- **Part 7: 確率とAI・LLM**（自作ニューラルネット / 言語の分散表現 / TransformerとSelf-Attention）

---

## 🛠️ 構成スタック
- **Frontend**: Astro + MDX (Shiki / KaTeX / Pagefind)
- **Infrastructure**: AWS (S3 + CloudFront) managed by Terraform
- **CI/CD**: GitHub Actions
