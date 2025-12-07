---
author: "ijikeman"
showToc: true
TocOpen: true
title: "oauth2-proxyをbuildする(on Ubuntu22)"
date: 2025-12-07T00:00:00+09:00
# weight: 1
aliases: ["/oauth2-proxy/build"]
tags: ["oauth2-proxy", "2fa"]
categories: ["oauth2-proxy"]
draft: false
cover:
    image: "/images/eyecatch/oauth2-proxy/setup_first/index.png" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---

# このページでわかること

* oauth2-proxyバイナリのbuildと起動

# 執筆時の環境とバージョン
* Ubuntu: 22.04
* oauth2-proxy: v7.13.0

# 参考サイト

* oauth2-proxy公式リポジトリ
  * https://github.com/oauth2-proxy/oauth2-proxy

* oauth2-proxyの公式ドキュメント
  * https://oauth2-proxy.github.io/oauth2-proxy/docs/

# 1. ビルド環境の準備
* snapでgolangをインストール 
```
snap install golang --channel 1.25.0 --classic
```

# 2. ビルド 
* oauth2-proxyリポジトリの取得
```
git clone https://github.com/oauth2-proxy/oauth2-proxy -b v7.13.0
cd oauth2-proxy
```

* バイナリのビルド
```
make
make build
```
