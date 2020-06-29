#!/usr/bin/env bash
# It is designed to build Debian Linux for Variscite iMX modules
# prepare host OS system:
#  sudo apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx
#  sudo apt-get install lvm2 dosfstools gpart binutils git lib32ncurses5-dev python-m2crypto
#  sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev
#  sudo apt-get install autoconf libtool libglib2.0-dev libarchive-dev
#  sudo apt-get install python-git xterm sed cvs subversion coreutils texi2html
#  sudo apt-get install docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils libgl1-mesa-dev
#  sudo apt-get install libglu1-mesa-dev mercurial automake groff curl lzop asciidoc u-boot-tools mtd-utils
#
umask 022

# -e  Exit immediately if a command exits with a non-zero status.
set -e

declare -r SCRIPT_NAME=${0##*/}

: ${MACHINE:='revo-roadrunner-mx7'}

#### Exports Variables ####
#### global variables ####
declare -r ABSOLUTE_FILENAME=$(readlink -e "$0")
declare -r ABSOLUTE_DIRECTORY=$(dirname "$ABSOLUTE_FILENAME")
declare -r SCRIPT_POINT=$ABSOLUTE_DIRECTORY
declare -r SCRIPT_START_DATE=$(date +%Y%m%d)
declare -r LOOP_MAJOR=7
declare -r COMPRESSION_SUFFIX=gz
declare -r GZIP=gzip
declare -r ZCAT=zcat

# default mirror
declare -r DEF_DEBIAN_MIRROR=https://deb.debian.org/debian/
declare -r DEB_RELEASE=buster
declare -r DEF_ROOTFS_TARBALL_NAME=rootfs.tar.gz

# base paths
declare -r DEF_BUILDENV=$ABSOLUTE_DIRECTORY
declare -r DEF_SRC_DIR=${DEF_BUILDENV}/src
declare -r G_ROOTFS_DIR=${DEF_BUILDENV}/rootfs
declare -r G_TMP_DIR=${DEF_BUILDENV}/tmp
declare -r G_TOOLS_PATH=${DEF_BUILDENV}/toolchain
if [[ ."$MACHINE" =~ \.(revo-roadrunner-mx7) ]]; then
    declare -r G_VENDOR_PATH=${DEF_BUILDENV}/revo
else
    declare -r G_VENDOR_PATH=${DEF_BUILDENV}/variscite
fi

#64 bit CROSS_COMPILER config and paths
declare -r G_CROSS_COMPILER_64BIT_NAME=gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
declare -r G_CROSS_COMPILER_ARCHIVE_64BIT=${G_CROSS_COMPILER_64BIT_NAME}.tar.xz
declare -r G_EXT_CROSS_64BIT_COMPILER_LINK=http://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/${G_CROSS_COMPILER_ARCHIVE_64BIT}
declare -r G_CROSS_COMPILER_64BIT_PREFIX=aarch64-linux-gnu-

#32 bit CROSS_COMPILER config and paths
declare -r G_CROSS_COMPILER_32BIT_NAME=gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf
declare -r G_CROSS_COMPILER_ARCHIVE_32BIT=${G_CROSS_COMPILER_32BIT_NAME}.tar.xz
declare -r G_EXT_CROSS_32BIT_COMPILER_LINK=http://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/arm-linux-gnueabihf/${G_CROSS_COMPILER_ARCHIVE_32BIT}
declare -r G_CROSS_COMPILER_32BIT_PREFIX=arm-linux-gnueabihf-

declare -r G_CROSS_COMPILER_JOPTION="-j 6"

#### user rootfs packages ####
declare -r G_USER_PACKAGES="bash-completion binutils cockpit cockpit-networkmanager curl dnsutils ed git openvpn network-manager-openvpn pciutils python3-cryptography python3-dateutil python3-lxml python3-pip python3-psutil python3-websockets python3-zmq sudo traceroute"

export LC_ALL=C

#### Input params ####
declare PARAM_DEB_LOCAL_MIRROR=$DEF_DEBIAN_MIRROR
declare PARAM_OUTPUT_DIR=${DEF_BUILDENV}/output
declare PARAM_DEBUG=0
declare PARAM_CMD=''
declare PARAM_BLOCK_DEVICE='na'
declare PARAM_DISK_IMAGE='na'

### usage ###
usage ()
{
    cat <<EOF
Make Debian $DEB_RELEASE image and create a bootabled SD card

Usage:
 MACHINE=<imx8m-var-dart|imx8mm-var-dart|imx8qxp-var-som|imx8qm-var-som|imx6ul-var-dart|var-som-mx7|revo-roadrunner-mx7> ./$SCRIPT_NAME OPTIONS
Options:
  -h|--help        -- print this help
  -c|--cmd <command>
     Supported commands:
       deploy      -- prepare environment for all commands
       all         -- build or rebuild kernel/bootloader/rootfs
       bootloader  -- build or rebuild U-Boot
       kernel      -- build or rebuild the Linux kernel
       modules     -- build or rebuild the Linux kernel modules & headers and install them in the rootfs dir
       rootfs      -- build or rebuild the Debian root filesystem and create rootfs.tar.gz
                       (including: make & install Debian packages, firmware and kernel modules & headers)
       rubi        -- generate or regenerate rootfs.ubi.img image from rootfs folder
       rtar        -- generate or regenerate rootfs.tar.gz image from the rootfs folder
       clean       -- clean all build artifacts (without deleting sources code or resulted images)
       sdcard      -- create a bootable SD card
       diskimage   -- create a bootable image file
       flashimage  -- flash a disk image to SD card
  -o|--output dir  -- destination directory for build images (default: "$PARAM_OUTPUT_DIR")
  -d|--dev         -- removable block device to write to (e.g., -d /dev/sde)
  -i|--image diskimage
                   -- disk image to flash (image directory -- cf. option -o)
  --debug          -- enable debug mode for this script

Examples:
  deploy and build:                 ./${SCRIPT_NAME} --cmd deploy && sudo ./${SCRIPT_NAME} --cmd all
  make the Linux kernel only:       sudo ./${SCRIPT_NAME} --cmd kernel
  make rootfs only:                 sudo ./${SCRIPT_NAME} --cmd rootfs
  create bootable SD card:          sudo ./${SCRIPT_NAME} --cmd sdcard [--dev /dev/sdX]
  create boot image:                sudo ./${SCRIPT_NAME} --cmd diskimage
  flash image to SD card:           sudo ./${SCRIPT_NAME} --cmd flashimage
EOF
}

if test ! -e "${G_VENDOR_PATH}/${MACHINE}/${MACHINE}.sh"; then
    echo "Illegal MACHINE: $MACHINE"
    echo
    usage
    exit 1
fi

source "${G_VENDOR_PATH}/${MACHINE}/${MACHINE}.sh"

# Setup cross compiler path, name, kernel dtb path, kernel image type, helper scripts
if test ."$ARCH_CPU" = .'64BIT'; then
    declare G_CROSS_COMPILER_NAME=$G_CROSS_COMPILER_64BIT_NAME
    declare G_EXT_CROSS_COMPILER_LINK=$G_EXT_CROSS_64BIT_COMPILER_LINK
    declare G_CROSS_COMPILER_ARCHIVE=$G_CROSS_COMPILER_ARCHIVE_64BIT
    declare G_CROSS_COMPILER_PREFIX=$G_CROSS_COMPILER_64BIT_PREFIX
    declare ARCH_ARGS=arm64
    declare BUILD_IMAGE_TYPE=Image.gz
    declare KERNEL_BOOT_IMAGE_SRC=arch/arm64/boot/
    declare KERNEL_DTB_IMAGE_PATH=arch/arm64/boot/dts/freescale/
    # Include weston backend rootfs helper
    source "${G_VENDOR_PATH}/weston_rootfs.sh"
elif test ."$ARCH_CPU" = .'32BIT'; then
    declare G_CROSS_COMPILER_NAME=$G_CROSS_COMPILER_32BIT_NAME
    declare G_EXT_CROSS_COMPILER_LINK=$G_EXT_CROSS_32BIT_COMPILER_LINK
    declare G_CROSS_COMPILER_ARCHIVE=$G_CROSS_COMPILER_ARCHIVE_32BIT
    declare G_CROSS_COMPILER_PREFIX=$G_CROSS_COMPILER_32BIT_PREFIX
    declare ARCH_ARGS=arm
    # Include x11 backend rootfs helper
    source "${G_VENDOR_PATH}/x11_rootfs.sh"
else
    echo " Error unknown CPU type"
    exit 1
fi

declare G_CROSS_COMPILER_PATH=${G_TOOLS_PATH}/${G_CROSS_COMPILER_NAME}/bin

## parse input arguments ##
declare -r SHORTOPTS='c:d:i:o:h'
declare -r LONGOPTS='cmd:,dev:,image:,output:,help,debug'

declare ARGS=$(
    getopt -s bash --options ${SHORTOPTS}  \
           --longoptions ${LONGOPTS} --name ${SCRIPT_NAME} -- "$@"
        )

eval set -- "$ARGS"

# Require a command-line argument
if (( $# == 0 )); then
    usage
    exit 1
fi

while true; do
    case $1 in
        -c|--cmd) # script command
            shift
            PARAM_CMD=$1
            ;;
        -d|--dev) # SD card block device
            shift
            if test -e "$1"; then
                PARAM_BLOCK_DEVICE=$1
            fi
            ;;
        -i|--image) # Disk image
            shift
            if test -e "$1"; then
                PARAM_DISK_IMAGE=$1
            fi
            ;;
        -o|--output) # select output dir
            shift
            PARAM_OUTPUT_DIR=$1
            ;;
        --debug) # enable debug
            PARAM_DEBUG=1
            ;;
        -h|--help) # get help
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            shift
            break
            ;;
    esac
    shift
