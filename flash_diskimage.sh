#!/usr/bin/env bash
#
# @(#) flash_diskimage
#
# Copyright © 2020 Revolution Robotics, Inc.
#
declare -r SCRIPT_NAME=${0##*/}

declare -r COMPRESSION_SUFFIX='gz'
declare -r ZCAT='zcat'

declare PARAM_OUTPUT_DIR=output
declare PARAM_BLOCK_DEVICE='na'
declare PARAM_DISK_IMAGE='na'

usage ()
{
    cat <<EOF
Usage: $SCRIPT_NAME OPTIONS
Options:
  -h|--help   -- print this help
  -o|--output -- directory of disk image(s) (default: "$PARAM_OUTPUT_DIR")
  -d|--dev    -- removable block device to flash to (e.g., -d /dev/sde)
  -i|--image diskimage
              -- disk image to flash from (see also option -o)

Example:
  flash image to SD card:           ./${SCRIPT_NAME}
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
    local count=${#choices[*]}

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

    mapfile -t archives < <(ls "${PARAM_OUTPUT_DIR}/"*.$COMPRESSION_SUFFIX 2>/dev/null)
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

is_loop_device ()
{
    local device=$1

    (( $(stat -c '%t' "$device") == LOOP_MAJOR ))
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

flash_diskimage ()
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
        if test ! -b "$LPARAM_BLOCK_DEVICE"; then
            pr_error "Device not available"
            exit 1
        fi
    fi

    total_size=$(sudo blockdev --getsz "$LPARAM_BLOCK_DEVICE")
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
            sudo umount -f "${LPARAM_BLOCK_DEVICE}${i}"
        fi
    done

    if ! $ZCAT "$LPARAM_DISK_IMAGE" | sudo dd of="$LPARAM_BLOCK_DEVICE" bs=1M; then
        pr_error "Flash did not complete successfully."
        echo "*** Please check media and try again! ***"
    fi
}


## parse input arguments ##
declare -r SHORTOPTS='d:i:o:h'
declare -r LONGOPTS='dev:,image:,output:,help'

declare ARGS=$(
    getopt -s bash --options ${SHORTOPTS}  \
           --longoptions ${LONGOPTS} --name ${SCRIPT_NAME} -- "$@"
        )

eval set -- "$ARGS"

while true; do
    case $1 in
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

flash_diskimage
