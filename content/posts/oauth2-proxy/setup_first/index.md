---
author: "ijikeman"
showToc: true
TocOpen: true
title: "oauth2-proxyの導入(Setup編)"
date: 2025-12-22T00:00:00+09:00
# weight: 1
aliases: ["/oauth2-proxy/setup"]
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

# このページでわかること(※2025/12/22 更新しました)
* oauth2-proxyの起動と画面の確認まで(基本設定)

# 執筆時の環境とバージョン
* Ubuntu: 22.04
* oauth2-proxy: 7.13.0

# 参考サイト

* oauth2-proxy公式リポジトリ
  * https://github.com/oauth2-proxy/oauth2-proxy

* oauth2-proxyの公式ドキュメント
  * https://oauth2-proxy.github.io/oauth2-proxy/docs/

# Killercoda URL
この記事の内容はKillercodaにて学習コンテンツとして公開しております。
併せて、動作確認で利用してください。

URL: https://killercoda.com/ijikeman/scenario/oauth2-proxy

# 1. 基本設定による起動確認
## 1-1. ファイル/ディレクトリ構成

* 今回ファイル/ディレクトリ構成は以下になります
```
- /
  - usr/bin/
    - oauth2-proxy ... oauth2-proxyバイナリ
  - etc/oauth2-proxy/
    - oauth2-proxy.cfg ... oauth2-proxy設定ファイル
  - usr/lib/systemd/system/
    - oauth2-proxy.servce ... systemd管理サービスファイル
```

## 1-2. インストール
* oauth2-proxyバイナリのダウンロード
```
VERSION=7.13.0
OS=darwin
ARCH=amd64
FILENAME="oauth2-proxy-v${VERSION}.${OS}-${ARCH}"

wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v${VERSION}/${FILENAME}.tar.gz -O /tmp/oauth2-proxy.tar.gz
tar zxvf /tmp/oauth2-proxy.tar.gz -C /tmp
mv /tmp/${FILENAME}/oauth2-proxy /usr/bin/
chmod +x /usr/bin/oauth2-proxy
```

* 設定ファイルサンプルのダウンロード
```
mkdir -p /etc/oauth2-proxy/
wget https://raw.githubusercontent.com/oauth2-proxy/oauth2-proxy/refs/tags/v${VERSION}/contrib/oauth2-proxy.cfg.example -O /etc/oauth2-proxy/oauth2-proxy.cfg
```

* systemd管理Serviceファイルのダウンロード
```
wget https://raw.githubusercontent.com/oauth2-proxy/oauth2-proxy/refs/tags/v${VERSION}/contrib/oauth2-proxy.service.example -O /usr/lib/systemd/system/oauth2-proxy.service
```

## 1-3. 設定ファイル修正(仮)
* oauth2-proxy.cfgの以下の部分を修正します(最低限の設定と起動確認のみ)
```
vi /etc/oauth2-proxy/oauth2-proxy.cfg
---
http_address = "0.0.0.0:4180" # グローバルIPでListenできるように変更

upstreams = [
    "http://127.0.0.1:8080 # 一旦デフォルトのまま
]

email_domains = [
    "yourcompany.com" # 一旦デフォルトのまま
]

client_id = "123456.apps.googleusercontent.com" # 一旦デフォルトのまま
client_secret = "test" # 空欄だと起動時にエラーになる

# ※必須パラメータ 仮なので16文字であればOK
# 16, 24, or 32 bytes to create an AES cipher
cookie_secret = "AAAAAAAAAAAAAAAA"
```

## 1-4. Oauth2-Proxyユーザ/グループの作成
* systemdサービスファイルに記載されている専用ユーザ/グループの作成
```
groupadd oauth2-proxy
useradd -g oauth2-proxy -s /sbin/nologin oauth2-proxy
```

## 1-4. oauth2-proxyの起動
* テスト起動しConfigエラーがないか確認
```
su - oauth2-proxy -s /bin/bash -c '/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy.cfg'
---
/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy.cfg
2025/12/22 00:19:12 oauthproxy.go:130: mapping path "/" => upstream "http://127.0.0.1:8080"
2025/12/22 00:19:12 oauthproxy.go:157: OAuthProxy configured for Google Client ID: 123456.apps.googleusercontent.com
2025/12/22 00:19:12 oauthproxy.go:167: Cookie settings: name:_oauth2_proxy secure(https):true httponly:true expiry:168h0m0s domain:<default> refresh:disabled
2025/12/22 00:19:12 http.go:49: HTTP: listening on 0.0.0.0:4180
```

* systemd経由で起動
```
systemctl start oauth2-proxy.service
```

## 1-5. oauth2-proxyの画面確認
* http://$IP:4180にアクセスし、oauth2-proxyの認証画面が表示されることを確認(以下はkillercodaを使って確認しています)

![](oauth2_proxy_setup_confirm01.gif)

![](oauth2_proxy_setup_confirm02.gif)

こちらの[記事](/posts/oauth2-proxy/setup_google_auth/)にてGoogle認証に必要な設定を行っていきます