done

# enable trace option in debug mode
if test ."$PARAM_DEBUG" = .'1'; then
    echo "Debug mode enabled!"
    set -x
fi

if test ."$PARAM_CMD" != .'flashimage'; then
    echo "=============== Build summary ==============="
    echo "Building Debian $DEB_RELEASE for $MACHINE"
    echo "U-Boot config:      $G_UBOOT_DEF_CONFIG_MMC"
    echo "Kernel config:      $G_LINUX_KERNEL_DEF_CONFIG"
    echo "Default kernel dtb: $DEFAULT_BOOT_DTB"
    echo "kernel dtbs:        $G_LINUX_DTB"
    echo "============================================="
    echo
fi

## declarate dynamic variables ##
declare -r G_ROOTFS_TARBALL_PATH="${PARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBALL_NAME}"

###### local functions ######

### printing functions ###

# print error message
# $1 - printing string
pr_error ()
{
    echo "E: $1"
}

# print warning message
# $1 - printing string
pr_warning ()
{
    echo "W: $1"
}

# print info message
# $1 - printing string
pr_info ()
{
    echo "I: $1"
}

# print debug message
# $1 - printing string
pr_debug ()
{
    echo "D: $1"
}

### work functions ###

# get sources from git repository
# $1 - git repository
# $2 - branch name
# $3 - output dir
# $4 - commit id
get_git_src ()
{
    # clone src code
    git clone "$1" -b "$2" "$3"
    (cd "$3" && git reset --hard "$4")
}

