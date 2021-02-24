#!/usr/bin/env bash
#
# @(#) express-recoveryfs.sh
#
# This script quickly creates a recovery filesystem by paring an
# existing root filesystem.
#
# After generating recovery filesystems `newfs' with this script and
# `recoveryfs' with debootstrap, generate for each a list of installed
# packages with the function `get-installed-pkgs' below. Comparing the
# installed packages lists shows that the two filesystems are very
# similar:
#
#     $ comm -3 newfs/newfs-installed.list recoveryfs/recoveryfs-installed.list
#     cpio
#     cron
#     init
#             libatm1
#             libnss-systemd
#             libpam-cap
#     sqlite3
#     xxd
#     $ sudo du -sm newfs
#     577
#     $ sudo du -sm recoveryfs
#     585
#
# The difference is size is mostly due to removal of newfs/usr/share/man/*.
#
set -e -o pipefail

declare -r script_name=${0##*/}

declare -r ABSOLUTE_FILENAME=$(readlink -e "$0")
declare -r G_VENDOR_PATH=${ABSOLUTE_FILENAME%/*}/revo
declare -r MACHINE=revo-roadrunner-mx7
declare -r G_IMAGES_DIR=opt/images/Debian

get-installed-pkgs ()
{
    local fs=$1

    cat >"${fs}/get-installed-pkgs.sh" <<EOF
#!/bin/bash
apt list --installed |
    sed -e '1d' -e 's;/.*;;' |
    sort -u >${fs##*/}-installed.list
rm -f /get-installed-pkgs.sh
EOF
    chmod +x "${fs}/get-installed-pkgs.sh"
    echo "chroot ${fs} /get-installed-pkgs.sh"
    chroot "${fs}" /get-installed-pkgs.sh
}

get-only-in-pkgs ()
{
    local fs1=$1
    local fs2=$2

    get-installed-pkgs "$fs1"
    get-installed-pkgs "$fs2"

    echo "comm -23 ${fs1}/${fs1##*/}-installed.list \\"
    echo "    ${fs2}/${fs2##*/}-installed.list >pkgs-only-in-${fs1##*/}.list"
    comm -23 "${fs1}/${fs1##*/}-installed.list" \
         "${fs2}/${fs2##*/}-installed.list" >"pkgs-only-in-${fs1##*/}.list"
}

