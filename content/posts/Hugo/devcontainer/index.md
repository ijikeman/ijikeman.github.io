---
author: "ijikeman"
showToc: true
TocOpen: true
title: "Hugo開発環境(devcontainer)"
date: 2023-10-12T22:00:00+00:00
# weight: 1
aliases: ["/hugo/devcontainer"]
tags: ["vscode", "devcontainer", "Hugo"]
categories: [ "Hugo" ]
draft: false
cover:
    image: "/images/eyecatch/Hugo/devcontainer/index.png" # image path/url
#     image: "test.jpg" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---

# ここでわかること
* VS Codeのdevcontainer機能でhugo環境を構築

# devcontainerで環境を構築する意味
■hugo環境をローカル用意するメリット, デメリット
* メリット
  * デバッグ実行速度

* デメリット
  * 開発端末の環境が汚れる(色々なコンポーネントや設定が行われ、端末変更などで再現が大変)
  * 複数のバージョンを切り替えれない

など開発環境の可搬性に問題があります。

どこでも、記事の執筆とプレビューできる環境を用意する為に
[Remote SSH] + [VS Code Server] + [devcontainer(Hugo開発・デバッグ環境)] により、SSH接続できる環境を用意すれば継続開発ができます。

# Hugo用devcontainer template
devcontainerはmicrosoftリポジトリにありますので、自身で作成は不要。

* devcontainerリポジトリ
  * https://github.com/microsoft/vscode-dev-containers/tree/main/containers/hugo

# DevContainer(Hugo)の起動
* "DevContainers: Add Dev Container Configuration File." を選択
* "全ての定義を表示" を選択
* "Hugo コミュニティ" を選択

# Hugoデバッグ方法
* VS Codeから以下のコマンドでhugo serverを立ち上げる
```
hugo server -D
```

* VS Code実行端末でhttp://localhost:1313へアクセス
* 注: themeの変更の場合は再起動が必要
