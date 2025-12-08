# 軽量なAlpine Linuxをベースイメージとして使用
FROM alpine:latest

# WebPツール（libwebp）をインストール
# cwebpコマンドが含まれます
RUN apk add --no-cache libwebp-tools

# コンテナが起動したときに実行されるデフォルトコマンドを定義
# ユーザーが独自のコマンドを指定しない限り、cwebpの使用方法を表示します
CMD ["cwebp", "--help"]
