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

if ! findmnt ${ROOTFS_BASE}/proc >/dev/null; then
    $SUDO mount -t proc /proc ${ROOTFS_BASE}/proc
fi
for fs in sys dev dev/pts; do
    if ! findmnt "${ROOTFS_BASE}/${fs}" >/dev/null; then
        $SUDO mount -o bind "$fs" "${ROOTFS_BASE}/${fs}"
    fi
done

$SUDO chroot "$ROOTFS_BASE" /bin/bash
