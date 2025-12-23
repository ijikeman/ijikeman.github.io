#!/bin/bash

MD_PATH=$1 # hugo blog path
FONTDIR='HackGen_v2.9.0'
MOUNT_POINT="/go/mount/" # tcardgen mount point
TEMPLATE_IMAGE='eyecatch_template.png' # eyecatch template file
MOUNT_SRC='/home/vscode/project/ijikeman.github.io/' # hugo blog path
TCARDGEN_IMAGE='tcardgen:v0.9.0'
WEBP_IMAGE='webp:latest'

# アイキャッチ画像フォルダの作成
mkdir -p ./static/images/eyecatch/${MD_PATH}

# Docker build
docker build -t tcardgen:v0.9.0 ./Dockerfiles/tcardgen/
docker build -t webp:latest ./Dockerfiles/webp/

# tcardgenでアイキャッチ画像をpngで作成
docker run --rm -v ${MOUNT_SRC}:${MOUNT_POINT} ${TCARDGEN_IMAGE} bash -c \
"tcardgen --fontDir ${MOUNT_POINT}/static/fonts/${FONTDIR} \
--output ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH} \
--template ${MOUNT_POINT}/static/images/templates/${TEMPLATE_IMAGE} --config ${MOUNT_POINT}/static/tcardgen/tcardgen.yaml \
${MOUNT_POINT}/content/posts/${MD_PATH}/index.md"

# webpのcwebpコマンドでpng to webpコンバート
docker run --rm -v ${MOUNT_SRC}:/${MOUNT_POINT} webp \
cwebp ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH}/index.png \
-o ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH}/index.webp

# コンバートが終了したので削除
rm -f ./static/images/eyecatch/${MD_PATH}/index.png
