---
author: "ijikeman"
showToc: true
TocOpen: true
title: "AndroidでObsidianをGitHubと同期する方法（Termux + Obsidian Git）"
date: 2026-03-20T10:00:00+09:00
aliases: ["/obsidian/android-github"]
tags: ["Obsidian", "GitHub", "Termux", "Android", "Git"]
categories: ["Tools"]
draft: false
cover:
    image: "/images/eyecatch/obsidian/android-github/index.webp"
---

# このページでわかること
* TermuxとObsidian GitプラグインをつかってAndroid上でObsidianのVaultをGitHubリポジトリと同期する手順

---

# 事前準備
以下が揃っている前提で進めます。

* AndroidにObsidianがインストール済みであること
* GitHubアカウントを持っていること
* 同期対象のVaultを格納するGitHubリポジトリが作成済みであること

---

# 1. TermuxをF-Droidからインストールする

TermuxはAndroid向けのターミナルエミュレータです。
GitのインストールやSSH鍵の生成など、後続の手順はすべてTermux上で行います。

> **注意:** Termuxは必ずF-Droidからインストールしてください。
> Google Playストア版は更新が停止しており、パッケージのインストールに失敗する既知の問題があります。

* F-Droid公式サイト: https://f-droid.org/
* F-DroidからTermuxアプリを検索してインストールします

<!-- 画像プレースホルダー: F-DroidでTermuxを検索している画面のスクリーンショット -->

---

# 2. TermuxにGitをインストールする

Termuxを起動し、以下のコマンドを実行してパッケージリストを更新後、gitをインストールします。

```bash
pkg update && pkg upgrade -y
pkg install git -y
```

インストールが完了したら動作確認します。

```bash
git --version
```

```Plaintext
git version 2.x.x
```

---

# 3. SSH鍵を生成してGitHubに登録する

TermuxからGitHubへSSH接続するための鍵ペアを作成します。

### 3-1. SSH鍵の生成

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

対話プロンプトが表示されますが、すべてEnterで進めてデフォルト設定で生成します。

```Plaintext
Generating public/private ed25519 key pair.
Enter file in which to save the key (/data/data/com.termux/files/home/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /data/data/com.termux/files/home/.ssh/id_ed25519
Your public key has been saved in /data/data/com.termux/files/home/.ssh/id_ed25519.pub
```

### 3-2. 公開鍵の内容を確認する

```bash
cat ~/.ssh/id_ed25519.pub
```

出力された `ssh-ed25519 AAAA...` の文字列をすべてコピーします。

### 3-3. GitHubに公開鍵を登録する

1. GitHubにブラウザでログインします
2. [Settings] > [SSH and GPG keys] > [New SSH key] に移動します
3. Titleに任意の名前（例: `Termux Android`）を入力します
4. Keyフィールドにコピーした公開鍵を貼り付けます
5. [Add SSH key] をクリックします

<!-- 画像プレースホルダー: GitHubのSSH key登録画面のスクリーンショット -->

### 3-4. SSH接続の確認

```bash
ssh -T git@github.com
```

