#!/usr/bin/env bash
#
# @(#) flash_emmc
#
# Copyright © 2020 Revolution Robotics, Inc.
#
# This script creates a bootable eMMC storage device with Debian root
# and recovery filesystems.
#
declare -r SCRIPT_NAME=${0##*/}

declare -r COMPRESSION_SUFFIX=gz
declare -r ZCAT=zcat

declare -r IMGS_PATH=/opt/images/Debian
declare -r EMMC_DEVICE=mmcblk2

declare -r UBOOT_IMAGE=u-boot.img.mmc
declare -r SPL_IMAGE=SPL.mmc
declare -r KERNEL_IMAGE=zImage
declare -r KERNEL_DTBS=imx7d-roadrunner-emmc.dtb
declare -r ROOTFS_IMAGE=rootfs.tar.${COMPRESSION_SUFFIX}
declare -r RECOVERYFS_IMAGE=recoveryfs.tar.${COMPRESSION_SUFFIX}

usage ()
{
    cat <<EOF
Usage: $SCRIPT_NAME OPTIONS
Options:
  -h|--help              -- print this help, then exit.
EOF
}

pr_error ()
{
    echo "E: $@"
}

pr_info ()
{
    echo "I: $@"
}


if [[ $EUID != 0 ]] ; then
    echo "This script must be run with super-user privileges"
    exit 1
fi

check_images ()
{
    local dtb
    local image
    local -a distribution_images=(
        "$UBOOT_IMAGE"
        "$SPL_IMAGE"
        "$KERNEL_IMAGE"
        "$ROOTFS_IMAGE"
        "$RECOVERYFS_IMAGE"
        )

    for dtb in $KERNEL_DTBS; do
        if test ! -f "${IMGS_PATH}/${dtb}"; then
            pr_error "${IMGS_PATH}/${dtb}: No such file"
            return 1
        fi
    done

    for image in "${distribution_images[@]}"; do
        if test ! -f "${IMGS_PATH}/${image}"; then
            pr_error "${IMGS_PATH}/${image}: No such file"
            return 1
        fi
    done
}

# $1 is the full path of the config file
set_fw_env_config_to_emmc ()
{
    local fw_env_config=$1

    sed -i -e '/mtd/ s/^#*/#/' "$fw_env_config"
    sed -i -e "s;#*/dev/mmcblk.;/dev/${EMMC_DEVICE};" "$fw_env_config"
}

set_fw_utils_to_emmc_on_sd_card ()
{
    local fw_printenv=$(readlink /usr/bin/fw_printenv)

    # Adjust u-boot-fw-utils for eMMC on the SD card
    if test ."$fw_printenv"  != ."fw_printenv-mmc"; then
        ln -sf fw_printenv-mmc /usr/bin/fw_printenv
    fi

    if test -f /etc/fw_env.config; then
        set_fw_env_config_to_emmc /etc/fw_env.config
    fi
}

set_fw_utils_to_emmc_on_emmc ()
{
    local mountpoint=$1

    # Adjust u-boot-fw-utils for eMMC on the installed rootfs
    if test -f "${mountpoint}/usr/bin/fw_printenv-mmc"; then
        mv "${mountpoint}/usr/bin/fw_printenv-mmc" \
           "${mountpoint}/usr/bin/fw_printenv"
    fi

    if test -f "${mountpoint}/etc/fw_env.config"; then
        set_fw_env_config_to_emmc "${mountpoint}/etc/fw_env.config"
    fi
}

partition_emmc ()
{
    local device=$1
    local part=$2

    # Sizes in MiB
    # RECOVERYFS_SIZE must match that in recover_emmc.
    local RECOVERYFS_SIZE=1792
    local BOOTLOAD_RESERVE_SIZE=4
    local SPARE_SIZE=8

    # Get total device size in blocks
    local total_size=$(blockdev --getsz "$device")
    local total_size_bytes=$(( total_size * 512 ))
    local total_size_gib=$(perl -e "printf '%.1f', $total_size_bytes / 1024 ** 3")

    # Convert to MB
    total_size=$(( total_size / 2048 ))
    local rootfs_offset=$(( BOOTLOAD_RESERVE_SIZE + SPARE_SIZE ))
    local rootfs_size=$(( total_size - rootfs_offset - RECOVERYFS_SIZE ))
    local recoveryfs_offset=$(( rootfs_offset + rootfs_size ))

    pr_info "Device: $device, $total_size_gib GiB"
    echo "============================================="
    read -p "Press Enter to continue"

    pr_info "Creating new partitions:"
    pr_info "Root file system size: $rootfs_size MiB"
    pr_info "Recovery file system size: $RECOVERYFS_SIZE MiB"
    pr_info "Total size: $total_size MiB"

    local part1_start="${BOOTLOAD_RESERVE_SIZE}MiB"
    local part1_size="${SPARE_SIZE}MiB"
    local part2_start="${rootfs_offset}MiB"
    local part2_size="${rootfs_size}MiB"
    local part3_start="${recoveryfs_offset}MiB"

    # Erase file system signatures and labels
    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt "${device}${part}${i}")"; then
            umount "${device}${part}${i}"
        fi
        if test -e "${device}${part}${i}"; then
            tune2fs -L '' "${device}${part}${i}" >/dev/null 2>&1
            wipefs -a "${device}${part}${i}" >/dev/null 2>&1
        fi
    done
    wipefs -a "$device" >/dev/null 2>&1

    dd if=/dev/zero of="$device" bs=1M count="$rootfs_offset" >/dev/null 2>&1
    sleep 2
    sync

    flock "$device" sfdisk "$device" >/dev/null 2>&1 <<EOF
$part1_start,$part1_size,c
$part2_start,$part2_size,L
$part3_start,-,L
EOF

    partprobe "$device"
    sleep 2
    sync
}