get-auto-install-pkgs ()
{
    local fs=$1

    cat >"${fs}/get-auto-install-pkgs.sh" <<EOF
#!/bin/bash
apt-mark -y minimize-manual
sed -n '/^Package:/s;^Package: ;;p' \\
    /var/lib/apt/extended_states |
    sort -u >${fs##*/}-auto-install.list
rm -f /get-auto-install-pkgs.sh
EOF
    chmod +x "${fs}/get-auto-install-pkgs.sh"
    echo "chroot ${fs} /get-auto-install-pkgs.sh"
    chroot "${fs}" /get-auto-install-pkgs.sh
}

get-only-in-auto-install ()
{
    local fs1=$1
    local fs2=$2

    get-auto-install-pkgs "$fs1"
    get-auto-install-pkgs "$fs2"

    echo "comm -23 ${fs1}/${fs1##*/}-auto-install.list \\"
    echo "    ${fs2}/${fs2##*/}-auto-install.list >auto-install-only-in-${fs1##*/}.list"
    comm -23 "${fs1}/${fs1##*/}-auto-install.list" \
         "${fs2}/${fs2##*/}-auto-install.list" >"auto-install-only-in-${fs1##*/}.list"
}

pare-fs ()
{
    local fs=$1
    local tarball=$2
    local purge_lists=$3

    echo "tar -C $fs -xpf $tarball"
    rm -rf "$fs"
    install -d -m 0755 "$fs"
    tar -C "$fs" -xpf "$tarball"
    for list in $purge_lists; do
        install -m 0755 "$list" "$fs"
    done
    cat >"${fs}/pare-fs.sh" <<EOF
#!/bin/bash
for list in $purge_lists; do
    apt -y purge \$(< "\$list")
done
rm -rf /usr/share/man/*
userdel revo
rm -rf /home/revo
rm -f /pare-fs.sh
EOF
    chmod +x "${fs}/pare-fs.sh"
    echo "chroot ${fs} /pare-fs.sh"
    chroot "${fs}" /pare-fs.sh
}

if test ."$0" = ."${BASH_SOURCE[0]}"; then
    declare rootfs_tarball=${PWD}/output/rootfs.tar.gz
    declare rootfs=${PWD}/rootfs
    declare recoveryfs=${PWD}/recoveryfs
    declare newfs=${PWD}/newfs

    if test ."$USER" != .'root'; then
        echo "$script_name: Run as user root"
        exit
    fi

    # Clean up from any prior run.
    rm -f *.list

    get-only-in-pkgs "$rootfs" "$recoveryfs"
    get-only-in-auto-install "$rootfs" "$recoveryfs"

    # The packages common between lists pkgs-only-in-rootfs.list and
    # auto-install-only-in-rootfs.list are removed from a copy of
    # rootfs to produce the base of a recovery filesystem.
    echo "comm -12 pkgs-only-in-rootfs.list auto-install-only-in-rootfs.list \\"
    echo "    >pkgs-to-remove.list"
    comm -12 pkgs-only-in-rootfs.list auto-install-only-in-rootfs.list \
         >pkgs-to-remove.list

    # The list of packages to remove, pkgs-to-remove.list, is
    # augmented by a curated list of residual packages, appended as a
    # patch to this script. This list was produced after purging
    # pkgs-to-remove.list and comparing the remaining installed
    # packages against those in recoveryfs. So after enough iterations
    # and/or version changes, the list should be re-examined.

    # Extract and apply patch at the end of this script to create
    # `residual-to-remove.list'.
    sed -n '/BEGIN patch/,$s/^#//p' "${script_name}" | patch -p0

    # To produce recoveryfs, copy rootfs and remove from it all
    # packages in both lists `pkgs-to-remove.list' and
    # `residual-to-remove.list'.
    pare-fs "$newfs" "$rootfs_tarball" "pkgs-to-remove.list residual-to-remove.list"

    # Disable Pulse audio service.
    rm -f "${newfs}/etc/systemd/system/multi-user.target.wants/pulseaudio.service"

    # Disable Exim4 mail service.
    rm -f "${newfs}/etc/systemd/system/multi-user.target.wants/exim4.service"

    # Disable flash eMMC service (recoveryfs uses recover eMMC service instead).
    rm -f "${newfs}/lib/systemd/system/system-update.target.wants/flash-emmc.service"

    # Install REVO recover eMMC service.
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc" "${newfs}/usr/sbin"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc.service" \
            "${newfs}/lib/systemd/system"
    install -d -m 0755 "${newfs}/lib/systemd/system/system-update.target.wants"
    ln -sf '../recover-emmc.service' \
       "${newfs}/lib/systemd/system/system-update.target.wants"
    ln -sf "$G_IMAGES_DIR" "${newfs}/system-update"

    # Support resizing a serial console - taken from Debian xterm package.
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/resize" \
            "${newfs}/usr/bin"
fi

## **** BEGIN patch ****
#diff -Nru residual-to-remove.list~ residual-to-remove.list
#--- residual-to-remove.list~   1969-12-31 19:00:00.000000000 -0500
#+++ residual-to-remove.list    2020-12-29 02:08:49.534680534 -0500
#@@ -0,0 +1,22 @@
#+bluez-tools
#+dmidecode
#+gdbm-l10n
#+iperf
#+iputils-ping
#+libestr0
#+libfastjson4
#+libip6tc0
#+libiptc0
#+liblognorm5
#+logrotate
#+mtd-utils
#+nano
#+net-tools
#+rsyslog
#+systemtap-sdt-dev
#+tasksel
#+tasksel-data
#+traceroute
#+vim-common
#+vim-tiny
#+whiptail
