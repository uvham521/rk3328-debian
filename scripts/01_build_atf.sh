#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

# 检查并创建下载目录
mkdir -p ${DOWNLOAD_PATH}

# 判断 Arm Trusted Firmware 是否已下载，未下载则从指定链接下载
if [ ! -f ${DOWNLOAD_PATH}/${ATF_FILENAME} ]; then
    debug_msg "Downloading Arm Trusted Firmware..."
    wget ${ATF_SRC} -O ${DOWNLOAD_PATH}/${ATF_FILENAME}
else
    debug_msg "Arm Trusted Firmware already exists: ${DOWNLOAD_PATH}/${ATF_FILENAME}"
fi

# 创建临时目录以解压 Arm Trusted Firmware
ATF_BUILD_DIR=$(mktemp -d)
unzip -q ${DOWNLOAD_PATH}/${ATF_FILENAME} -d ${ATF_BUILD_DIR}

# 检查并删除旧的 bl31.bin 文件（如果存在）
if [ -f "${OUTPUT_PATH}/atf/bl31.bin" ]; then
    debug_msg "bl31.bin already exists. Deleting: ${OUTPUT_PATH}/atf/bl31.bin"
    rm -f "${OUTPUT_PATH}/atf/bl31.bin"
fi

# 确保输出目录存在
mkdir -p ${OUTPUT_PATH}/atf

# 复制解压出的 bl31 文件到目标位置
cp $ATF_BUILD_DIR/rkbin-master/bin/rk33/rk322xh_bl31_v1.49.elf ${OUTPUT_PATH}/atf/bl31.bin

# 打印成功消息
debug_msg "Successfully prepared bl31.bin at ${OUTPUT_PATH}/atf/bl31.bin"

exit 0 # 执行成功后退出