# get remote file
# $1 - remote file
# $2 - local directory
get_remote_file ()
{
    uri=$1
    destdir=$2

    # download remote file
    # wget -c "$1" -O "$2"
    (cd "$destdir" && curl -C - -LO "$uri")
}

make_prepare ()
{
    # create src dir
    mkdir -p "$DEF_SRC_DIR"

    # create toolchain dir
    mkdir -p "$G_TOOLS_PATH"

    # create rootfs dir
    mkdir -p "$G_ROOTFS_DIR"

    # create out dir
    mkdir -p "$PARAM_OUTPUT_DIR"

    # create tmp dir
    mkdir -p "$G_TMP_DIR"
}


# make tarball from footfs
# $1 -- packet folder
# $2 -- output tarball file (full name)
make_tarball ()
{
    (
        cd "$1"
        chown root:root .
        pr_info "make tarball from folder $1"
        pr_info "Remove old tarball $2"
        rm -f "$2"

        pr_info "Create $2"

        tar -zcf "$2" --exclude '*~' . || {
            rm -f "$2"
            exit 1
        }
    )
}

# make Linux kernel image & dtbs
# $1 -- cross compiler prefix
# $2 -- Linux defconfig file
# $3 -- Linux dtb files
# $4 -- Linux dirname
# $5 -- out path
make_kernel ()
{
    pr_info "make kernel .config"
    make ARCH="$ARCH_ARGS" CROSS_COMPILE="$1" $G_CROSS_COMPILER_JOPTION -C "$4" "$2"

    pr_info "make kernel"
    if test ! -z "$UIMAGE_LOADADDR"; then
        IMAGE_EXTRA_ARGS=LOADADDR=$UIMAGE_LOADADDR
    fi
    make CROSS_COMPILE="$1" ARCH="$ARCH_ARGS" $G_CROSS_COMPILER_JOPTION \
         $IMAGE_EXTRA_ARGS -C "$4" "$BUILD_IMAGE_TYPE"

    pr_info "make $3"
    make CROSS_COMPILE="$1" ARCH="$ARCH_ARGS" $G_CROSS_COMPILER_JOPTION -C "$4" "$3"

    pr_info "Copy kernel and dtb files to output dir: $5"
    cp "${4}/${KERNEL_BOOT_IMAGE_SRC}/${BUILD_IMAGE_TYPE}" "$5"
    cp "${4}/${KERNEL_DTB_IMAGE_PATH}"*.dtb "$5"
}

# clean kernel
# $1 -- Linux dir path
clean_kernel ()
{
    pr_info "Clean the Linux kernel"

    make ARCH="$ARCH_ARGS" -C "$1" mrproper
}

# make Linux kernel modules
# $1 -- cross compiler prefix
# $2 -- Linux defconfig file
# $3 -- Linux dirname
# $4 -- out modules path
make_kernel_modules ()
{
    pr_info "make kernel defconfig"
    make ARCH="$ARCH_ARGS" CROSS_COMPILE="$1" $G_CROSS_COMPILER_JOPTION -C "$3" "$2"

    pr_info "Compiling kernel modules"
    make ARCH="$ARCH_ARGS" CROSS_COMPILE="$1" $G_CROSS_COMPILER_JOPTION -C "$3" modules
}

# install the Linux kernel modules
# $1 -- cross compiler prefix
# $2 -- Linux defconfig file
# $3 -- Linux dirname
# $4 -- out modules path
install_kernel_modules ()
{
    pr_info "Installing kernel headers to $4"
    make ARCH="$ARCH_ARGS" CROSS_COMPILE="$1" $G_CROSS_COMPILER_JOPTION -C "$3" \
         INSTALL_HDR_PATH="$4/usr/local" headers_install

    pr_info "Installing kernel modules to $4"
    make ARCH="$ARCH_ARGS" CROSS_COMPILE="$1" $G_CROSS_COMPILER_JOPTION -C "$3" \
         INSTALL_MOD_PATH="$4" modules_install
}

