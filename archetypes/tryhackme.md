---
author: "ijikeman"
showToc: true
TocOpen: true
title: "TryHackMe: {{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
aliases: ["/TryHackMe/{{ .File.ContentBaseName }}"]
tags: ["TryHackMe", "CTF", "walkthrough"]
categories: ["TryHackMe"]
draft: false
cover:
    image: "/images/eyecatch/TryHackMe/{{ .File.ContentBaseName }}/index.png"
---

# このページでわかること

* TryHackMe ルーム「{{ replace .File.ContentBaseName "-" " " | title }}」のWalkthrough

# ルーム情報

| 項目 | 内容 |
|------|------|
| ルーム名 | {{ replace .File.ContentBaseName "-" " " | title }} |
| 難易度 | Easy / Medium / Hard |
| カテゴリ | |
| URL | https://tryhackme.com/room/{{ .File.ContentBaseName }} |

# 執筆時の環境

* OS: Kali Linux
* VPN: TryHackMe OpenVPN

# 参考サイト

* [TryHackMe 公式](https://tryhackme.com/)

---

# 1. 偵察 (Reconnaissance)

## 1-1. nmap スキャン

```bash
nmap -sV -sC -oN nmap.txt <TARGET_IP>
```

```
# nmap結果をここに貼る
```

# 2. 列挙 (Enumeration)

## 2-1.

# 3. 攻撃 (Exploitation)

## 3-1.

# 4. 権限昇格 (Privilege Escalation)

## 4-1.

# 5. フラグ取得

| フラグ | 値 |
|--------|----|
| user.txt | `THM{...}` |
| root.txt | `THM{...}` |
