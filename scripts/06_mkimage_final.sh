#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

# 创建一个临时目录，供生成镜像文件时使用
GENIMAGE_ROOT=$(mktemp -d)

# setup and move bits
mkdir -p ${BUILD_PATH}/final
cp ${BUILD_PATH}/boot.vfat ${BUILD_PATH}/final/
cp ${BUILD_PATH}/rootfs.ext4 ${BUILD_PATH}/final/
cp ${ROOT_PATH}/genimage_final.cfg ${BUILD_PATH}/genimage.cfg

# Update UUID in genimage.cfg to match what u-boot has set
sed -i "s|PLACEHOLDERUUID|$(cat ${BUILD_PATH}/disk-signature.txt)|g" ${BUILD_PATH}/genimage.cfg

echo "Generating disk image"
cp ${OUTPUT_PATH}/uboot/u-boot.bin ${BUILD_PATH}/final/u-boot.bin

sudo rm -rf /tmp/genimage-initial-tmppath # 删除之前的临时目录
sudo genimage \
    --rootpath "${GENIMAGE_ROOT}" \
    --tmppath "/tmp/genimage-initial-tmppath" \
    --inputpath "${BUILD_PATH}/final" \
    --outputpath "${BUILD_PATH}/final" \
    --config "${BUILD_PATH}/genimage.cfg"

mkdir -p ${OUTPUT_PATH}
mv ${BUILD_PATH}/final/sdcard.img ${OUTPUT_PATH}/debian-sdcard.img
gzip ${OUTPUT_PATH}/debian-sdcard.img

sudo rm -rf /tmp/genimage-initial-tmppath
