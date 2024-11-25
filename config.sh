#!/bin/bash
set -e

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_PATH="${ROOT_PATH}/build"
DOWNLOAD_PATH="${BUILD_PATH}/download"
OUTPUT_PATH="${ROOT_PATH}/output"

# Arm Trusted Firmware
ATF_SRC="https://github.com/rockchip-linux/rkbin/archive/refs/heads/master.zip"
ATF_FILENAME="rkbin-master.zip"

debug_msg() {
    BLU='\033[0;32m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

error_msg() {
    BLU='\033[0;31m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}