format_emmc ()
{
    local device=$1
    local part=$2
    local bootpart=$3
    local rootfspart=$4
    local recoveryfspart=$5

    pr_info "Formating eMMC partitions"

    if ! mkfs.vfat -n BOOT "${device}${part}${bootpart}" >/dev/null 2>&1; then
        pr_error "${device}${part}${bootpart}: format failed"
        return 1
    elif ! mkfs.ext4 -L rootfs "${device}${part}${rootfspart}" >/dev/null 2>&1; then
        pr_error "${device}${part}${rootfspart}: format failed"
        return 1
    elif ! mkfs.ext4 -L recoveryfs "${device}${part}${recoveryfspart}" >/dev/null 2>&1; then
        pr_error "${device}${part}${recoveryfspart}: format failed"
        return 1
    fi
}

mount_partitions ()
{
    local mountdir_prefix=$1
    local device=$2
    local part=$3
    local bootpart=$4
    local rootfspart=$5
    local recoveryfspart=$6

    local bootdir="${mountdir_prefix}${bootpart}"
    local rootfsdir="${mountdir_prefix}${rootfspart}"
    local recoveryfsdir="${mountdir_prefix}${recoveryfspart}"

    pr_info "Mounting eMMC partitions"

    # Mount the partitions
    mkdir -p "$bootdir"
    mkdir -p "$rootfsdir"
    mkdir -p "$recoveryfsdir"

    if ! mount -t vfat "${device}${part}${bootpart}" "$bootdir" >/dev/null 2>&1; then
        pr_error "${device}${part}${bootpart}: mount failed"
        return 1
    elif ! mount -t ext4 "${device}${part}${rootfspart}" "$rootfsdir" >/dev/null 2>&1; then
        pr_error "${device}${part}${rootfspart}: mount failed"
        return 1
    elif ! mount -t ext4 "${device}${part}${recoveryfspart}" "$recoveryfsdir" >/dev/null 2>&1; then
        pr_error "${device}${part}${recoveryfspart}: mount failed"
        return 1
    fi
    sleep 2
    sync
}

