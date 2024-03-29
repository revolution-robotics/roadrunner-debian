#!/usr/bin/env bash
#
declare -r ARCH_CPU=32BIT
declare -r ARCH_ARGS=arm
declare -r ARCH_VERSION=7

# U-Boot
declare -r G_UBOOT_GIT=https://github.com/revolution-robotics/roadrunner-uboot-imx.git
# declare -r G_UBOOT_BRANCH=imx_v2018.03_4.14.78_1.0.0_ga_var01_rr01
# declare -r G_UBOOT_REV=4efa8e63a6364e484307d8cbb79f053f7e91f4a9
# declare -r G_UBOOT_BRANCH=imx_4.14.78_blade
# declare -r G_UBOOT_REV=ff44929407a03e5af02199388e9500af2a69156c
declare -r G_UBOOT_BRANCH=imx_v2018.03_4.14.78_1.0.0_ga_var02_rr01
declare -r G_UBOOT_REV=0966f389fba76819cb9ef4f0acc0f88d287f9ed6
declare -r G_UBOOT_SRC_DIR=${DEF_SRC_DIR}/uboot
declare -r G_UBOOT_DEF_CONFIG_MMC=mx7d_roadrunner_defconfig
declare -r G_UBOOT_DEF_CONFIG_NAND=mx7d_roadrunner_nand_defconfig
declare -r G_UBOOT_NAME_FOR_EMMC=u-boot.img.mmc
declare -r G_SPL_NAME_FOR_EMMC=SPL.mmc
declare -r G_UBOOT_NAME_FOR_NAND=u-boot.img.nand
declare -r G_SPL_NAME_FOR_NAND=SPL.nand

# Linux kernel
declare -r G_LINUX_KERNEL_GIT=https://github.com/revolution-robotics/roadrunner-linux-imx.git
# declare -r G_LINUX_KERNEL_BRANCH=imx_4.14.78_1.0.0_ga_var01_rr01
# declare -r G_LINUX_KERNEL_REV=4d80804d8759fe5a31535a4e56e8125b2cc736fa
# declare -r G_LINUX_KERNEL_BRANCH=imx_5.4.85_1.0.0_revo
# declare -r G_LINUX_KERNEL_REV=9292229fa9587f0587541bc2962685a442cbd6db
declare -r G_LINUX_KERNEL_BRANCH=imx_5.4.142_1.0.0_revo
declare -r G_LINUX_KERNEL_REV=1095950f72be5a6207e81b0fc848838f9ae79331
declare -r G_LINUX_KERNEL_SRC_DIR=${DEF_SRC_DIR}/kernel
declare -r G_LINUX_KERNEL_DEF_CONFIG=imx_v7_roadrunner_defconfig
declare -r G_LINUX_DTB='imx7d-roadrunner-gpio16.dtb imx7d-roadrunner-iomix.dtb imx7d-roadrunner-blade.dtb'

# ACCESS_CONTROL must be one of:
#   Apparmor
#   SELinux
#   Unix
declare -r ACCESS_CONTROL=Apparmor
declare -r UBOOT_SCRIPT=boot.scr
declare -r UBOOT_PROVISION_SCRIPT=provision.scr

# IMAGE_TYPE is either zImage or (checksummed) uImage
declare -r BUILD_IMAGE_TYPE=uImage
if test ."$BUILD_IMAGE_TYPE" = .'uImage'; then
    declare -r UIMAGE_LOADADDR=0x80800000
fi
declare -r KERNEL_BOOT_IMAGE_SRC=arch/arm/boot/
declare -r KERNEL_DTB_IMAGE_PATH=arch/arm/boot/dts/

# SDMA Firmware
declare -r G_IMX_SDMA_FW_SRC_DIR=${G_VENDOR_PATH}/deb/firmware-misc-nonfree

# Broadcom BT/WIFI firmware
declare -r G_BCM_FW_GIT=https://github.com/varigit/bcm_4343w_fw.git
declare -r G_BCM_FW_GIT_BRANCH=6.0.0.121
declare -r G_BCM_FW_GIT_REV=7bce9b69b51ffd967176c1597feed79305927370
declare -r G_BCM_FW_SRC_DIR=${DEF_SRC_DIR}/bcmfw

# ubi
declare -r G_UBI_FILE_NAME=rootfs.ubi.img

# REVO web dispatch
declare -r G_REVO_WEB_DISPATCH_GIT=https://github.com/revolution-robotics/roadrunner-web-dispatch.git
declare -r G_REVO_WEB_DISPATCH_BRANCH=golang
declare -r G_REVO_WEB_DISPATCH_REV=6aa8f314b80f515309a18840dc2f8c5591c8e9c8
declare -r G_REVO_WEB_DISPATCH_SRC_DIR=${DEF_SRC_DIR}/web_dispatch

# Smallstep CLI
declare -r G_SMALLSTEP_CLI_GIT=https://github.com/smallstep/cli.git
declare -r G_SMALLSTEP_CLI_BRANCH=master
declare -r G_SMALLSTEP_CLI_REV=HEAD
declare -r G_SMALLSTEP_CLI_SRC_DIR=${DEF_SRC_DIR}/smallstep-cli

# Smallstep CERTIFICATES
declare -r STEP_GROUP=999
declare -r STEP_USER=999
declare -r G_SMALLSTEP_CERTIFICATES_GIT=https://github.com/smallstep/certificates.git
declare -r G_SMALLSTEP_CERTIFICATES_BRANCH=master
declare -r G_SMALLSTEP_CERTIFICATES_REV=HEAD
declare -r G_SMALLSTEP_CERTIFICATES_SRC_DIR=${DEF_SRC_DIR}/smallstep-certificates

# Node version and user
declare -r NODE_BASE=20.
declare -r NODE_USER=revo
declare -r NODE_GROUP=revo

# Smallstep certificate authority bootstrap parameters
: ${CA_URL:=''}
: ${CA_FINGERPRINT:=''}

echo "I: CA_URL: $CA_URL"
