---
title: "git submoduleコマンドの理解"
date: 2023-10-12T11:30:03+00:00
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

### 参考
* [git-scm.com git-submodule](https://git-scm.com/docs/git-submodule)
* [git-scm.com - 7.11 Git のさまざまなツール - サブモジュール](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%81%95%E3%81%BE%E3%81%96%E3%81%BE%E3%81%AA%E3%83%84%E3%83%BC%E3%83%AB-%E3%82%B5%E3%83%96%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB)

# git submoduleコマンドオプション一覧
### add ... サブモジュールを追加
* .gitsubmodulesファイルに追記される(存在しなければ生成)
* タグ指定やコミットハッシュ指定ができないので注意
```
$ git submodule add --name submodule-A --branch main --depth 1 https://github.com/example/submodule-A.git
$ cat .gitmodules
[submodule "submodule-A"]
        path = submodule-A
        url = https://github.com/example/submodule-A.git
        branch = main
```

* タグ、コミットハッシュ指定する
  * 参考: https://stackoverflow.com/questions/1777854/how-can-i-specify-a-branch-tag-when-adding-a-git-submodule
```
$ cd submodule-A
git checkout v1.0
cd ..
git add submodule-A
git commit -m "moved submodule to v1.0"
git push
```

#### [発生するエラー]
* 既に追加されている(.submodulesから手動削除しても)
```
'submodule-A' already exists in the index
```

* 手動で削除したりすると怒られる。空ファイルを作成して再実行
```
please make sure that the .gitmodules file is in the working tree
```

* サブモジュール削除の残骸による影響
  * --forceをつけて強制追加するか
  * 下記deinitを参考に正しく解除する
```
"submodule" already exists in the index
```

### status
### init ... サブモジュールフォルダを初期化
### deinit ... サブモジュールを解除
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

### update .. サブモジュールフォルダを更新する
* deinitした後にupdateすると、指定branchの状態に戻せる
```
# ファイルを削除する
$ ls -a submodule-A/
. .. .git README.md
$ rm -f submodule-A/README.md

# いったんサブモジュールをクリア
$ git submodule deinit submodule-A
Cleared directory 'submodule-A'
$ ls -a submodule-A/
.  ..

# 再度updateすると初期checkout状態に戻る
$ git submodule update submodule-A
Submodule path 'submodule-A': checked out 'efe4cb45161be836d602d5cd0f857e62661dae8b'
$ ls -a submodule-A/
. .. .git README.md
```

### checkout
### rebase
### merge
### custom
### none
### set-branch
### set-url
### summary
### foreach
### sync
### absorbgitdirs
