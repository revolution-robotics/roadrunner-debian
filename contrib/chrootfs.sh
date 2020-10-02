#!/usr/bin/env bash
#
# Mount given Debian rootfs.
#
declare ROOTFS_BASE=${1:-'rootfs'}

: ${SUDO:='/usr/bin/sudo'}

umount_rootfs ()
{
    $SUDO umount -f "${ROOTFS_BASE}/"{sys,proc,dev/pts,dev} 2>/dev/null || true
    $SUDO umount -f "${ROOTFS_BASE}/dev" 2>/dev/null || true
}

trap 'umount_rootfs; exit' 0 1 2 15

$SUDO mount -t proc /proc "${ROOTFS_BASE}/proc"
$SUDO mount -o bind /sys "${ROOTFS_BASE}/sys"
$SUDO mount -o bind /dev "${ROOTFS_BASE}/dev"
$SUDO mount -o bind /dev/pts "${ROOTFS_BASE}/dev/pts"

$SUDO chroot "$ROOTFS_BASE" /bin/bash