# make U-Boot
# $1 U-Boot path
# $2 Output dir
make_uboot ()
{
    pr_info "Make U-Boot: $G_UBOOT_DEF_CONFIG_MMC"

    # clean work directory
    make ARCH="$ARCH_ARGS" -C "$1" \
         CROSS_COMPILE="${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
         $G_CROSS_COMPILER_JOPTION mrproper

    # make U-Boot mmc defconfig
    make ARCH="$ARCH_ARGS" -C "$1" \
         CROSS_COMPILE="${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
         $G_CROSS_COMPILER_JOPTION "$G_UBOOT_DEF_CONFIG_MMC"

    # make U-Boot
    make -C "$1" \
         CROSS_COMPILE="${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
         $G_CROSS_COMPILER_JOPTION

    # make fw_printenv
    make envtools -C "$1" \
         CROSS_COMPILE="${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
         $G_CROSS_COMPILER_JOPTION

    cp "${1}/tools/env/fw_printenv" "$2"

    if test ."$MACHINE" = .'imx8qxp-var-som'; then
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/scfw_tcm.bin \
           src/imx-mkimage/iMX8QX/
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/bl31-imx8qx.bin \
           src/imx-mkimage/iMX8QX/bl31.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/mx8qx-ahab-container.img \
           src/imx-mkimage/iMX8QX/
        cp ${1}/u-boot.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8QX/
        cp ${1}/spl/u-boot-spl.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8QX/
        cd ${DEF_SRC_DIR}/imx-mkimage
        make SOC=iMX8QX flash_spl
        cp ${DEF_SRC_DIR}/imx-mkimage/iMX8QX/flash.bin \
           ${DEF_SRC_DIR}/imx-mkimage/${G_UBOOT_NAME_FOR_EMMC}
        cp ${G_UBOOT_NAME_FOR_EMMC} ${2}/${G_UBOOT_NAME_FOR_EMMC}
    elif test ."$MACHINE" = .'imx8m-var-dart'; then
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/bl31-imx8mq.bin \
           src/imx-mkimage/iMX8M/bl31.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/signed_hdmi_imx8m.bin \
           src/imx-mkimage/iMX8M/signed_hdmi_imx8m.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_1d_imem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_1d_imem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_1d_dmem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_1d_dmem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_2d_imem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_2d_imem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_2d_dmem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_2d_dmem.bin
        cp ${1}/u-boot.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/u-boot-nodtb.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/spl/u-boot-spl.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/arch/arm/dts/${UBOOT_DTB} ${DEF_SRC_DIR}/imx-mkimage/iMX8M/fsl-imx8mq-evk.dtb
        cp ${1}/tools/mkimage ${DEF_SRC_DIR}/imx-mkimage/iMX8M/mkimage_uboot
        cd ${DEF_SRC_DIR}/imx-mkimage
        make SOC=iMX8M flash_evk
        cp ${DEF_SRC_DIR}/imx-mkimage/iMX8M/flash.bin \
           ${DEF_SRC_DIR}/imx-mkimage/${G_UBOOT_NAME_FOR_EMMC}
        cp ${G_UBOOT_NAME_FOR_EMMC} ${2}/${G_UBOOT_NAME_FOR_EMMC}
    elif test ."$MACHINE" = .'imx8mm-var-dart'; then
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/bl31-imx8mm.bin \
           src/imx-mkimage/iMX8M/bl31.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_1d_imem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_1d_imem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_1d_dmem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_1d_dmem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_2d_imem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_2d_imem.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/lpddr4_pmu_train_2d_dmem.bin \
           src/imx-mkimage/iMX8M/lpddr4_pmu_train_2d_dmem.bin
        cp ${1}/u-boot.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/u-boot-nodtb.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/spl/u-boot-spl.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8M/
        cp ${1}/arch/arm/dts/${UBOOT_DTB} ${DEF_SRC_DIR}/imx-mkimage/iMX8M/fsl-imx8mm-evk.dtb
        cp ${1}/tools/mkimage ${DEF_SRC_DIR}/imx-mkimage/iMX8M/mkimage_uboot
        cd ${DEF_SRC_DIR}/imx-mkimage
        make SOC=iMX8MM flash_evk
        cp ${DEF_SRC_DIR}/imx-mkimage/iMX8M/flash.bin \
           ${DEF_SRC_DIR}/imx-mkimage/${G_UBOOT_NAME_FOR_EMMC}
        cp ${G_UBOOT_NAME_FOR_EMMC} ${2}/${G_UBOOT_NAME_FOR_EMMC}
    elif test ."$MACHINE" = .'imx8qm-var-som'; then
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/scfw_tcm.bin \
           src/imx-mkimage/iMX8QM/
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/bl31-imx8qm.bin \
           src/imx-mkimage/iMX8QM/bl31.bin
        cp ${G_VENDOR_PATH}/${MACHINE}/imx-boot-tools/mx8qm-ahab-container.img \
           src/imx-mkimage/iMX8QM/
        cp ${1}/u-boot.bin ${DEF_SRC_DIR}/imx-mkimage/iMX8QM/
        cd ${DEF_SRC_DIR}/imx-mkimage
        make SOC=iMX8QM flash
        cp ${DEF_SRC_DIR}/imx-mkimage/iMX8QM/flash.bin \
           ${DEF_SRC_DIR}/imx-mkimage/${G_UBOOT_NAME_FOR_EMMC}
        cp ${G_UBOOT_NAME_FOR_EMMC} ${2}/${G_UBOOT_NAME_FOR_EMMC}
        cp ${1}/tools/env/fw_printenv ${2}
    elif test ."$MACHINE" = .'imx6ul-var-dart' ||
             test ."$MACHINE" = .'var-som-mx7' ||
             test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        mv ${2}/fw_printenv ${2}/fw_printenv-mmc
        #copy MMC SPL, u-boot, SPL binaries
        cp ${1}/SPL ${2}/${G_SPL_NAME_FOR_EMMC}
        cp ${1}/u-boot.img  ${2}/${G_UBOOT_NAME_FOR_EMMC}

        # # make NAND U-Boot
        # pr_info "Make SPL & u-boot: ${G_UBOOT_DEF_CONFIG_NAND}"
        # # clean work directory
        # make ARCH=arm -C $1 \
        #      CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} \
        #      ${G_CROSS_COMPILER_JOPTION} mrproper

        # # make uboot config for nand
        # make ARCH=arm -C $1 \
        #      CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} \
        #      ${G_CROSS_COMPILER_JOPTION} ${G_UBOOT_DEF_CONFIG_NAND}

        # # make uboot
        # make ARCH=arm -C $1 \
        #      CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} \
        #      ${G_CROSS_COMPILER_JOPTION}

        # # make fw_printenv
        # make envtools -C $1 \
        #      CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} \
        #      ${G_CROSS_COMPILER_JOPTION}

        # # copy NAND SPL, u-boot binaries
        # cp ${1}/SPL ${2}/${G_SPL_NAME_FOR_NAND}
        # cp ${1}/u-boot.img ${2}/${G_UBOOT_NAME_FOR_NAND}
        # cp ${1}/tools/env/fw_printenv ${2}/fw_printenv-nand
    fi
}

