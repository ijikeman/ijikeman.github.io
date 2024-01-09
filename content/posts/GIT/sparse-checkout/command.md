---
title: "Git部分チェックアウト git sparse-checkoutコマンドの理解"
date: 2023-10-12T18:30:00+00:00
# weight: 1
# aliases: ["/first"]
tags: ["git", "sparse-checkout"]
categories: [ "git" ]
author: "Me"
TocOpen: false
draft: true
# cover:
#     image: "test.jpg" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---
# 参考サイト

https://git-scm.com/docs/git-sparse-checkout

### memo
```
特にこれ自体に意味がないが、調べて試してみたかったのでhugo templateだけをcloneしてみる

# .gitのみgit cloneする

git clone --no-checkout --depth=1 https://github.com/microsoft/vscode-dev-containers.git
----------------------------------------------------------------------------------------

Cloning into 'vscode-dev-containers'...
remote: Enumerating objects: 1652, done.
remote: Counting objects: 100% (1652/1652), done.
remote: Compressing objects: 100% (1040/1040), done.
remote: Total 1652 (delta 746), reused 1019 (delta 480), pack-reused 0
Receiving objects: 100% (1652/1652), 971.19 KiB | 5.99 MiB/s, done.
Resolving deltas: 100% (746/746), done.

ls -al vscode-dev-containers/
total 0
drwxr-xr-x 3 vscode users  17 Oct 13 18:09 .
drwxr-xr-x 6 vscode users 106 Oct 13 18:09 ..
drwxr-xr-x 8 vscode users 154 Oct 13 18:09 .git

# 部分チェックアウトするためのルールを設定

git sparse-checkout init
git sparse-checkout add containers/hugo
git sparse-checkout list
------------------------

/*
!/*/
containers/hugo
---------------

git checkout
------------

Your branch is up to date with 'origin/main'.
---------------------------------------------

ls -al
total 640
drwxr-xr-x 4 vscode users   4096 Oct 13 18:12 .
drwxr-xr-x 5 vscode users     92 Oct 13 18:10 ..
-rw-r--r-- 1 vscode users    242 Oct 13 18:12 azure-pipelines.yml
-rw-r--r-- 1 vscode users   1414 Oct 13 18:12 cgmanifest.json
drwxr-xr-x 3 vscode users     17 Oct 13 18:12 containers
-rw-r--r-- 1 vscode users   2721 Oct 13 18:12 CONTRIBUTING.md
-rw-r--r-- 1 vscode users  59068 Oct 13 18:12 devcontainer-collection.json
-rw-r--r-- 1 vscode users    134 Oct 13 18:12 .editorconfig
drwxr-xr-x 8 vscode users   4096 Oct 13 18:12 .git
-rw-r--r-- 1 vscode users    154 Oct 13 18:12 .gitattributes
-rw-r--r-- 1 vscode users   5732 Oct 13 18:12 .gitignore
-rw-r--r-- 1 vscode users   1162 Oct 13 18:12 LICENSE
-rw-r--r-- 1 vscode users 506878 Oct 13 18:12 NOTICE.txt
-rw-r--r-- 1 vscode users    983 Oct 13 18:12 package.json
-rw-r--r-- 1 vscode users  10207 Oct 13 18:12 README.md
-rw-r--r-- 1 vscode users   2780 Oct 13 18:12 SECURITY.md
-rw-r--r-- 1 vscode users   2179 Oct 13 18:12 SUPPORT.md
-rw-r--r-- 1 vscode users  17730 Oct 13 18:12 yarn.lock

ls -al containers/
total 4
drwxr-xr-x 3 vscode users   17 Oct 13 18:12 .
drwxr-xr-x 4 vscode users 4096 Oct 13 18:12 ..
drwxr-xr-x 4 vscode users  106 Oct 13 18:12 hugo

ls -al containers/hugo/
total 12
drwxr-xr-x 4 vscode users  106 Oct 13 18:12 .
drwxr-xr-x 3 vscode users   17 Oct 13 18:12 ..
drwxr-xr-x 2 vscode users   47 Oct 13 18:12 .devcontainer
-rw-r--r-- 1 vscode users  403 Oct 13 18:12 devcontainer-template.json
-rw-r--r-- 1 vscode users   77 Oct 13 18:12 .npmignore
-rw-r--r-- 1 vscode users 2701 Oct 13 18:12 README.md
drwxr-xr-x 2 vscode users   23 Oct 13 18:12 .vscode
```
```
```