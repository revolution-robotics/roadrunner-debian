#!/usr/bin/env bash
#
declare -r ARCH_CPU="32BIT"

# U-Boot
declare -r G_UBOOT_SRC_DIR="${DEF_SRC_DIR}/uboot"
declare -r G_UBOOT_GIT="https://github.com/revolution-robotics/roadrunner-uboot-imx.git"
declare -r G_UBOOT_BRANCH="imx_v2018.03_4.14.78_1.0.0_ga_var01_rr01"
declare -r G_UBOOT_REV="4efa8e63a6364e484307d8cbb79f053f7e91f4a9"
declare -r G_UBOOT_DEF_CONFIG_MMC='mx7d_roadrunner_defconfig'
declare -r G_UBOOT_DEF_CONFIG_NAND='mx7d_roadrunner_nand_defconfig'
declare -r G_UBOOT_NAME_FOR_EMMC='u-boot.img.mmc'
declare -r G_SPL_NAME_FOR_EMMC='SPL.mmc'
declare -r G_UBOOT_NAME_FOR_NAND='u-boot.img.nand'
declare -r G_SPL_NAME_FOR_NAND='SPL.nand'

# Linux kernel
declare -r G_LINUX_KERNEL_SRC_DIR="${DEF_SRC_DIR}/kernel"
declare -r G_LINUX_KERNEL_GIT="https://github.com/revolution-robotics/roadrunner-linux-imx.git"
declare -r G_LINUX_KERNEL_BRANCH="imx_4.14.78_1.0.0_ga_var01_rr01"
declare -r G_LINUX_KERNEL_REV="4d80804d8759fe5a31535a4e56e8125b2cc736fa"
# declare -r G_LINUX_KERNEL_BRANCH="5.4-2.1.x-imx_var01_rr01"
# declare -r G_LINUX_KERNEL_REV="2f51141278845d554d1370a6bfcaa09403fbe601"
declare -r G_LINUX_KERNEL_DEF_CONFIG='imx_v7_roadrunner_defconfig'
declare -r G_LINUX_DTB="imx7d-roadrunner-gpio16.dtb imx7d-roadrunner-iomix.dtb"

# ACCESS_CONTROL must be one of:
#   Apparmor
#   SELinux
#   Unix
declare -r ACCESS_CONTROL=Apparmor
declare -r UBOOT_SCRIPT="boot.scr"
declare -r UBOOT_PROVISION_SCRIPT="provision.scr"
declare -r BUILD_IMAGE_TYPE="uImage"
if test ."$BUILD_IMAGE_TYPE" = .'uImage'; then
    declare -r UIMAGE_LOADADDR=0x80800000
fi
declare -r KERNEL_BOOT_IMAGE_SRC="arch/arm/boot/"
declare -r KERNEL_DTB_IMAGE_PATH="arch/arm/boot/dts/"

# SDMA Firmware
declare -r G_IMX_SDMA_FW_SRC_DIR="${G_VENDOR_PATH}/deb/firmware-misc-nonfree"

# Broadcom BT/WIFI firmware
declare -r G_BCM_FW_SRC_DIR="${DEF_SRC_DIR}/bcmfw"
declare -r G_BCM_FW_GIT="https://github.com/varigit/bcm_4343w_fw.git"
declare -r G_BCM_FW_GIT_BRANCH="6.0.0.121"
declare -r G_BCM_FW_GIT_REV="7bce9b69b51ffd967176c1597feed79305927370"

# ubi
declare -r G_UBI_FILE_NAME='rootfs.ubi.img'

# REVO web dispatch
declare -r G_REVO_WEB_DISPATCH_SRC_DIR="${DEF_SRC_DIR}/web_dispatch"
declare -r G_REVO_WEB_DISPATCH_GIT="https://github.com/revolution-robotics/roadrunner-web-dispatch.git"
declare -r G_REVO_WEB_DISPATCH_BRANCH="golang"
declare -r G_REVO_WEB_DISPATCH_REV="6aa8f314b80f515309a18840dc2f8c5591c8e9c8"

# Node version and user
declare -r NODE_BASE=14.
declare -r NODE_GROUP=revo
declare -r NODE_USER=revo