# make *.ubi image from rootfs
# params:
#  $1 -- path to rootfs dir
#  $2 -- tmp dir
#  $3 -- output dir
#  $4 -- ubi file name
make_ubi ()
{
    local _rootfs=$1
    local _tmp=$2
    local _output=$3
    local _ubi_file_name=$4

    local UBI_CFG="${_tmp}/ubi.cfg"
    local UBIFS_IMG="${_tmp}/rootfs.ubifs"
    local UBI_IMG="${_output}/${_ubi_file_name}"
    local UBIFS_ROOTFS_DIR="${DEF_BUILDENV}/rootfs_ubi_tmp"

    rm -rf "$UBIFS_ROOTFS_DIR"
    cp -a ${_rootfs} "$UBIFS_ROOTFS_DIR"
    prepare_x11_ubifs_rootfs "$UBIFS_ROOTFS_DIR"
    # gnerate ubifs file
    pr_info "Generate ubi config file: ${UBI_CFG}"
    cat > "$UBI_CFG" << EOF
[ubifs]
mode=ubi
image=$UBIFS_IMG
vol_id=0
vol_type=dynamic
vol_name=rootfs
vol_flags=autoresize
EOF
    # delete previus images
    rm -f "$UBI_IMG"
    rm -f "$UBIFS_IMG"

    pr_info "Creating $UBIFS_IMG image"
    mkfs.ubifs -x zlib -m 2048  -e 124KiB -c 3965 -r "$UBIFS_ROOTFS_DIR" $UBIFS_IMG

    pr_info "Creating $UBI_IMG image"
    ubinize -o "$UBI_IMG" -m 2048 -p 128KiB -s 2048 -O 2048 "$UBI_CFG"

    # delete unused file
    rm -f "$UBIFS_IMG"
    rm -f "$UBI_CFG"
    rm -rf "$UBIFS_ROOTFS_DIR"

    return 0
}

# clean U-Boot
# $1 -- U-Boot dir path
clean_uboot ()
{
    pr_info "Clean U-Boot"
    make ARCH="$ARCH_ARGS" -C "$1" mrproper
}

is_removable_device ()
{
    local device=${1#/dev/}

    local removable
    local drive
    local gdbus_is_removable

    # Check that parameter is a valid block device
    if test ! -b "/dev/$device"; then
        pr_error "/dev/$device: Not a valid block device"
        return 1
    fi

    # Check that /sys/block/$dev exists
    if test ! -d "/sys/block/$device"; then
        pr_error "/sys/block/$device: No such directory"
        return 1
    fi

    # Loop device is removable for our purposes
    if is_loop_device "/dev/$device"; then
        return 0
    fi

    # Get device parameters
    removable=$(cat "/sys/block/${device}/removable")

    # Non removable SD card readers require additional check
    if test ."$removable" != .'1'; then
        local drive=$(
            udisksctl info -b "/dev/$device" |
                grep "Drive:"|
                cut -d"'" -f 2
              )
        gdbus_is_removable=$(
            gdbus call --system --dest org.freedesktop.UDisks2 \
                  --object-path ${drive} \
                  --method org.freedesktop.DBus.Properties.Get org.freedesktop.UDisks2.Drive MediaRemovable 2>/dev/null
                          )
        if [[ ."$gdbus_is_removable" =~ ^\..*true ]]; then
            removable=1
        fi
    fi

    # Check that device is either removable or loop
    if test ."$removable" != .'1'; then
        pr_error "/dev/$device: Not a removable device"
        return 1
    fi
}

is_loop_device ()
{
    local device=$1

    (( $(stat -c '%t' "$device") == LOOP_MAJOR ))
}

get_range ()
{
    size=$1

    if (( size > 10 )); then
        echo "1-$size"
    else
        echo $(seq $size) | tr ' ' '|'
    fi
}

select_from_list ()
{
    local -n choices=$1
    local prompt=$2

    local choice
    local count

    count=${#choices[*]}
    case "$count" in
        0)
            pr_error "Nothing to choose"
            return 1
            ;;
        1)
            choice=${choices[0]}
            ;;
        *)
            echo "$prompt" >&2
            PS3="Selection [$(get_range $count)]? "
            select choice in "${choices[@]}"; do
                case "$choice" in
                    '')
                        echo "$REPLY: Invalid choice - Please try again:" >&2
                        ;;
                    *)
                        break
                        ;;
                esac
            done
    esac
    echo "$choice"
}

