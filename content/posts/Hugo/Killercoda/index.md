---
title: "Hugo用開発環境(Killercoda)"
date: 2024-01-11T23:00:00+09:00
# weight: 1
aliases: ["/hugo/killercoda"]
tags: ["Hugo", "Killercoda"]
categories: [ "Hugo" ]
author: "Me"
TocOpen: false
draft: false
cover:
    image: "/images/eyecatch/Hugo/Killercoda/index.png"
---
# 概要

Hugo開発を自身の端末に作らずに、どこからでも気軽にHugoのテンプレート変更や記事の確認などを行いたい。

Killercodaという学習用プラットフォームサービスでHugo用デバッグ環境を用意する方法を記載します。

# Killercoda過去記事

[KillercodaとGithubリポジトリを同期させる方法](https:/blog.1mg.org/posts/killercoda/setup/)
[Killercodaのオリジナルシナリオの作成方法](https:/blog.1mg.org/posts/killercoda/create_scenario/)

# このページでわかること

* KillerCodaを使ったHugo開発環境の作り方

# 1. Killercoda Hugoシナリオ ディレクトリ構成

```
- /
  - Hugo/
    - index.json
    - background.sh
    - foreground.sh
    - intro.md
    - finish.md
    - step1.md
```

# 2. 実装解説


### 2-1. foreground
* foregroundにスクリプトを定義すると、シナリオ実行時にスクリプトを呼び出すことができます。
* 実装以下
  * /tmp/background-finishedというファイルを作成するまでloop
    * foreground.sh
    ```
    while [ ! -f /tmp/background-finished ]; do sleep 5; echo 'check file'; done
    echo Hello and Welcom to this scenario!
    ```

### 2-2. background
* backgroundにスクリプトを定義すると、foregroundとは別にスクリプトを呼び出すことができます。
* 実装は以下
  * hugoのインストール
  * Githubから自身のhugoリポジトリの取得及びgit submoduleによるthemeの設置のでは
  * /tmp/background-finishedというファイルを作成
    * background.sh
    ```
    snap install hugo
    git clone https://github.com/myhugo-repository.git ./repos
    cd ./repos
    git submodule -i
    touch /tmp/background-finished
    ```
![](intro.gif)

### 2-3. step1
* 外部インターネットからkillercodaの環境内へアクセスするには、グローバル用IP+Portの組み合わせのhostnameが割り当てられアクセスすることができます。
* またこのhostnameは`/etc/killercoda/host`ファイルに以下のフォーマットで記載されています。

```
-を含むランダム英数字-IP-IP-IP-IP-PORT.*.*.killercoda.com
```

* よってstep1では上記hostファイルを加工し、hugoサーバの起動時に--baseURL=オプションとして起動できるようにしています。

```
sed -e 's/^/hugo server --buildDrafts --port 443 --bind 0.0.0.0 --baseURL=/' -e 's/443/PORT/' /etc/killercoda/host > startHugo.sh

sh startHugo.sh
```

![](step1.gif)

* ACCESS HUGOへアクセスするとhugoリポジトリのコンテンツが表示されます。

![](hugo_demo.gif)


上記で紹介したサンプルシナリオは以下になります。
* https://github.com/ijikeman/hugo_scenario_on_killercoda.git
