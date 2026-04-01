# CLAUDE.md — ijikeman's Hugo Blog

## プロジェクト概要

- **URL**: https://blog.1mg.org/
- **GitHub Pages**: ijikeman.github.io
- **フレームワーク**: Hugo + PaperMod テーマ
- **対象読者**: エンジニア向け技術記事

## ディレクトリ構成

```
ijikeman.github.io/
├── content/
│   └── posts/          # 記事（カテゴリ別ディレクトリ）
│       ├── GIT/
│       ├── Hugo/
│       ├── KillerCoda/
│       ├── Linux/
│       ├── oauth2-proxy/
│       ├── code-server/
│       └── vhs/
├── static/
│   └── images/
│       ├── eyecatch/   # カバー画像（カテゴリ/記事名/index.png）
│       └── tcardgen/   # OGP画像
├── archetypes/
│   └── default.md      # 記事テンプレート
├── hugo.toml           # Hugo設定
└── themes/PaperMod/    # テーマ
```

## 記事のフロントマター形式

```yaml
---
author: "ijikeman"
showToc: true
TocOpen: true
title: "記事タイトル"
date: 2025-01-01T00:00:00+09:00
aliases: ["/カテゴリ/記事名"]
tags: ["タグ1", "タグ2"]
categories: ["カテゴリ名"]
draft: false
cover:
    image: "/images/eyecatch/カテゴリ/記事名/index.png"
---
```

## 記事の作成手順

1. `content/posts/<カテゴリ>/<記事名>/` ディレクトリを作成
2. `index.md` を作成しフロントマターを記述
3. 記事本文を Markdown で記述
4. 画像は同ディレクトリに配置（`![](image.png)` で参照）
5. カバー画像は `static/images/eyecatch/<カテゴリ>/<記事名>/index.png` に配置

## 記事の構成パターン（推奨）

```markdown
# このページでわかること
* 本記事で学べること

# 執筆時の環境とバージョン
* OS: Ubuntu 22.04
* ツール名: x.x.x

# 参考サイト
* [公式ドキュメント](URL)

# 1. セクション見出し
## 1-1. サブセクション
...
```

## Hugo ローカル確認

```bash
cd ijikeman.github.io
docker-compose up   # または hugo server
```

## 既存カテゴリ一覧

| カテゴリ | 内容 |
|---------|------|
| GIT | Git操作・submodule・sparse-checkout等 |
| Hugo | Hugoブログ構築・設定 |
| KillerCoda | KillerCoda学習コンテンツ作成 |
| Linux | Linux操作・設定 |
| oauth2-proxy | oauth2-proxy導入・設定 |
| code-server | code-server関連 |
| vhs | vhs（ターミナル録画ツール）|
| TryHackMe | TryHackMe CTF Walkthrough記事 |

## 注意事項

- `draft: false` にしないと公開されない
- タイムゾーンは `+09:00`（JST）を使用
- カバー画像のパスは `/images/eyecatch/...` (static/ 以下の相対パス)
- 記事URLは `aliases` で短縮パスを設定できる

## TryHackMe Walkthrough 記事の作成手順

1. `content/posts/TryHackMe/<ルーム名>/` ディレクトリを作成
2. `index.md` を `archetypes/tryhackme.md` を参考に作成
3. カバー画像は `static/images/eyecatch/TryHackMe/<ルーム名>/index.png` に配置
4. タグは `["TryHackMe", "CTF", "walkthrough"]` を基本とし、必要に応じて追加
5. 難易度・カテゴリ・ルームURLをフロントマターの表に記載

### Walkthrough 記事の構成パターン

```markdown
# このページでわかること
# ルーム情報（表）
# 執筆時の環境
# 参考サイト
# 1. 偵察 (Reconnaissance)
# 2. 列挙 (Enumeration)
# 3. 攻撃 (Exploitation)
# 4. 権限昇格 (Privilege Escalation)
# 5. フラグ取得
```
