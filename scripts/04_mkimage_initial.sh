#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

# 开始清理旧文件
debug_msg "Cleaning up..."

# 如果存在 boot.vfat 文件，则删除并输出提示
if [ -f "${BUILD_PATH}/boot.vfat" ]; then
	rm -rf "${BUILD_PATH}/boot.vfat"
	debug_msg "Deleted: ${BUILD_PATH}/boot.vfat"
fi

# 如果存在 rootfs.ext4 文件，则删除并输出提示
if [ -f "${BUILD_PATH}/rootfs.ext4" ]; then
	rm -rf "${BUILD_PATH}/rootfs.ext4"
	debug_msg "Deleted: ${BUILD_PATH}/rootfs.ext4"
fi

# 创建一个临时目录，供生成镜像文件时使用
GENIMAGE_ROOT=$(mktemp -d)

# 在临时目录下创建一个 "伪" 文件，确保 genimage 工具可以正常运行
touch ${GENIMAGE_ROOT}/placeholder

# 使用 genimage 工具生成 boot 和 rootfs 镜像文件
# - --rootpath：指定根目录的路径（包含要打包的文件）
# - --tmppath：指定临时工作目录，用于存放中间生成的文件
# - --inputpath：指定输入路径，包含构建的文件（如 U-Boot、内核、rootfs 等）
# - --outputpath：指定输出路径，镜像生成后存放的位置
# - --config：指定 genimage 配置文件，定义了镜像的结构和内容
sudo rm -rf /tmp/genimage-initial-tmppath # 删除之前的临时目录
sudo genimage \
	--rootpath "${GENIMAGE_ROOT}" \
	--tmppath "/tmp/genimage-initial-tmppath" \
	--inputpath "${BUILD_PATH}" \
	--outputpath "${BUILD_PATH}" \
	--config "${ROOT_PATH}/genimage_initial.cfg"

exit 0 # 执行成功后退出
