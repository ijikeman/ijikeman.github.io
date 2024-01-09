---
title: "git submoduleの正しい削除方法"
date: 2023-10-12T15:50:03+00:00
# weight: 1
# aliases: ["/first"]
tags: ["git submodule"]
categories: [ "git" ]
author: "Me"
TocOpen: false
draft: false
# cover:
#     image: "test.jpg" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: false # only hide on current single page
---

## 結論
* 以下２点が重要
  * .gitmodulesを触らない
  * オリジナルリポジトリのgit履歴からも削除

## 方法
* サブモジュール自体を削除する場合は.git/modules/<submodule_name>/も削除する必要がある
* .gitmodulesからも消えないのはgit rm -rでサブモジュールを削除していないから
```
# サブモジュールを解除
$ git submodule deinit submodule-A
Cleared directory 'submodule-A'

# git履歴から削除(※これ重要で.gitmodulesから消えてくれる)
$ git rm -r submodule-A/

# .git以下からも削除(※これ重要。面倒くさい)
$ rm -rf .git/modules/submodule-A
```

## 正しく削除できていない時に発生するエラー
* その１
```
'submodule-A' already exists in the index
```

* その2
```
"submodule" already exists in the index
```