get_disk_images ()
{
    local -a archives
    local archive
    local kind

    mapfile -t archives < <(ls "${PARAM_OUTPUT_DIR}/"*.$COMPRESSION_SUFFIX)
    for archive in "${archives[@]}"; do
        kind=$($ZCAT "$archive" | file - | awk '{ print $2 }')
        case "$kind" in
            DOS/MBR)
                echo "$archive"
                ;;
        esac
    done
}

get_removable_devices ()
{
    local -a devices
    local device
    local vendor
    local model

    mapfile -t devices < <(
        grep -lv ^0$ '/sys/block/'*'/removable' |
            sed -e 's;removable$;device/uevent;' |
            xargs grep -l '^DRIVER=sd$' |
            sed -e 's;device/uevent;size;' |
            xargs grep -lv '^0' |
            cut -d/ -f4
    )

    for device in "${devices[@]}"; do
        vendor=$(sed -e 's/^  *//' -e 's/  *$//' "/sys/block/${device}/device/vendor")
        model=$(sed -e 's/^  *//' -e 's/  *$//' "/sys/block/${device}/device/model")
        echo "/dev/$device ($vendor $model)"
    done
}

select_disk_image ()
{
    declare -a disk_images

    mapfile -t disk_images < <(get_disk_images)
    select_from_list disk_images 'Please choose an image to flash from:'
}

select_removable_device ()
{
    declare -a removable_devices

    mapfile -t removable_devices < <(get_removable_devices)
    select_from_list removable_devices 'Please choose a device to flash to:'
}

# make imx sdma firmware
# $1 -- SDMA firmware directory
# $2 -- rootfs output dir
make_imx_sdma_fw ()
{
    pr_info "Install imx sdma firmware"
    install -d ${2}/lib/firmware/imx/sdma
    if test ."$MACHINE" = .'imx6ul-var-dart'; then
        install -m 0644 ${1}/sdma-imx6q.bin \
                ${2}/lib/firmware/imx/sdma
    elif  test ."$MACHINE" = .'var-som-mx7' ||
              test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        install -m 0644 ${1}/sdma-imx7d.bin \
            ${2}/lib/firmware/imx/sdma
    fi
    install -m 0644 ${1}/LICENSE.sdma_firmware ${2}/lib/firmware/
}

