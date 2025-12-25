---
author: "ijikeman"
showToc: true
TocOpen: true
title: "VHSの設定ファイルからターミナル動画Gifを作成する"
date: 2025-12-24T12:00:00+09:00
# weight: 1
aliases: ["/vhsy/config"]
tags: ["vhs", "terminal"]
categories: ["Infrastructure", "Tools"]
draft: false
cover:
    image: "/images/eyecatch/vhs/config/index.webp"
---

# この記事でわかること
* .tapeファイルの構成
* .tapeファイルを実際に入力して作成する場合
* .tapeファイルに出力設定を行う
* .tapeファイルを実行する

# 関連記事
* [VHSによるデモ動画GIFの作成環境の構築](/posts/vhs/install/)
* [VHSの設定ファイルからターミナル動画Gifを作成する](/posts/vhs/config/)

# 概要
[前回の記事](/posts/vhs/install/)でVHSのセットアップを行いましたので、実際に設定ファイルを作成し
ターミナル操作動画を作成していきます。

# 1. VHSの簡単な使い方
1. tapeファイルテンプレートの作成
```bash
vhs new sample.tape
---
Created sample.tape
```

2. .tapeファイルを編集する
```bash
vi sample.tape
```

3. 構文チェック
```bash
vhs validate sample.tape
```

4. .tapeファイルを実行する
```bash
vhs < sample.tape
```

# 2. .tapeファイルの構成
## 2-1. 記録したい実行コマンドの記載
以下の設定を記載することでその結果を録画することができます。

| [Config Format] | [設定例] |  [意味] |
| --- | --- | --- |
| Type "[COMMAND]" | Type "echo Test"| 実行したいコマンドを記載 |
| Sleep [NUM] | Sleep 0.1s | 待機する時間を設定 単位を省略すると秒(単位:ms, s) |
| Enter [NUM] | Enter 1 |EnterキーをNum回実行 |
| Ctrl+[KEY] | Ctrl+C  | Ctrl+キーを実行 |
| Wait /[STRING]/ | Wait /Hello/ | 画面に指定した文字が表示されるまで待つ |
| Hide | Hide | Show設定が行われるまで画面表示を隠す |
| Show | Show | Hide設定からShow設定までの画面結果を表示する |
| Source [FILE.tape] | Source command.tape | 別の.tapeファイルにある.tapeを読み込んで実行 |

## 2-2. 出力設定
以下の設定を記載することで出力される画像の設定を調整することができます。

| [Config Format] | [設定例] |  [意味] |
| --- | --- | --- |
| Output FILENAME | Output example.gif | 出力先のファイル名を指定 |
| Set Shell [VALUE] | Set Shell bash | 実行時のシェルを指定 |
| Set FontSize [VALUE] | Set FontSize 10 | フォントサイズを指定 |
| Set FontFamily "[VALUE]" | Set FontFamily "Monoflow" | フォントを指定 |
| Set Width [NUM] | Set Width 128 | 画像出力の幅を指定 |
| Set Height [NUM] | Set Height 80 | 画像出力の高さを指定 |
| Set LetterSpacing [NUM] | Set LetterSpacing 5 | 文字間隔を指定 |
| Set LineHeight [NUM] | Set LineHeight 1.8 | 行間隔を指定 |
| Set TypingSpeed [NUM] | Set TypingSpeed 500ms | タイピング速度を指定 |
| Type@TypingSpeed "[String]" | Type@10ms "Hellow World!" | 入力速度を対象行のみ指定 |
| Set Theme "[THEME NAME]" | Set Theme "Catppuccin Frappe" | テーマを指定 |
| Set WindowBar [VALUE] | Set WindowBar Colorful | ウィンドーフレームに表示するバーを指定(Colorful、ColorfulRight、Rings、RingsRight) ) |
| Set Framerate [NUM] | Set Framerate 60 | フレームレートを指定 |
| Set PlaybackSpeed [NUM] | Set PlaybackSpeed 0.5 | レンダリングの再生速度を指定(0.1 - 1.0(default) - 2.0) |
| Set CursorBlink [true/false] | Set CursorBlink true | カーソルを点滅させる |

# 3. ファイル編集で設定する手間を省く実際に入力して.
上記設定を記載していくのは大変なため、実際のターミナルを操作して.tapeを作成する方法があります。

recordコマンドを使用して、実際のコマンドを入力して.tapeファイルを作成することで効率的に作成することができます。

## 3-1. recordを使ってコマンドを記録する
```bash
vhs record > sample.tape
---
ここに実行したいコマンドを実行する

Ctrl + C で終了
```

実行すると以下の様子になり実行したコマンドがsample.tapeに保存されます。

![vhs-record](vhs-record.gif)

## 3-2. 生成された.tapeファイル
* sample.tape
```
Type "echo 'Welcome to VHS!'"
Sleep 500ms # 500ミリ秒待機
Enter 1 # Enterキーを押す
Sleep 5s # 5秒待機
```

## 3-3 .tapeファイルに出力設定を行う
入力したコマンドの設定しか記載されていない為、この.tapeファイルを実行しても画像は生成されません。
画像出力設定を追記して、.gifファイルを出力するようにします。

```bash
# 行頭にOutput設定を追加する
sed -i '1i Output sample.gif' sample.tape
```

## 3-4 .tapeファイルを実行する
修正したsample.tapeをvhsコマンドで実行し、sample.gifを作成します。
```bash
vhs < sample.tape
```

実行すると以下の様子になり、vhsの実行が完了すると設定したコマンドを実行したgifが生成されます。
![vhs-run](vhs-run.gif)

生成されたsample.gifは以下になります。
![sample.gif](sample.gif)
