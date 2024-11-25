#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

# 检查并创建下载目录
mkdir -p ${DOWNLOAD_PATH}

# 判断是否需要下载 U-Boot 文件
if [ ! -f ${DOWNLOAD_PATH}/${UBOOT_FILENAME} ]; then
    debug_msg "Downloading U-Boot..."
    wget ${UBOOT_SRC} -O ${DOWNLOAD_PATH}/${UBOOT_FILENAME}
else
    debug_msg "U-Boot already exists: ${DOWNLOAD_PATH}/${UBOOT_FILENAME}"
fi

# 定义 U-Boot 解压目录
UBOOT_BUILD_DIR=${BUILD_PATH}/${UBOOT_FILENAME%.zip}

# 检查并删除旧的 U-Boot 构建目录（如果存在）
if [ -d "${UBOOT_BUILD_DIR}" ]; then
    debug_msg "Cleaning up existing U-Boot build directory: ${UBOOT_BUILD_DIR}"
    rm -rf "${UBOOT_BUILD_DIR}"
fi

# 解压 U-Boot 文件到指定构建目录
debug_msg "Extracting U-Boot..."
unzip -q ${DOWNLOAD_PATH}/${UBOOT_FILENAME} -d ${BUILD_PATH}

# 切换到 U-Boot 构建目录
cd ${UBOOT_BUILD_DIR}
debug_msg "U-Boot source is ready in ${UBOOT_BUILD_DIR}"

# 配置 U-Boot 构建
debug_msg "Configuring U-Boot build..."
make CROSS_COMPILE=aarch64-linux-gnu- O=build roc-cc-rk3328_defconfig

# 检查 BL31 文件是否存在
if [ ! -f "${OUTPUT_PATH}/atf/bl31.bin" ]; then
    echo "Error: BL31 file not found at ${OUTPUT_PATH}/atf/bl31.bin. Please ensure Arm Trusted Firmware is built first."
    exit 1
fi

# 编译 U-Boot
debug_msg "Building U-Boot..."
make \
    CROSS_COMPILE=aarch64-linux-gnu- \
    BL31=${OUTPUT_PATH}/atf/bl31.bin \
    O=build -j$(getconf _NPROCESSORS_ONLN)

# 确保输出目录存在
mkdir -p ${OUTPUT_PATH}/uboot

# 移动生成的 U-Boot 文件到输出目录
mv build/u-boot-rockchip.bin ${OUTPUT_PATH}/uboot/u-boot.bin
debug_msg "U-Boot build completed successfully. Output: ${OUTPUT_PATH}/uboot/u-boot.bin"

exit 0  # 脚本执行成功后退出