# make firmware for wl bcm module
# $1 -- bcm git directory
# $2 -- rootfs output dir
make_bcm_fw ()
{
    pr_info "Make and install bcm configs and firmware"

    install -d ${2}/lib/firmware/bcm
    install -d ${2}/lib/firmware/brcm
    install -m 0644 ${1}/brcm/* ${2}/lib/firmware/brcm/
    install -m 0644 ${1}/*.hcd ${2}/lib/firmware/bcm/
    install -m 0644 ${1}/LICENSE ${2}/lib/firmware/bcm/
    install -m 0644 ${1}/LICENSE ${2}/lib/firmware/brcm/
}

################ commands ################

cmd_make_deploy ()
{
    # get linaro toolchain
    if (( $(ls "$G_CROSS_COMPILER_PATH" 2>/dev/null | wc -l) == 0 )); then
        pr_info "Get and unpack cross compiler"
        get_remote_file "$G_EXT_CROSS_COMPILER_LINK" "$DEF_SRC_DIR"
        tar -xJf "${DEF_SRC_DIR}/${G_CROSS_COMPILER_ARCHIVE}" \
            -C "$G_TOOLS_PATH"/
    fi

    # get U-Boot repository
    if (( $(ls "$G_UBOOT_SRC_DIR" 2>/dev/null | wc -l) == 0 )); then
        pr_info "Get U-Boot repository"
        get_git_src "$G_UBOOT_GIT" "$G_UBOOT_BRANCH" \
                    "$G_UBOOT_SRC_DIR" "$G_UBOOT_REV"
    fi

    # get kernel repository
    if (( $(ls "$G_LINUX_KERNEL_SRC_DIR" 2>/dev/null | wc -l) == 0 )); then
        pr_info "Get kernel repository"
        get_git_src "$G_LINUX_KERNEL_GIT" "$G_LINUX_KERNEL_BRANCH" \
                    "$G_LINUX_KERNEL_SRC_DIR" "$G_LINUX_KERNEL_REV"
    fi
    if test ! -z "$G_BCM_FW_GIT"; then
        # get bcm firmware repository
        if (( $(ls "$G_BCM_FW_SRC_DIR"  2>/dev/null | wc -l) == 0 )); then
            pr_info "Get bcmhd firmware repository"
            get_git_src "$G_BCM_FW_GIT" "$G_BCM_FW_GIT_BRANCH" \
                        "$G_BCM_FW_SRC_DIR" "$G_BCM_FW_GIT_REV"
        fi
    fi
    if test ! -z "$G_IMXBOOT_GIT"; then
        # get IMXBoot Source repository
        if (( $(ls "$G_IMXBOOT_SRC_DIR"  2>/dev/null | wc -l) == 0 )); then
            pr_info "Get imx-boot"
            get_git_src "$G_IMXBOOT_GIT" \
                        "$G_IMXBOOT_BRACH" "$G_IMXBOOT_SRC_DIR" "$G_IMXBOOT_REV"
        fi
    fi


}

cmd_make_rootfs ()
{
    make_prepare

    if test ."$MACHINE" = .'imx6ul-var-dart' ||
           test ."$MACHINE" = .'var-som-mx7' ||
           test ."$MACHINE" = .'revo-roadrunner-mx7'; then

        (
            cd "$G_ROOTFS_DIR"
            # make debian x11 backend rootfs
            make_debian_x11_rootfs "$G_ROOTFS_DIR"

            trap - 0 1 2 15 RETURN

            # make imx sdma firmware
            make_imx_sdma_fw "$G_IMX_SDMA_FW_SRC_DIR" "$G_ROOTFS_DIR"
        )
    else
        (
            cd "$G_ROOTFS_DIR"
            make_debian_weston_rootfs "$G_ROOTFS_DIR"
        )
    fi

    # make bcm firmwares
    if test ! -z "$G_BCM_FW_GIT"; then
        make_bcm_fw "$G_BCM_FW_SRC_DIR" "$G_ROOTFS_DIR"
    fi

    # pack rootfs
    make_tarball "$G_ROOTFS_DIR" "$G_ROOTFS_TARBALL_PATH"

    # if test ."$MACHINE" = .'imx6ul-var-dart' ||
    #        test ."$MACHINE" = .'var-som-mx7' ||
    #        test ."$MACHINE" = .'revo-roadrunner-mx7'; then
    #     pack to ubi
    #     make_ubi "$G_ROOTFS_DIR" "$G_TMP_DIR" "$PARAM_OUTPUT_DIR" \
    #              "$G_UBI_FILE_NAME"
    # fi
}

cmd_make_uboot ()
{
    make_uboot "$G_UBOOT_SRC_DIR" "$PARAM_OUTPUT_DIR"
}

cmd_make_kernel ()
{
    make_kernel "${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
                "$G_LINUX_KERNEL_DEF_CONFIG" "$G_LINUX_DTB" \
                "$G_LINUX_KERNEL_SRC_DIR" "$PARAM_OUTPUT_DIR"
}

cmd_make_kmodules ()
{
    rm -rf "${G_ROOTFS_DIR}/lib/modules/"*

    make_kernel_modules "${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
                        "$G_LINUX_KERNEL_DEF_CONFIG" "$G_LINUX_KERNEL_SRC_DIR" \
                        "$G_ROOTFS_DIR"

    install_kernel_modules "${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
                           "$G_LINUX_KERNEL_DEF_CONFIG" \
                           "$G_LINUX_KERNEL_SRC_DIR" "$G_ROOTFS_DIR"
}

cmd_make_rfs_ubi ()
{
    make_ubi "$G_ROOTFS_DIR" "$G_TMP_DIR" "$PARAM_OUTPUT_DIR" \
             "$G_UBI_FILE_NAME"
}

cmd_make_rfs_tar ()
{
    # pack rootfs
    make_tarball "$G_ROOTFS_DIR" "$G_ROOTFS_TARBALL_PATH"
}

cmd_make_sdcard ()
{
    if test ."$MACHINE" = .'imx6ul-var-dart' ||
           test ."$MACHINE" = .'var-som-mx7' ||
           test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        make_x11_image "$PARAM_BLOCK_DEVICE" "$PARAM_OUTPUT_DIR"
    else
        make_weston_sdcard "$PARAM_BLOCK_DEVICE" "$PARAM_OUTPUT_DIR"
    fi
}

cmd_make_diskimage ()
{
    local ISO8601=$(date  +'%Y%m%dT%H%M%SZ')
    local IMAGE_FILE=${G_TMP_DIR}/${MACHINE}-${ISO8601}.img
    local IMAGE_SIZE=$(( 7774208 * 512 )) # 3.7 GiB
    local LOOP_DEVICE

    pr_info "Initialize file-backed loop device"
    mkdir -p $(dirname "$IMAGE_FILE")
    dd if=/dev/zero of="$IMAGE_FILE" bs="$IMAGE_SIZE" seek=1 count=0
    LOOP_DEVICE=$(losetup --nooverlap --find --show "$IMAGE_FILE")

    trap 'losetup -d "$LOOP_DEVICE"; exit' 0 1 2 15

    if test ."$MACHINE" = .'imx6ul-var-dart' ||
           test ."$MACHINE" = .'var-som-mx7' ||
           test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        make_x11_image "$LOOP_DEVICE" "$PARAM_OUTPUT_DIR"
    else
        make_weston_sdcard "$LOOP_DEVICE" "$PARAM_OUTPUT_DIR"
    fi

    losetup -d "$LOOP_DEVICE"

    trap - 0 1 2 15

    pr_info "Compressing image file \"$(basename $IMAGE_FILE)\"..."
    $GZIP "$IMAGE_FILE"
    mv "${IMAGE_FILE}.${COMPRESSION_SUFFIX}" "$PARAM_OUTPUT_DIR"
}

cmd_flash_diskimage ()
{
    local LPARAM_DISK_IMAGE=$PARAM_DISK_IMAGE
    local LPARAM_BLOCK_DEVICE=$PARAM_BLOCK_DEVICE

    local total_size
    local total_size_bytes
    local total_size_gib
    local -i i

    if test ! -f "$LPARAM_DISK_IMAGE"; then
        if test -f "${PARAM_OUTPUT_DIR}/${LPARAM_DISK_IMAGE}"; then
            LPARAM_DISK_IMAGE=${PARAM_OUTPUT_DIR}/${LPARAM_DISK_IMAGE}
        else
            LPARAM_DISK_IMAGE=$(select_disk_image)
        fi
        if test ! -f "$LPARAM_DISK_IMAGE"; then
            pr_error "Image not available"
            exit 1
        fi
    fi

    if ! is_removable_device "$LPARAM_BLOCK_DEVICE" >/dev/null 2>&1; then
        LPARAM_BLOCK_DEVICE=$(select_removable_device | awk '{ print $1 }')
        if test ."$LPARAM_BLOCK_DEVICE" = .''; then
            pr_error "Device not available"
            exit 1
        fi
    fi

    total_size=$(blockdev --getsz "$LPARAM_BLOCK_DEVICE")
    total_size_bytes=$(( total_size * 512 ))
    total_size_gib=$(bc <<< "scale=1; ${total_size_bytes}/(1024*1024*1024)")

    echo '============================================='
    pr_info "Image: ${LPARAM_DISK_IMAGE##*/}"
    pr_info "Device: $LPARAM_BLOCK_DEVICE, $total_size_gib GiB"
    echo '============================================='
    read -p "Press Enter to continue"

    pr_info "Flashing image to device..."

    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt "${LPARAM_BLOCK_DEVICE}${i}")"; then
            umount -f "${LPARAM_BLOCK_DEVICE}${i}"
        fi
    done

    if ! $ZCAT "$LPARAM_DISK_IMAGE" | dd of="$LPARAM_BLOCK_DEVICE" bs=1M; then
        pr_error "Flash did not complete successfully."
        echo "*** Please check media and try again! ***"
    fi
}

