#!/usr/bin/env bash
#
# @(#) flash-diskimage
#
# Copyright © 2022 Revolution Robotics, Inc.
#
# This script is intended for flashing a USB drive with a bootable
# image file.
#
# In addition to requiring a recent version of the Bash shell
# interpreter, for identifying removable devices, it depends on
# GNU/Linux sysfs, udisksctl and gdbus.
#
usage ()
{
    cat <<EOF
Usage: $script_name OPTIONS
Options:
  -h|--help   - Print this help, then exit.
  -b|--block-device DEVICE
              - Flash to removable block DEVICE (e.g., -d /dev/sdh).
  -d|--directory DIRECTORY
              - Select image from DIRECTORY (default: $PWD).
  -f|--file IMAGE
              - Flash file IMAGE (see also option -d).
  -v|--verbose
              - Debug script.
  -x|--ex-dos-mbr
              - Include in selection lists non-USB boot images.

Examples:
  To flash an image in the current directory to a removable block
  device, use:

    ${script_name}

  To flash a specific image, \`/path/to/file.iso', to a specific block
  device, \`/dev/sdh', use:

    ${script_name} /path/to/file.iso /dev/sdh

  When selecting from multiple images to flash, this script lists, by
  default, only those that can produce a bootable USB drive. In
  particular, ISO 9660 images that don't have a DOS/MBR boot sector
  are omitted. To include these images in the selection list, invoke
  the script with option \`-x', e.g.:

    ${script_name} -x

  Alternatively, any file can be flashed by providing its path as in
  the example above.

EOF
}

pr-error ()
{
    echo "Error: $@" >&2
}

pr-info ()
{
    echo "$@" >&2
}

get-range ()
{
    size=$1

    if (( size > 9 )); then
        echo "1-$size"
    else
        echo $(seq $size) | tr ' ' '|'
    fi
}

select-from-list ()
{
    local -n choices=$1
    local prompt=$2

    local choice
    local count=${#choices[*]}

    case "$count" in
        0)
            pr-error "Nothing to choose"
            return 1
            ;;
        1)
            choice=${choices[0]}
            ;;
        *)
            echo "$prompt" >&2
            PS3="Selection [$(get-range $count)]? "
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

get-decompressor ()
{
    local image_file=$1

    case $(file "$image_file") in
        *bzip2*)
            image_cat='bzip2 -dc'
            ;;
        *lzip*)
            image_cat='lzip -dc'
            ;;
        *LZMA*)
            image_cat='lzma -dc'
            ;;
        *lzop*)
            image_cat='lzop -dc'
            ;;
        *gzip*)
            image_cat='gzip -dc'
            ;;
        *XZ*)
            image_cat='xz -dc'
            ;;
        *Zip*)
            image_cat='unzip -p'
            ;;
        *'ISO 9660'*|*'DOS/MBR boot sector'*)
            image_cat=cat
            ;;
        *)
            image_cat=unknown
            ;;
    esac

    if test ."$image_cat" = .'unknown'; then
        pr-error "${image_file}: Unrecognized image"
        return 1
    fi

    echo "$image_cat"
}

get-disk-images ()
{
    local image_directory=$1
    local ex_dos_mbr=$2

    local image_suffixes='{bz2,gz,img,iso,lz,lzma,lzo,xz,zip}'

    local -a archives
    local archive
    local image_cat

    mapfile -t archives < <(eval ls "${image_directory}/"*.${image_suffixes} 2>/dev/null)

    for archive in "${archives[@]}"; do
        image_cat=$(get-decompressor "$archive")
        case $($image_cat "$archive" | file -) in
            *'DOS/MBR boot sector'*)
                echo "$archive"
                ;;
            *'ISO 9660'*'bootable'*)
                if $ex_dos_mbr; then
                    echo "$archive"
                fi
                ;;
        esac
    done
}

get-removable-devices ()
{
    local -a devices
    local device
    local vendor
    local model

    mapfile -t devices < <(
        grep -lv '^0$' '/sys/block/'*'/removable' |
            sed -e 's;removable$;device/uevent;' |
            xargs grep -l '^DRIVER=sd$' |
            sed -e 's;device/uevent;size;' |
            xargs grep -lv '^0' |
            cut -d/ -f4
    )

    for device in "${devices[@]}"; do
        vendor=$(echo $(< "/sys/block/${device}/device/vendor"))
        model=$(echo $(< "/sys/block/${device}/device/model"))
        echo "/dev/$device ($vendor $model)"
    done
}

select-disk-image ()
{
    local image_directory=$1
    local ex_dos_mbr=$2

    local -a disk_images

    mapfile -t disk_images < <(get-disk-images "$image_directory" "$ex_dos_mbr")
    select-from-list disk_images 'Please choose an image to flash from:'
}

select-removable-device ()
{
    declare -a removable_devices

    mapfile -t removable_devices < <(get-removable-devices)
    select-from-list removable_devices 'Please choose a device to flash to:'
}

is-removable-device ()
{
    local device=${1#/dev/}

    local removable
    local drive
    local gdbus_is_removable

    # Check that parameter is a valid block device
    if test ! -b "/dev/$device"; then
        pr-error "/dev/$device: Not a valid block device"
        return 1
    fi

    # Check that /sys/block/$dev exists
    if test ! -d "/sys/block/$device"; then
        pr-error "/sys/block/$device: No such directory"
        return 1
    fi

    # Get device parameters
    removable=$(cat "/sys/block/${device}/removable")

    # Non removable SD card readers require additional check
    if test ."$removable" != .'1'; then
        drive=$(udisksctl info -b "/dev/$device" |
                    awk -F\' '/Drive:/ { print $2 }')
        gdbus_is_removable=$(
            gdbus call --system --dest org.freedesktop.UDisks2 \
                  --object-path "$drive" \
                  --method org.freedesktop.DBus.Properties.Get \
                  org.freedesktop.UDisks2.Drive MediaRemovable 2>/dev/null
                          )
        if [[ ."$gdbus_is_removable" =~ ^\..*true ]]; then
            removable=1
        fi
    fi

    # Device not removable
    if test ."$removable" != .'1'; then
        pr-error "/dev/$device: Not a removable device"
        return 1
    fi
}

get-image-file ()
{
    local image_directory=$1
    local image_file=$2
    local ex_dos_mbr=$3

    if test ! -f "$image_file"; then
        if test -f "${image_directory}/${image_file}"; then
            image_file=${image_directory}/${image_file}
        else
            image_file=$(select-disk-image "$image_directory" "$ex_dos_mbr")
        fi

        if test ! -f "$image_file"; then
            pr-error "${image_file}: Image not available"
            return 1
        fi
    fi

    echo "$image_file"
}

get-block-device ()
{
    local block_device=$1

    local total_size
    local total_size_bytes
    local total_size_gib
    local -i i

    if ! is-removable-device "$block_device" >/dev/null 2>&1; then
        block_device=$(select-removable-device | awk '{ print $1 }')

        if test ! -b "$block_device"; then
            pr-error "${block_device}: Device not available"
            return 1
        fi
    fi

    echo "$block_device"
}

verify-media ()
{
    local image_file=$1
    local block_device=$2

    total_size=$(sudo blockdev --getsz "$block_device")
    total_size_bytes=$(( total_size * 512 ))
    total_size_gib=$(perl -e "printf '%.1f', $total_size_bytes / 1024 ** 3")

    echo '═════════════════════════════════════════════' >&2
    pr-info "Image: ${image_file##*/}"
    pr-info "Device: $block_device, $total_size_gib GiB"
    echo '─────────────────────────────────────────────' >&2
    read -t 30 -p "Press Enter to continue... "
    local -i status=$?

    if (( status != 0 )); then
       echo >&2
       pr-error "Timed out waiting for response"
       return $status
    fi
}

flash-image ()
{
    local image_file=$1
    local image_cat=$2
    local block_device=$3

    pr-info "Flashing image to device..."

    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt -n "${block_device}${i}")"; then
            sudo umount -f "${block_device}${i}"
        fi
    done

    errfile=$(mktemp "/tmp/${script_name}.XXXXX")
    trap 'rm -f "$errfile"; exit' 0 1 2 15 RETURN

    if ! $image_cat "$image_file" |
            sudo dd of="$block_device" bs=1M 2>"$errfile"; then
        pr-error "Flash did not complete successfully."
        echo "*** Please check media and try again! ***"
        return 1
    fi

    local bytes_written=$(awk '/bytes/ { print $1 }' "$errfile")

    rm -f "$errfile"
    trap - 0 1 2 15 RETURN

    echo "$bytes_written"
}

verify-diskimage ()
{
    local image_file=$1
    local block_device=$2
    local -i bytes_written=$3

    pr-info "Verifying device against image..."

    errfile=$(mktemp "/tmp/${script_name}.XXXXX")
    trap 'rm -f "$errfile"; exit' 0 1 2 15 RETURN

    $image_cat "$image_file" |
        sudo cmp -n "$bytes_written" "$block_device" - >"$errfile" 2>&1

    local bytes_verified=$(sed -nE -e 's/.*differ: byte +([0-9]+).*$/\1/p' "$errfile")

    if test -s "$errfile"; then
        pr-error "Device and image differ at byte: ${bytes_verified}"
        return 1
    fi

    rm -f "$errfile"
    trap - 0 1 2 15 RETURN

    pr-info "Compared: ${bytes_written} bytes"
    pr-info 'Device successfully verified'
}

if test ."$0" = ."${BASH_SOURCE[0]}"; then
    declare -r script_name=${0##*/}

    declare block_device
    declare image_cat
    declare image_directory=$PWD
    declare image_file
    declare verbose=false
    declare ex_dos_mbr=false

    ## parse input arguments ##
    declare -r short_opts=b:d:f:hvx
    declare -r long_opts=block-device:,directory:,file:,help,verbose,ex-dos-mbr

    declare ARGS=$(
        getopt -s bash --options "$short_opts"  \
               --longoptions "$long_opts" --name "$script_name" -- "$@"
            )

    eval set -- "$ARGS"

    while true; do
        case "$1" in
            -b|--block-device) # flash disk block device
                shift
                block_device=$1

                if test -b "$block_device"; then
                    pr-error "${block_device}: No such file or directory"
                    exit 1
                fi
                ;;
            -d|--directory) # image directory
                shift
                image_directory=$1

                if test ! -d "$image_directory"; then
                    pr-error "${image_directory}: No such file or directory"
                    exit 1
                fi
                ;;
            -f|--file) # image file
                shift
                image_file=$1

                if test ! -f "$image_file"; then
                    pr-error "${image_file}: No such file or directory"
                    exit 1
                fi
                ;;
            -h|--help) # get help
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -x|--ex-dos-mbr)
                ex_dos_mbr=true
                ;;
            --)
                shift
                break
                ;;
            *) # Process non-option arguments below...
                break
                ;;
        esac
        shift
    done

    # enable trace option in debug mode
    if $verbose; then
        echo "Debug mode enabled!"
        set -x
    fi

    case $# in
        0)
            : Nothing to do
            ;;
        1)
            image_file=$1
            ;;
        *)
            image_file=$1
            block_device=$2
            ;;
    esac

    image_file=$(get-image-file "$image_directory" "$image_file" "$ex_dos_mbr") || exit $?
    image_cat=$(get-decompressor "$image_file") || exit $?
    block_device=$(get-block-device "$block_device") || exit $?
    verify-media "$image_file" "$block_device" || exit $?

    declare -i bytes_written

    bytes_written=$(flash-image "$image_file" "$image_cat" "$block_device") || exit $?
    verify-diskimage "$image_file" "$block_device" "$bytes_written" || exit $?
fi