```Plaintext
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

上記のメッセージが表示されれば接続成功です。

---

# 4. Termuxにストレージ権限を付与してパスを設定する

TermuxからAndroidの共有ストレージ（ObsidianのVaultが存在する場所）にアクセスするために、ストレージ権限を付与します。

### 4-1. ストレージ権限の付与

```bash
termux-setup-storage
```

実行するとAndroidのシステムダイアログが表示されます。[許可] を選択します。

<!-- 画像プレースホルダー: Androidのストレージ権限ダイアログのスクリーンショット -->

### 4-2. アクセスパスの確認

権限付与後、共有ストレージへのシンボリックリンクが `~/storage/` 以下に作成されます。

```bash
ls ~/storage/
```

```Plaintext
dcim  downloads  external-1  movies  music  pictures  shared
```

Obsidianのデフォルトのストレージは `~/storage/shared/` 配下に存在します。
Vaultの実際のパスは端末やObsidianの設定によって異なります。

---

# 5. GitHubからVaultリポジトリをCloneする

ObsidianのVaultを格納するディレクトリへ移動し、GitHubリポジトリをcloneします。

### 5-1. Vaultを配置するディレクトリへ移動

Obsidianが参照できる共有ストレージ配下に移動します。
以下は `Documents` フォルダにcloneする例です。

```bash
cd ~/storage/shared/Documents
```

### 5-2. リポジトリのclone

```bash
git clone git@github.com:YOUR_USERNAME/YOUR_VAULT_REPO.git
```

`YOUR_USERNAME` と `YOUR_VAULT_REPO` は自身のGitHubユーザー名とリポジトリ名に置き換えてください。

```Plaintext
Cloning into 'YOUR_VAULT_REPO'...
remote: Enumerating objects: ...
...
```

### 5-3. gitのユーザー情報を設定する

コミット時に必要なユーザー情報をTermux内のgitに設定します。

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

---

# 6. ObsidianでCloneしたVaultを開く

1. Obsidianを起動します
2. [フォルダとして開く] を選択します
3. 手順5でcloneしたフォルダを選択します

<!-- 画像プレースホルダー: ObsidianでVaultフォルダを選択している画面のスクリーンショット -->

Vaultが正常に開くことを確認します。

---

# 7. Obsidian Gitプラグインをインストールする

Obsidian Gitはコミュニティプラグインとして提供されており、Obsidian内からGitの操作（push/pull）を行えます。

### 7-1. コミュニティプラグインを有効化する

1. Obsidianの [設定] > [コミュニティプラグイン] を開きます
2. [コミュニティプラグインを有効化] をオンにします

> **注意:** 初回は「セーフモード」を無効化するよう求められます。内容を確認の上、許可してください。

### 7-2. Obsidian Gitをインストールする

1. [コミュニティプラグインを参照] をタップします
2. 検索欄に `Obsidian Git` と入力します
3. 表示された `Obsidian Git` をタップし、[インストール] を選択します
4. インストール完了後、[有効化] をタップします

<!-- 画像プレースホルダー: Obsidian GitプラグインのインストールページのスクリーンショットとAndroid画面 -->

---

# 8. Obsidian Gitプラグインの設定を行う

プラグインのインストール後、設定画面で動作をカスタマイズします。

### 8-1. 設定画面を開く

[設定] > [コミュニティプラグイン] > `Obsidian Git` の歯車アイコンをタップします。

### 8-2. 主な設定項目

| 設定項目 | 推奨値 | 説明 |
| --- | --- | --- |
| Vault backup interval (minutes) | `30` | 指定分ごとに自動でcommit & pushを実行する |
| Auto pull interval (minutes) | `30` | 指定分ごとに自動でpullを実行する |
| Commit message | `vault backup: {{date}}` | 自動コミット時のメッセージテンプレート |
| Pull updates on startup | ON | Obsidian起動時に自動でpullする |
| Push on backup | ON | バックアップ時に自動でpushも行う |

<!-- 画像プレースホルダー: Obsidian Gitの設定画面のスクリーンショット -->

上記はあくまでも一例です。利用スタイルに合わせて間隔を調整してください。

---

# 9. 動作確認

### 9-1. 手動で同期する

コマンドパレット（Androidでは画面上部のコマンドボタンから開く）を起動し、以下のコマンドを実行します。

| 操作 | コマンド名 |
| --- | --- |
| プッシュ（バックアップ） | `Obsidian Git: Create backup` |
| プル（最新取得） | `Obsidian Git: Pull` |
| コミットのみ（pushなし） | `Obsidian Git: Commit all changes` |

### 9-2. 自動同期の確認

設定したインターバルの時間が経過すると、画面左下（もしくはステータスバー）にObsidian Gitのステータスが表示され、自動でcommit & pushが走ることを確認します。

<!-- 画像プレースホルダー: 自動同期後のステータス表示のスクリーンショット -->

### 9-3. GitHubで確認

ブラウザでGitHubリポジトリを開き、コミット履歴に自動バックアップのコミットが追加されていることを確認します。

<!-- 画像プレースホルダー: GitHubのcommit履歴画面のスクリーンショット -->

---

# 参考情報
* Termux公式 (F-Droid): https://f-droid.org/en/packages/com.termux/
* Obsidian Git (GitHub): https://github.com/denolehov/obsidian-git
* Obsidian公式: https://obsidian.md/
