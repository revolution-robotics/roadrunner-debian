#!/bin/bash
readonly ARCH_CPU="32BIT"

# U-Boot
readonly G_UBOOT_SRC_DIR="${DEF_SRC_DIR}/uboot"
readonly G_UBOOT_GIT="https://github.com/revolution-robotics/roadrunner-uboot-imx.git"
readonly G_UBOOT_BRANCH="imx_v2018.03_4.14.78_1.0.0_ga_var01_rr01"
readonly G_UBOOT_REV="1c2ba200b8d3db23523edae213f82efb20cab187"
readonly G_UBOOT_DEF_CONFIG_MMC='mx7d_roadrunner_defconfig'
readonly G_UBOOT_DEF_CONFIG_NAND='mx7d_roadrunner_nand_defconfig'
readonly G_UBOOT_NAME_FOR_EMMC='u-boot.img.mmc'
readonly G_SPL_NAME_FOR_EMMC='SPL.mmc'
readonly G_UBOOT_NAME_FOR_NAND='u-boot.img.nand'
readonly G_SPL_NAME_FOR_NAND='SPL.nand'

# Linux kernel
readonly G_LINUX_KERNEL_SRC_DIR="${DEF_SRC_DIR}/kernel"
readonly G_LINUX_KERNEL_GIT="https://github.com/revolution-robotics/roadrunner-linux-imx.git"
readonly G_LINUX_KERNEL_BRANCH="imx_4.14.78_1.0.0_ga_var01_rr01"
readonly G_LINUX_KERNEL_REV="825a224cd86c38e048b1d802682e799b35c74900"
readonly G_LINUX_KERNEL_DEF_CONFIG='imx_v7_roadrunner_defconfig'
G_LINUX_DTB="imx7d-roadrunner-emmc.dtb"
        # imx7d-roadrunner-nand.dtb"
        # imx7d-var-som-nand.dtb
        # imx7d-var-som-emmc-m4.dtb
        # imx7d-var-som-nand-m4.dtb"

BUILD_IMAGE_TYPE="zImage"
KERNEL_BOOT_IMAGE_SRC="arch/arm/boot/"
KERNEL_DTB_IMAGE_PATH="arch/arm/boot/dts/"

# SDMA Firmware
readonly G_IMX_SDMA_FW_SRC_DIR="${DEF_SRC_DIR}/linux-firmware"
readonly G_IMX_SDMA_FW_GIT="git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
readonly G_IMX_SDMA_FW_GIT_BRANCH="master"
readonly G_IMX_SDMA_FW_GIT_REV="710963fe53ee3f227556d36839df3858daf6e232"

# Broadcom BT/WIFI firmware
readonly G_BCM_FW_SRC_DIR="${DEF_SRC_DIR}/bcmfw"
readonly G_BCM_FW_GIT="https://github.com/varigit/bcm_4343w_fw.git"
readonly G_BCM_FW_GIT_BRANCH="6.0.0.121"
readonly G_BCM_FW_GIT_REV="7bce9b69b51ffd967176c1597feed79305927370"

# ubi
readonly G_UBI_FILE_NAME='rootfs.ubi.img'
