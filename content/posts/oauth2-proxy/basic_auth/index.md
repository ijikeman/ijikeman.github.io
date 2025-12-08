---
author: "ijikeman"
showToc: true
TocOpen: true
title: "OAuth2-Proxy動作テスト(Basic認証編)"
date: 2025-12-08T00:00:00+09:00
# weight: 1
aliases: ["/oauth2-proxy/basic_auth"]
tags: ["oauth2-proxy", "2fa"]
categories: ["oauth2-proxy"]
draft: false
cover:
    image: "/images/eyecatch/oauth2-proxy/basic_auth/index.webp" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---

# このページでわかること
* Nginxのトップページに対してOAuth2-ProxyのBasic認証を経由してアクセスする

# Oauth2-Proxyの認証機構としてBasic認証でテスト実行してみる
* .htpasswdを発行する
```
docker run -it httpd:2.4.39-alpine htpasswd -nb -B user1 hogehoge  > /etc/.htpasswd 
```

# OAuth2-Proxyの設定ファイル
```
oauth2-proxy.cfg
---
# oauth2-proxyをhttp://*:4180でLISTENする
http_address = "0.0.0.0:4180"

# 認証後のcallbackの受け先を指定
redirect_url = "http://test.example.com/oauth2/callback"

# Basic Auth
htpasswd_file = "/etc/.htpasswd" # Basic認証用パスワードのパスを指定

# ※起動時に必須パラメータ。適当な文字列を設定
client_id = "123456.apps.googleusercontent.com"

# 認証後に、認証cookieの有効期間を指定
cookie_expire = "0m15s"

# ※必須パラメータ 仮なので16文字であればOK
# 16, 24, or 32 bytes to create an AES cipher
cookie_secret = "AAAAAAAAAAAAAAAA"

# http通信の場合はこの値を無効化する必要がある(default: true)
cookie_secure = "false"

# 認証後にOauth2-proxy経由での接続先
upstreams = [
  "http://127.0.0.1:80"
]
```

* nginxを80番で起動してOAuth2-Proxyの接続後の仮サイトとする
```
docker run --rm --name nginx -p 80:80 -itd nginx:latest
```

* OAuth2-Proxyを起動する
```
./oauth2-proxy --config ./oauth2-proxy.cfg
---
[2025/12/08 09:39:05] [oauthproxy.go:128] using htpasswd file: /etc/.htpasswd
[2025/12/08 09:39:05] [watcher.go:40] watching '/etc/.htpasswd' for updates
[2025/12/08 09:39:05] [proxy.go:89] mapping path "/" => upstream "http://127.0.0.1:80"
[2025/12/08 09:39:05] [oauthproxy.go:176] OAuthProxy configured for Google Client ID: 123456.apps.googleusercontent.com
[2025/12/08 09:39:05] [oauthproxy.go:182] Cookie settings: name:_oauth2_proxy secure(https):false httponly:true expiry:15s domains:.test.example.com path:/ samesite: refresh:disabled
```

* https://test.example.com:4180にブラウザからアクセスし、OAuth2-Proxyのページが表示されることを確認

![](oauth2-proxy01.gif)

* Basic認証で発行したユーザパスワードを入力すると、nginxの画面が表示される

![](oauth2-proxy02.gif)

* 認証時のOAuth2-ProxyのログにBasic認証が表示されていることが確認できる
```
192.168.0.1:50640 - - user1 [2025/12/01 00:00:00] [AuthSuccess] Authenticated via HtpasswdFile
192.168.0.1:50640 - - - [2025/12/01 00:00:00] test.example.com:4180 POST - "/oauth2/sign_in" HTTP/1.1 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" 302 0 0.004
192.168.0.1:50640 - - user1 [2025/12/01 00:00:00] test.example.com:4180 GET / "/" HTTP/1.1 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" 200 615 0.001
```
