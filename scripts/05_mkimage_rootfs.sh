#!/bin/bash
set -e

# 引入配置文件 config.sh 中的变量和设置
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
. ${SCRIPT_PATH}/config.sh

BOOT_LOOP_DEV=""
ROOTFS_LOOP_DEV=""

# 定义清理函数
cleanup() {
    debug_msg "Cleaning up..."
    # 卸载 /boot 挂载点
    if mountpoint -q ${BUILD_PATH}/rootfs/boot; then
        sudo umount -l ${BUILD_PATH}/rootfs/boot || true
    fi
    # 卸载 rootfs 挂载点
    if mountpoint -q ${BUILD_PATH}/rootfs; then
        sudo umount -l ${BUILD_PATH}/rootfs || true
    fi
    # 释放 loopback 设备
    if [ -n "${BOOT_LOOP_DEV}" ]; then
        sudo losetup -d ${BOOT_LOOP_DEV} || true
    fi
    if [ -n "${ROOTFS_LOOP_DEV}" ]; then
        sudo losetup -d ${ROOTFS_LOOP_DEV} || true
    fi
    # 删除构建目录
    rm -rf ${build_path}/rootfs
    rm -rf ${BUILD_PATH}/disk-signature.txt
}

# 捕获脚本退出或中断信号，并执行清理
trap cleanup EXIT

debug_msg "Cleaning up previous runs..."
rm -rf ${build_path}/disk-signature.txt

# 挂载 loopback 设备
debug_msg "Mounting generated block files for use with docker..."
BOOT_LOOP_DEV=$(sudo losetup -f --show ${BUILD_PATH}/boot.vfat)
ROOTFS_LOOP_DEV=$(sudo losetup -f --show ${BUILD_PATH}/rootfs.ext4)

# 挂载目录
mkdir -p ${BUILD_PATH}/rootfs
sudo mount -t ext4 ${ROOTFS_LOOP_DEV} ${BUILD_PATH}/rootfs
sudo mkdir -p ${BUILD_PATH}/rootfs/boot
sudo mount -t vfat ${BOOT_LOOP_DEV} ${BUILD_PATH}/rootfs/boot

# 删除占位符文件
sudo rm -f ${BUILD_PATH}/rootfs/placeholder ${BUILD_PATH}/rootfs/boot/placeholder

# 生成随机磁盘签名
sudo hexdump -n 4 -e '1 "0x%08X" 1 "\n"' /dev/urandom > ${BUILD_PATH}/disk-signature.txt

# 执行 debootstrap 和 chroot
cd ${BUILD_PATH}/rootfs
sudo debootstrap --no-check-gpg --foreign --arch=arm64 --include=apt-transport-https bookworm ${BUILD_PATH}/rootfs http://ftp.cn.debian.org/debian
sudo cp /usr/bin/qemu-aarch64-static usr/bin/
sudo chroot ${BUILD_PATH}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our overlay if we have one
if [[ -d ${ROOT_PATH}/overlay/ ]]; then
	debug_msg "Applying rootfs overlay"
	sudo cp -R ${ROOT_PATH}/overlay/rootfs/* ./
fi

# Apply our disk signature to fstab
UBOOTUUID=$(cat ${BUILD_PATH}/disk-signature.txt | awk '{print tolower($0)}')
sudo sed -i "s|PLACEHOLDERUUID|${UBOOTUUID:2}|g" ${BUILD_PATH}/rootfs/etc/fstab

# Hostname
debug_msg "debian" | sudo tee ${BUILD_PATH}/rootfs/etc/hostname > /dev/null
debug_msg "127.0.1.1	debian" | sudo tee -a ${BUILD_PATH}/rootfs/etc/hosts > /dev/null

# Console settings
cat <<EOF | sudo tee ${BUILD_PATH}/rootfs/debconf.set >/dev/null
console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
EOF

# Copy over kernel goodies
sudo cp -r ${OUTPUT_PATH}/kernel ${BUILD_PATH}/rootfs/root/

# Kick off bash setup script within chroot
sudo cp ${ROOT_PATH}/bootstrap ${BUILD_PATH}/rootfs/bootstrap
sudo chroot ${BUILD_PATH}/rootfs bash /bootstrap
sudo rm ${BUILD_PATH}/rootfs/bootstrap

# Final cleanup
sudo rm ${BUILD_PATH}/rootfs/usr/bin/qemu-aarch64-static

debug_msg "All done!"
