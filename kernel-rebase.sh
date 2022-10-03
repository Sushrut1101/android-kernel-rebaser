#!/usr/bin/env bash

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'

# Project Directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Variables
ACK_REPO="https://android.googlesource.com/kernel/common.git"
OEM_KERNEL=${1}
ACK_BRANCH=${2}

# Help Function
usage() {
	echo -e "${0} \"link to oem kernel source (git)\" \"ack-branch\"
	>> eg: ${0} \"https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git -b dandelion-q-oss\" \"android-4.9-q\""
}

# Abort Function
abort() {
	[ ! -z "${@}" ] && echo -e ${RED}"${@}"${NORMAL}
	exit 1
}

# Clone the OEM Kernel Source
git clone --depth=1 --single-branch $(echo ${OEM_KERNEL}) oem

# Clone the Android Common Kernel Source
git clone --single-branch -b ${ACK_BRANCH} ${ACK_REPO} kernel

# Get the OEM Kernel's Version
cd oem
OEM_KERNEL_VERSION=$(make kernelversion)
cd -

# Hard Reset ACK to ${OEM_KERNEL_VERSION}
cd kernel
OEM_KERNEL_VER_SHORT_SHA=$(git log --oneline ${ACK_BRANCH} Makefile | grep -i ${OEM_KERNEL_VERSION} | grep -i merge | cut -d ' ' -f1)
git reset --hard ${OEM_KERNEL_VER_SHORT_SHA}
cd -

# Get the list of Directories of the OEM Kernel
cd oem
OEM_DIR_LIST=$(find -type d -printf "%P\n" | grep -v / | grep -v .git)
cd -

# Start Rebasing
cd kernel
for i in ${OEM_DIR_LIST}; do
	rm -rf ${i}
done

cd -
cp -r oem/* kernel/
cd kernel

for i in ${OEM_DIR_LIST}; do
	git add ${i}
	git commit -s -m "${i}: Import OEM Changes"
done

git add .
git commit -s -m "Import Remaining OEM Changes"

cd -

echo -e ${GREEN}"Your Kernel has been successfully rebased to ACK. Please check kernel/"${NORMAL}

# Exit
exit 0