flash_emmc ()
{
    local mountdir_prefix=$1
    local bootpart=$2
    local rootfspart=$3
    local recoveryfspart=$4

    local bootdir="${mountdir_prefix}${bootpart}"
    local rootfsdir="${mountdir_prefix}${rootfspart}"
    local recoveryfsdir="${mountdir_prefix}${recoveryfspart}"

    pr_info "Flashing eMMC \"BOOT\" partition"

    cp "${IMGS_PATH}/${KERNEL_IMAGE}" "$bootdir"
    for dtb in $KERNEL_DTBS; do
        cp "${IMGS_PATH}/${dtb}" "$bootdir"
    done
    sync

    pr_info "Flashing eMMC \"rootfs\" partition"

    if ! tar -C "$rootfsdir" -zxpf "${IMGS_PATH}/${ROOTFS_IMAGE}" \
         --checkpoint=4096 --checkpoint-action=.; then
        pr_error "$rootfsdir: eMMC flash did not complete successfully."
        return 1
    fi
    echo

    set_fw_utils_to_emmc_on_emmc "$rootfsdir"
    sync


    pr_info "Flashing eMMC \"recoveryfs\" partition"

    if ! tar -C "$recoveryfsdir" -zxpf "${IMGS_PATH}/${RECOVERYFS_IMAGE}" \
         --checkpoint=4096 --checkpoint-action=.; then
        pr_error "$recoveryfsdir: eMMC flash did not complete successfully."
        return 1
    fi
    echo

    set_fw_utils_to_emmc_on_emmc "$recoveryfsdir"
    sync
}

copy_images ()
{
    local recoveryfsdir=$1

    local dtb
    local image
    local recovery_imgs_path=${recoveryfsdir}/opt/images/Debian
    local -a recovery_images=(
        "$UBOOT_IMAGE"
        "$SPL_IMAGE"
        "$KERNEL_IMAGE"
        "$ROOTFS_IMAGE"
        )

    pr_info "Installing recovery images"

    mkdir -p "$recovery_imgs_path"
    for dtb in $KERNEL_DTBS; do
        install -m 0644 "${IMGS_PATH}/${dtb}" "$recovery_imgs_path"
    done

    for image in "${recovery_images[@]}"; do
        install -m 0644 "${IMGS_PATH}/${image}" "$recovery_imgs_path"
    done
}

flash_u-boot ()
{
    local device=$1

    local spl_image=${IMGS_PATH}/${SPL_IMAGE}
    local uboot_image=${IMGS_PATH}/${UBOOT_IMAGE}

    pr_info "Flashing eMMC U-Boot"

    if ! dd if="$spl_image" of="$device" bs=1K seek=1 >/dev/null 2>&1; then
        pr_error "eMMC flash did not complete successfully."
        return 1
    fi
    sync
    if ! dd if="$uboot_image" of="$device" bs=1K seek=69 >/dev/null 2>&1; then
        pr_error "eMMC flash did not complete successfully."
        return 1
    fi
}

finish ()
{

    local mountdir_prefix=$1
    local bootpart=$2
    local rootfspart=$3
    local recoveryfspart=$4

    local bootdir="${mountdir_prefix}${bootpart}"
    local rootfsdir="${mountdir_prefix}${rootfspart}"
    local recoveryfsdir="${mountdir_prefix}${recoveryfspart}"

    umount "$bootdir" "$rootfsdir" "$recoveryfsdir" || return 1

    if [[ ."${mountdir_prefix%/*}" =~ \./tmp/media ]]; then
        rm -rf "${mountdir_prefix%/*}"
    fi

    pr_info "eMMC flash completed successfully"
}

while getopts :b:hr: c;
do
    case $c in
        *)
            usage
            exit 1
            ;;
    esac
done

declare soc=$(cat /sys/bus/soc/devices/soc0/soc_id)
declare device=/dev/$EMMC_DEVICE
declare part=p
declare mountdir_prefix=/tmp/media/${EMMC_DEVICE}${part}
declare bootpart=1
declare rootfspart=2
declare recoveryfspart=3

if test ."$soc" != .'i.MX7D'; then
    pr_error "This script is for imaging an i.MX7D board's eMMC device"
    exit 1
elif test ! -b $device; then
    pr_error "$device: Device not found"
    exit 1
fi

pr_info "Board: $soc"
pr_info "Internal storage: eMMC"

check_images || exit $?
partition_emmc "$device" "$part" || exit $?
format_emmc "$device" "$part" "$bootpart" "$rootfspart" "$recoveryfspart" || exit $?
sleep 2
sync
mount_partitions "$mountdir_prefix" "$device" "$part" "$bootpart" "$rootfspart" "$recoveryfspart" || exit $?
flash_emmc "$mountdir_prefix" "$bootpart" "$rootfspart" "$recoveryfspart" || exit $?
copy_images "${mountdir_prefix}${recoveryfspart}"

flash_u-boot "$device" || exit $?
finish "$mountdir_prefix" "$bootpart" "$rootfspart" "$recoveryfspart"
