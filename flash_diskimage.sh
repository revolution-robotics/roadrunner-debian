#!/usr/bin/env bash
#
# @(#) flash_diskimage
#
# Copyright © 2020 Revolution Robotics, Inc.
#
declare -r COMPRESSION_SUFFIX='gz'
declare -r ZCAT='zcat'

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
        echo "$(sed -e 's/ /|/g' <<< $(echo $(seq $size)))"
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
    local kind

    mapfile -t archives < <(ls output/*.$COMPRESSION_SUFFIX)
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
    local gdbus_resp

    # Check that parameter is a valid block device
    if [ ! -b "/dev/$device" ]; then
        pr_error "/dev/$device: Not a valid block device"
        return 1
    fi

    # Check that /sys/block/$dev exists
    if [ ! -d "/sys/block/$device" ]; then
        pr_error "/sys/block/$device: No such directory"
        return 1
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
        local gdbus_resp=$(
            gdbus call --system --dest org.freedesktop.UDisks2 \
                  --object-path ${drive} \
                  --method org.freedesktop.DBus.Properties.Get org.freedesktop.UDisks2.Drive MediaRemovable 2>/dev/null
              )
        if [[ ."$gdbus_resp" =~ ^\..*true ]]; then
            removable=1
        fi
    fi

    # Check that device is either removable or loop
    if [ "$removable" != "1" ] && ! is_loop_device "/dev/$device"; then
        pr_error "/dev/$device: Not a removable device"
        return 1
    fi
}

flash_diskimage ()
{
    local image=$1
    local device=$2
    local total_size
    local total_size_bytes
    local total_size_gib
    local -i i

    if test ! -e "$image"; then
        image=$(select_disk_image)
        if test ."$image" = .''; then
            pr_error "Image not available"
            exit 1
        fi
    fi

    if ! is_removable_device "$device"; then
        device=$(sed -e 's/ .*//' <<<$(select_removable_device))
        if test ."$device" = .''; then
            pr_error "Device not available"
            exit 1
        fi
    fi

    total_size=$(blockdev --getsz "$LPARAM_BLOCK_DEVICE")
    total_size_bytes=$(( total_size * 512 ))
    total_size_gib=$(bc <<< "scale=1; ${total_size_bytes}/(1024*1024*1024)")

    echo '============================================='
    echo "Image: $image"
    echo "Device: $device, ${size_gib} GiB"
    echo '============================================='
    read -p "Press Enter to continue"

    pr_info "Flashing image to device..."

    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt "${device}${i}")"; then
            sudo umount -f "${device}${i}"
        fi
    done
    $ZCAT "$image" | sudo dd of="$device" bs=1M
}


flash_diskimage "$@"
