#!/bin/bash
MD_PATH=$1
FONTDIR='HackGen_v2.9.0'
MOUNT_POINT="/go/mount/"
TEMPLATE_IMAGE='eyecatch_template2.png'
MOUNT_SRC='/home/vscode/project/ijikeman.github.io/'

mkdir -p ./static/images/eyecatch/${MD_PATH}

docker run --rm -v ${MOUNT_SRC}:${MOUNT_POINT} tcardgen bash -c \
"tcardgen --fontDir ${MOUNT_POINT}/static/fonts/${FONTDIR} \
--output ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH} \
--template ${MOUNT_POINT}/static/images/templates/${TEMPLATE_IMAGE} --config ${MOUNT_POINT}/static/tcardgen/tcardgen.yaml \
${MOUNT_POINT}/content/posts/${MD_PATH}/index.md"

docker run --rm -v ${MOUNT_SRC}:${MOUNT_POINT} tcardgen bash -c "convert -resize "50%" ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH}/index.png ${MOUNT_POINT}/static/images/eyecatch/${MD_PATH}/index.dst.png"
mv -f ./static/images/eyecatch/${MD_PATH}/index.dst.png ./static/images/eyecatch/${MD_PATH}/index.png