cmd_make_bcmfw ()
{
    make_bcm_fw "$G_BCM_FW_SRC_DIR" "$G_ROOTFS_DIR"
}

cmd_make_firmware ()
{
    make_imx_sdma_fw "$G_IMX_SDMA_FW_SRC_DIR" "$G_ROOTFS_DIR"
}

cmd_make_clean ()
{
    # clean kernel, dtb, modules
    clean_kernel "$G_LINUX_KERNEL_SRC_DIR"

    # clean U-Boot
    clean_uboot "$G_UBOOT_SRC_DIR"

    # delete tmp dirs and etc
    pr_info "Delete tmp dir ${G_TMP_DIR}"
    rm -rf "$G_TMP_DIR"

    pr_info "Delete rootfs dir ${G_ROOTFS_DIR}"
    rm -rf "$G_ROOTFS_DIR"
}

################ main function ################

# test for root access support
if [[ "$PARAM_CMD" != "deploy"  && "$EUID" != 0 ]]; then
    pr_error "This command must be run as root (or sudo/su)"
    exit 1
fi

pr_info "Command: \"$PARAM_CMD\" start..."

make_prepare

case $PARAM_CMD in
    deploy)
        cmd_make_deploy
        ;;
    rootfs)
        cmd_make_rootfs
        ;;
    bootloader)
        cmd_make_uboot
        ;;
    kernel)
        cmd_make_kernel
        ;;
    modules)
        cmd_make_kmodules
        ;;
    bcmfw)
        cmd_make_bcmfw
        ;;
    firmware)
        cmd_make_firmware
        ;;
    sdcard)
        cmd_make_sdcard
        ;;
    diskimage)
        cmd_make_diskimage
        ;;
    flashimage)
        cmd_flash_diskimage
        ;;
    rubi)
        cmd_make_rfs_ubi
        ;;
    rtar)
        cmd_make_rfs_tar
        ;;
    all)
        cmd_make_uboot  &&
            cmd_make_kernel &&
            cmd_make_kmodules &&
            cmd_make_rootfs
        ;;
    clean)
        cmd_make_clean
        ;;
    *)
        pr_error "Invalid input command: \"$PARAM_CMD\""
        ;;
esac

echo
pr_info "Command: \"$PARAM_CMD\" end."
echo
