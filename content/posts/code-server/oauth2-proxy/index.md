---
title: "code-serverをoauth2-proxyを使って２段階認証にした話"
date: 2023-10-14T00:00:00+00:00
# weight: 1
aliases: ["/code-server/oauth2-proxy"]
tags: ["code-server", "oauth2-proxy", "2fa"]
categories: ['code-server']
author: "Me"
showToc: true
TocOpen: false
draft: true
cover:
    image: "/images/eyecatch/code-server/oauth2-proxy/index.png"
---
# 概要

code-serverには、標準でパスワードによる認証機能があるが
外部からパスワード入力画面へアクセスできてしまう。
公式ガイドに記載のある+ oauth2-proxyによるGithubの認証を前段に実装し2段階認証で対応する

# このページでわかること

* oauth2-proxyによるcode-serverの外部公開

# 参考サイト

* oauth2-proxy公式リポジトリ
  * https://github.com/oauth2-proxy/oauth2-proxy

# 1. ディレクトリ構成

* 今回修正するファイルは以下になります
```
- /
  - hugo.toml
  - layouts/
    - partials/
      - extend_head.html
```

# 2. 実装手順

### 2-1. hugo設定ファイルへGoogle Analytics 4 ID設定

* 公式ガイドに沿ってhugo.tomlへGoogle Analytics 4のIDを設定します

* hugo.toml or config.toml
```
[services]
  [services.googleAnalytics]
    ID = 'G-xxxxxxxxxx'
```

### 2-2. extend_head.html(Theme: PaperModの場合)を上書きする

* 全てのページへ反映する為、extend_head.htmlを修正する_internal/google_analytics.htmlを読み込む設定を記載

* layout/partials/extend_head.html
```
{{ template "_internal/google_analytics.html" . }}
```

# 3. 反映確認

* Hugoの各ページのソースを確認し、googletagmanager.comのタグが追記されていることを確認

![](source01.gif)