#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

# 检查并创建下载目录
mkdir -p ${DOWNLOAD_PATH}

# 判断是否需要下载 kernel 文件
if [ ! -f ${DOWNLOAD_PATH}/${KERNEL_FILENAME} ]; then
    debug_msg "Downloading KERNEL..."
    wget ${KERNEL_SRC} -O ${DOWNLOAD_PATH}/${KERNEL_FILENAME}
else
    debug_msg "Kernel already exists: ${DOWNLOAD_PATH}/${KERNEL_FILENAME}"
fi

# 定义 Kernel 解压目录
KERNEL_BUILD_DIR=${BUILD_PATH}/${KERNEL_FILENAME%.tar.gz}

# 检查并删除旧的 Kernel 构建目录（如果存在），不存在则解压源码
if [ -d "${KERNEL_BUILD_DIR}" ]; then
    debug_msg "Cleaning up Kernel build directory: ${KERNEL_BUILD_DIR}"
    # make -C "${KERNEL_BUILD_DIR}" ARCH=arm64 O=build clean
else
    debug_msg "Extracting Kernel..."
    tar -xzf ${DOWNLOAD_PATH}/${KERNEL_FILENAME} -C ${BUILD_PATH}
fi

# 检查解压后的 Kernel 目录是否存在
if [ ! -d "${KERNEL_BUILD_DIR}" ]; then
    echo "Error: Kernel extraction failed. Directory ${KERNEL_BUILD_DIR} not found."
    exit 1
fi

# 应用内核补丁或文件覆盖
if [[ -d ${ROOT_PATH}/overlay/kernel ]]; then
    debug_msg "Applying kernel overlay..."
    cp -R ${ROOT_PATH}/overlay/kernel/* ${KERNEL_BUILD_DIR}
fi

# 切换到 Kernel 构建目录
cd ${KERNEL_BUILD_DIR}
debug_msg "Kernel source is ready in ${KERNEL_BUILD_DIR}"

# 配置 Kernel 构建
debug_msg "Configuring Kernel build..."
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 O=build rk3328_defconfig

# 编译 Kernel
debug_msg "Building Kernel..."
make \
    CROSS_COMPILE=aarch64-linux-gnu- \
    ARCH=arm64 \
    EXTRAVERSION=-$(date +%Y%m%d-%H%M%S) \
    bindeb-pkg dtbs \
    O=build -j$(getconf _NPROCESSORS_ONLN)

# 确保输出目录存在
mkdir -p ${OUTPUT_PATH}/kernel

# 移动生成的 deb 文件到输出目录
mv linux-*.deb ${OUTPUT_PATH}/kernel/
mv linux-*.buildinfo ${OUTPUT_PATH}/kernel/
mv linux-*.changes ${OUTPUT_PATH}/kernel/

exit 0  # 脚本执行成功后退出
