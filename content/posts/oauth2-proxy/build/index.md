---
author: "ijikeman"
showToc: true
TocOpen: true
title: "Oauth2-proxyの起動"
date: 2025-12-07T00:00:00+09:00
# weight: 1
aliases: ["/oauth2-proxy/build"]
tags: ["oauth2-proxy", "2fa"]
categories: ["oauth2-proxy"]
draft: false
cover:
    image: "/images/eyecatch/oauth2-proxy/build/index.webp" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---

# このページでわかること
* oauth2-proxyバイナリのbuildと起動

# Oauth2-Proxy
* ライセンス: MITライセンス
* [oauth2-proxy公式リポジトリ](https://github.com/oauth2-proxy/oauth2-proxy)
* [公式ドキュメント](https://oauth2-proxy.github.io/oauth2-proxy/)

# 執筆時の環境とバージョン
* Ubuntu: 22.04
* oauth2-proxy: v7.13.0

# 参考文献
* [NRIのOpenStandiaが提供するOAuth2 Proxy最新情報](https://openstandia.jp/oss_info/oauth2-proxy/)

* [複数サイト対応(同一ドメインかつ複数サブドメイン)](https://medium.com/devops-dudes/using-oauth2-proxy-with-nginx-subdomains-e453617713a) ... Cognitoだと認証後に返すURLがどちらかのドメインになってしまうので、だめなようだ .htpasswdによるBasic認証ならOKだった
  * 複数サイト対応にはサイトごとにoauth2-proxyを用意する必要があるので、1ドメインで/以下のURL(/zabbix > zabbix.example.com)でリダイレクト&URL書き換えで対応するとかだとOK

# 設定
## 設定方法
* ENVを使う(only on docker)
* oauth2-proxy.cfgを作成し--configで読み込ませる
* 起動時に引数で渡す

## ENVで行う場合の注意点
* 以下のルールで設定
  * -を_に変更
  * 冒頭にOAUTH2_PROXY_をつける
  * 小文字を大文字に変更
  * 複数指定が可能なパラメータはSをつけて複数形に(例: OAUTH_PROXY2_EMAIL_DOMAINS)

# 環境構築
## binary build
* golang環境を用意
```
snap install go --channel 1.25.0
```

* makefileを使ってbuild
```
git clone https://github.com/oauth2-proxy/oauth2-proxy -b v7.13.0 --depth 1
cd oauth2-proxy
make
make build
./oauth2-proxy --version
```

## コンパイル済みbinaryを取得
```
wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v7.13.0/oauth2-proxy-v7.13.0.linux-amd64.tar.gz
tar zxvf oauth2-proxy-v7.13.0.linux-amd64.tar.gz
mv oauth2-proxy-v7.13.0.linux-amd64/oauth2-proxy /usr/local/bin/
```

## Dockerイメージから起動
* [QuayにあるDocker Image](https://quay.io/repository/oauth2-proxy/oauth2-proxy?tab=tags&tag=latest)
```
docker pull quay.io/oauth2-proxy/oauth2-proxy:v7.13.0
compose.yml
---
services:
  oauth2-proxy:
    container_name: oauth2-proxy
    image: quay.io/oauth2-proxy/oauth2-proxy:v7.13.0
    command: --config /oauth2-proxy.cfg
    hostname: oauth2-proxy
    volumes:
      - "./oauth2-proxy.cfg:/oauth2-proxy.cfg"
    restart: unless-stopped
    ports:
      - 4180:4180/tcp
```
