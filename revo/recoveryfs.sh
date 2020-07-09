#!/usr/bin/env bash
#
# Must be called after make_prepare in main script
# function generate recoveryfs in input dir
# $1 - recoveryfs base dir
make_debian_recoveryfs ()
{
    local RECOVERYFS_BASE=$1

    pr_info "Make debian(${DEB_RELEASE}) recoveryfs start..."

    # umount previus mounts (if fail)
    umount "${RECOVERYFS_BASE}/"{sys,proc,dev/pts,dev} 2>/dev/null || true

    # clear recoveryfs dir
    rm -rf "${RECOVERYFS_BASE}/"*

    pr_info "recoveryfs: debootstrap"
    # debootstrap --verbose --no-check-gpg --foreign --arch armhf "${DEB_RELEASE}" \
    #             "${RECOVERYFS_BASE}/" "${PARAM_DEB_LOCAL_MIRROR}"
    debootstrap --variant=minbase --verbose  --foreign --arch armhf \
                --keyring="/usr/share/keyrings/debian-${DEB_RELEASE}-release.gpg" \
                "${DEB_RELEASE}" "${RECOVERYFS_BASE}/" "${PARAM_DEB_LOCAL_MIRROR}"

    # prepare qemu
    pr_info "recoveryfs: debootstrap in recoveryfs (second-stage)"
    install -m 0755 "${G_VENDOR_PATH}/qemu_32bit/qemu-arm-static" "${RECOVERYFS_BASE}/usr/bin"

    umount_recoveryfs ()
    {
        umount -f "${RECOVERYFS_BASE}/"{sys,proc,dev/pts,dev} 2>/dev/null || true
        umount -f "${RECOVERYFS_BASE}/dev" 2>/dev/null || true
    }

    trap 'umount_recoveryfs' RETURN
    trap 'umount_recoveryfs; exit' 0 1 2 15

    mount -t proc /proc ${RECOVERYFS_BASE}/proc
    mount -o bind /sys ${RECOVERYFS_BASE}/sys
    mount -o bind /dev ${RECOVERYFS_BASE}/dev
    mount -o bind /dev/pts ${RECOVERYFS_BASE}/dev/pts

    chroot $RECOVERYFS_BASE /debootstrap/debootstrap --second-stage

    # delete unused folder
    chroot $RECOVERYFS_BASE rm -rf  ${RECOVERYFS_BASE}/debootstrap

    # pr_info "recoveryfs: generate default configs"
    # mkdir -p ${RECOVERYFS_BASE}/etc/sudoers.d/
    # echo "user ALL=(root) /usr/bin/apt-get, /usr/bin/dpkg, /usr/bin/vi, /sbin/reboot" > ${RECOVERYFS_BASE}/etc/sudoers.d/user
    # chmod 0440 ${RECOVERYFS_BASE}/etc/sudoers.d/user

    # install local Debian packages
    mkdir -p ${RECOVERYFS_BASE}/srv/local-apt-repository

    # udisk2
    cp -r ${G_VENDOR_PATH}/deb/udisks2/* \
       ${RECOVERYFS_BASE}/srv/local-apt-repository

    # gstreamer-imx
    # cp -r ${G_VENDOR_PATH}/deb/gstreamer-imx/* \
    #    ${RECOVERYFS_BASE}/srv/local-apt-repository

    # shared-mime-info
    # cp -r ${G_VENDOR_PATH}/deb/shared-mime-info/* \
    #    ${RECOVERYFS_BASE}/srv/local-apt-repository

    # add mirror to source list
    cat >etc/apt/sources.list <<EOF
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE} main contrib non-free
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
EOF

    # raise backports priority
    cat >etc/apt/preferences.d/backports <<EOF
Package: *
Pin: release n=${DEB_RELEASE}-backports
Pin-Priority: 500
EOF

    # maximize local repo priority
    cat >etc/apt/preferences.d/local <<EOF
Package: *
Pin: origin ""
Pin-Priority: 1000
EOF

    cat >etc/fstab <<EOF

# /dev/mmcblk0p1  /boot           vfat    defaults        0       0
EOF

    echo "$MACHINE" > etc/hostname
    cat >etc/hosts <<EOF
127.0.0.1	localhost
127.0.1.1	$MACHINE

# The following lines are desirable for IPv6 capable hosts
::1		ip6-localhost ip6-loopback
fe00::0		ip6-localnet
ff00::0		ip6-mcastprefix
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
EOF

#     echo "auto lo
# iface lo inet loopback
# " > etc/network/interfaces

    cat >debconf.set <<EOF
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
console-common	console-data/keymap/policy	select	Select keymap from full list
keyboard-configuration keyboard-configuration/variant select 'English (US)'
openssh-server openssh-server/permit-root-login select true
EOF

    pr_info "recoveryfs: prepare install packages in recoveryfs"
    # apt-get install without starting
    cat > ${RECOVERYFS_BASE}/usr/sbin/policy-rc.d << EOF
#!/bin/sh
exit 101
EOF

    chmod +x ${RECOVERYFS_BASE}/usr/sbin/policy-rc.d

    # third packages stage
    cat > third-stage << EOF
#!/bin/bash
# apply debconfig options
debconf-set-selections /debconf.set
rm -f /debconf.set

protected_install ()
{
    local _name=\${1}
    local repeated_cnt=5
    local RET_CODE=1

    for (( c=0; c < \${repeated_cnt}; c++ )); do
        apt-get install -y \${_name} && {
            RET_CODE=0
            break
        }

        echo ""
        echo "###########################"
        echo "## Fix missing packeges ###"
        echo "###########################"
        echo ""

        sleep 2
        apt --fix-broken install -y && {
                RET_CODE=0
                break
        }
    done

    return \${RET_CODE}
}

# silence some apt warnings
protected_install dialog

# update packages and install base
apt-get update || apt-get upgrade

# local-apt-repository support
protected_install local-apt-repository
protected_install reprepro
reprepro rereference

# update packages and install base
apt-get update || apt-get upgrade

protected_install locales
protected_install ntp
protected_install openssh-server
# protected_install nfs-common

# packages required when flashing emmc
protected_install dosfstools

# fix config for sshd (permit root login)
sed -i -e 's/#PermitRootLogin.*/PermitRootLogin\tyes/g' /etc/ssh/sshd_config

# rng-tools
protected_install rng-tools

# udisk2
protected_install udisks2

# gvfs
# protected_install gvfs

# gvfs-daemons
# protected_install gvfs-daemons

# net-tools (ifconfig, etc.)
# protected_install net-tools

# enable graphical desktop
# protected_install xorg
# protected_install xfce4
# protected_install xfce4-goodies

# network manager
# protected_install network-manager-gnome

# net-tools (ifconfig, etc.)
# protected_install net-tools

## fix lightdm config (added autologin x_user) ##
# sed -i -e 's/\#autologin-user=/autologin-user=x_user/g' /etc/lightdm/lightdm.conf
# sed -i -e 's/\#autologin-user-timeout=0/autologin-user-timeout=0/g' /etc/lightdm/lightdm.conf

# added alsa & alsa utilites
# protected_install alsa-utils
# protected_install gstreamer1.0-alsa

# protected_install gstreamer1.0-plugins-bad
# protected_install gstreamer1.0-plugins-base
# protected_install gstreamer1.0-plugins-ugly
# protected_install gstreamer1.0-plugins-good
# protected_install gstreamer1.0-tools

# added gstreamer-imx
# protected_install gstreamer-imx

# added i2c tools
protected_install i2c-tools

# added usb tools
protected_install usbutils

# added net tools
# protected_install iperf

# mtd
# protected_install mtd-utils

# bluetooth
protected_install bluetooth
# protected_install bluez-obexd
# protected_install bluez-tools
# protected_install blueman
# protected_install gconf2

# shared-mime-info
# protected_install shared-mime-info

# wifi support packages
protected_install hostapd
# protected_install udhcpd

# disable the hostapd service by default
systemctl disable hostapd.service

# can support
# protected_install can-utils

# pm-utils
# protected_install pm-utils

# BEGIN -- REVO i.MX7D networking
apt-get -y install ethtool
apt-get -y install manpages-dev

# ifupdown is superceded by NetworkManager
apt-get -y purge ifupdown
rm -f /etc/network/interfaces

# iptables is superceded by nftables, but NetworkManager still depends
# on compatibility interface, iptables-nft, provided by iptables.
# See https://www.redhat.com/en/blog/using-iptables-nft-hybrid-linux-firewall.
# apt-get -y purge iptables
printf "\n\n" | DEBIAN_FRONTEND=noninteractive apt-get -y install network-manager
DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent
rm -f /etc/iptables/rules.v[46]

# Defaults, starting with Debian buster:
# update-alternatives --set iptables /usr/sbin/iptables-nft
# update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
# update-alternatives --set arptables /usr/sbin/arptables-nft
# update-alternatives --set ebtables /usr/sbin/ebtables-nft
# END -- REVO i.MX7D networking

# apt-get -y autoremove

# apt-get install -y --reinstall libgdk-pixbuf2.0-0

# create users and set password
# useradd -m -G audio -s /bin/bash user
# useradd -m -G audio -s /bin/bash x_user
# usermod -a -G video user
# usermod -a -G video x_user
# echo "user:user" | chpasswd
echo "root:root" | chpasswd
# passwd -d x_user

# BEGIN -- REVO i.MX7D users
# groupadd revo
# useradd -m -G revo -s /bin/bash revo
# usermod -aG audio revo
# usermod -aG bluetooth revo
# usermod -aG lp revo
# usermod -aG pulse revo
# usermod -aG pulse-access revo
# usermod -aG sudo revo
# usermod -aG video revo

# echo "revo:revo" | chpasswd
# END -- REVO i.MX7D users

# sado kill
rm -f third-stage
EOF

    pr_info "recoveryfs: install selected debian packages (third-stage)"
    chmod +x third-stage
    LANG=C chroot ${RECOVERYFS_BASE} /third-stage
    # fourth-stage

    # BEGIN -- REVO i.MX7D updates
    # Support resizing a serial console - taken from Debian xterm package.
    install -m 0755 ${G_VENDOR_PATH}/recovery_resources/resize \
            ${RECOVERYFS_BASE}/usr/bin

    # Regenerate SSH keys on first boot
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/regenerate-ssh-host-keys.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -s '/lib/systemd/system/regenerate-ssh-host-keys.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    # Set PATH and resize serial console window.
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/bash.bashrc" \
            "${RECOVERYFS_BASE}/etc"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/profile" \
            "${RECOVERYFS_BASE}/etc"

    # Set Exim hostname to $MACHINE
    echo "$MACHINE" > "${RECOVERYFS_BASE}/etc/mailname"

    # Mount /tmp, /var/tmp and /var/log on tmpfs.
    install -m 0644 "${RECOVERYFS_BASE}/usr/share/systemd/tmp.mount" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/var-"{log,tmp}.mount \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/var-log.conf" \
            "${RECOVERYFS_BASE}/usr/lib/tmpfiles.d"

    # Mount systemd journal on tmpfs
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/journald.conf" \
            "${RECOVERYFS_BASE}/etc/systemd"

    # Install redirect-web-ports service.
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/redirect-web-ports" \
            "${RECOVERYFS_BASE}/sbin"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/redirect-web-ports.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -s '/lib/systemd/system/redirect-web-ports.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    # Install NetworkManager auto-share dispatcher.
    # Fix permissions set by Git
    chmod -R g-w "${G_VENDOR_PATH}/NetworkManager/"*
    chmod 750 "${G_VENDOR_PATH}/NetworkManager/etc/NetworkManager/dispatcher.d/50-default-ethernet-ap"
    chmod 750 "${G_VENDOR_PATH}/NetworkManager/etc/NetworkManager/dispatcher.d/51-default-wifi-ap"

    tar -C "${G_VENDOR_PATH}/NetworkManager" -cf - . |
        tar -C "${RECOVERYFS_BASE}" -oxf -

    ln -sf '/lib/systemd/system/NetworkManager-dispatcher.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service"
    ln -s '../NetworkManager-autoshare-clean.service' \
       "${RECOVERYFS_BASE}/lib/systemd/system/sysinit.target.wants"

    rm -f "${RECOVERYFS_BASE}/etc/NetworkManager/dispatcher.d/"*ifupdown
    # END -- REVO i.MX7D update

    # install variscite-bt service
    install -m 0755 ${G_VENDOR_PATH}/recovery_resources/brcm_patchram_plus \
            ${RECOVERYFS_BASE}/usr/bin
    install -d ${RECOVERYFS_BASE}/etc/bluetooth
    install -m 0644 ${G_VENDOR_PATH}/${MACHINE}/variscite-bt.conf \
            ${RECOVERYFS_BASE}/etc/bluetooth
    install -m 0755 ${G_VENDOR_PATH}/recovery_resources/variscite-bt \
            ${RECOVERYFS_BASE}/etc/bluetooth
    install -m 0644 ${G_VENDOR_PATH}/recovery_resources/variscite-bt.service \
            ${RECOVERYFS_BASE}/lib/systemd/system
    ln -s /lib/systemd/system/variscite-bt.service \
       ${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/variscite-bt.service

    # install BT audio and main config
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/bluez5/files/audio.conf \
    #         ${RECOVERYFS_BASE}/etc/bluetooth/
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/bluez5/files/main.conf \
    #         ${RECOVERYFS_BASE}/etc/bluetooth/

    # install obexd configuration
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/bluez5/files/obexd.conf \
    #         ${RECOVERYFS_BASE}/etc/dbus-1/system.d

    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/bluez5/files/obex.service \
    #         ${RECOVERYFS_BASE}/lib/systemd/system
    # ln -s /lib/systemd/system/obex.service \
    #    ${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/obex.service

    # install pulse audio configuration
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/pulseaudio/pulseaudio.service \
    #         ${RECOVERYFS_BASE}/lib/systemd/system
    # ln -s /lib/systemd/system/pulseaudio.service \
    #    ${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/pulseaudio.service
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/pulseaudio/pulseaudio-bluetooth.conf \
    #         ${RECOVERYFS_BASE}/etc/dbus-1/system.d
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/pulseaudio/system.pa \
    #         ${RECOVERYFS_BASE}/etc/pulse/

    # Add alsa default configs
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/asound.state \
    #         ${RECOVERYFS_BASE}/var/lib/alsa/
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/asound.conf ${RECOVERYFS_BASE}/etc/

    # install variscite-wifi service
    install -d ${RECOVERYFS_BASE}/etc/wifi
    install -m 0644 ${G_VENDOR_PATH}/recovery_resources/blacklist.conf \
            ${RECOVERYFS_BASE}/etc/wifi
    install -m 0644 ${G_VENDOR_PATH}/${MACHINE}/variscite-wifi.conf \
            ${RECOVERYFS_BASE}/etc/wifi
    install -m 0644 ${G_VENDOR_PATH}/recovery_resources/variscite-wifi-common.sh \
            ${RECOVERYFS_BASE}/etc/wifi
    install -m 0755 ${G_VENDOR_PATH}/recovery_resources/variscite-wifi \
            ${RECOVERYFS_BASE}/etc/wifi
    install -m 0644 ${G_VENDOR_PATH}/recovery_resources/variscite-wifi.service \
            ${RECOVERYFS_BASE}/lib/systemd/system
    ln -s /lib/systemd/system/variscite-wifi.service \
       ${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/variscite-wifi.service

    # remove pm-utils default scripts and install wifi / bt pm-utils script
    rm -rf ${RECOVERYFS_BASE}/usr/lib/pm-utils/sleep.d/
    rm -rf ${RECOVERYFS_BASE}/usr/lib/pm-utils/module.d/
    rm -rf ${RECOVERYFS_BASE}/usr/lib/pm-utils/power.d/
    install -d -m 0755 ${RECOVERYFS_BASE}/etc/pm/sleep.d
    install -m 0755 ${G_VENDOR_PATH}/${MACHINE}/wifi.sh \
            ${RECOVERYFS_BASE}/etc/pm/sleep.d/

    # tar -xzf ${G_VENDOR_PATH}/deb/shared-mime-info/mime_image_prebuilt.tar.gz -C \
    #     ${RECOVERYFS_BASE}/
    ## end packages stage ##
    if test ."${G_USER_PACKAGES}" != .''; then

        pr_info "recoveryfs: install user defined packages (user-stage)"
        pr_info "recoveryfs: G_USER_PACKAGES \"${G_USER_PACKAGES}\" "

        cat > user-stage << EOF
#!/bin/bash
# update packages
apt-get update

# install all user packages from backports
DEBIAN_FRONTEND=noninteractive apt-get -yq -t ${DEB_RELEASE}-backports install ${G_USER_PACKAGES}
pip3 install minimalmodbus
pip3 install pystemd
pip3 install pytz

# BEGIN -- REVO i.MX7D purge
apt-get -y purge build-essential gcc-8 libpython2.7 libx11-6 manpages{,-dev}
apt-get --purge -y autoremove
apt-get clean
# END -- REVO i.MX7D purge

rm -f user-stage
EOF

        chmod +x user-stage
        LANG=C chroot ${RECOVERYFS_BASE} /user-stage

    fi

    # binaries recoveryfs patching
    install -m 0644 ${G_VENDOR_PATH}/issue ${RECOVERYFS_BASE}/etc/
    install -m 0644 ${G_VENDOR_PATH}/issue.net ${RECOVERYFS_BASE}/etc/
    install -m 0755 ${G_VENDOR_PATH}/recovery_resources/rc.local ${RECOVERYFS_BASE}/etc/
    install -m 0644 ${G_VENDOR_PATH}/recovery_resources/hostapd.conf ${RECOVERYFS_BASE}/etc/
    install -d -m 0755 ${RECOVERYFS_BASE}/boot
    install -m 0644 ${G_VENDOR_PATH}/splash.bmp ${RECOVERYFS_BASE}/boot/
    install -d -m 0755 ${RECOVERYFS_BASE}/usr/share/images/desktop-base
    install -m 0644 ${G_VENDOR_PATH}/wallpaper.png \
            ${RECOVERYFS_BASE}/usr/share/images/desktop-base/default

    # disable light-locker
    # install -m 0755 ${G_VENDOR_PATH}/recovery_resources/disable-lightlocker \
    #         ${RECOVERYFS_BASE}/usr/local/bin/
    # install -m 0644 ${G_VENDOR_PATH}/recovery_resources/disable-lightlocker.desktop \
    #         ${RECOVERYFS_BASE}/etc/xdg/autostart/

    # Revert regular booting
    rm -f ${RECOVERYFS_BASE}/usr/sbin/policy-rc.d

    # install kernel modules in recoveryfs
    install_kernel_modules \
        ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} \
        ${G_LINUX_KERNEL_DEF_CONFIG} ${G_LINUX_KERNEL_SRC_DIR} \
        ${RECOVERYFS_BASE}

    # copy all kernel headers for development
    install -d -m 0755 ${RECOVERYFS_BASE}/usr/local/src/linux-imx/drivers/staging/android/uapi
    cp ${G_LINUX_KERNEL_SRC_DIR}/drivers/staging/android/uapi/* \
       ${RECOVERYFS_BASE}/usr/local/src/linux-imx/drivers/staging/android/uapi
    cp -r ${G_LINUX_KERNEL_SRC_DIR}/include \
       ${RECOVERYFS_BASE}/usr/local/src/linux-imx/

    # copy custom files
    install -m 0755 ${G_VENDOR_PATH}/${MACHINE}/kobs-ng ${RECOVERYFS_BASE}/usr/bin
    install -m 0755 ${PARAM_OUTPUT_DIR}/fw_printenv-mmc ${RECOVERYFS_BASE}/usr/bin
    # install -m 0755 ${PARAM_OUTPUT_DIR}/fw_printenv-nand ${RECOVERYFS_BASE}/usr/bin
    # ln -sf fw_printenv ${RECOVERYFS_BASE}/usr/bin/fw_printenv-nand
    # ln -sf fw_printenv ${RECOVERYFS_BASE}/usr/bin/fw_setenv
    ln -sf fw_printenv-mmc ${RECOVERYFS_BASE}/usr/bin/fw_printenv
    ln -sf fw_printenv ${RECOVERYFS_BASE}/usr/bin/fw_setenv
    install -m 0644 ${G_VENDOR_PATH}/${MACHINE}/fw_env.config ${RECOVERYFS_BASE}/etc

    ## clenup command
    cat > cleanup << EOF
#!/bin/bash
apt-get clean
rm -f cleanup
EOF

    # clean all packages
    pr_info "recoveryfs: clean"
    chmod +x cleanup
    chroot ${RECOVERYFS_BASE} /cleanup

    # kill latest dbus-daemon instance due to qemu-arm-static
    QEMU_PROC_ID=$(ps axf | grep dbus-daemon | grep qemu-arm-static | awk '{print $1}')
    if [ -n "$QEMU_PROC_ID" ]; then
        kill -9 $QEMU_PROC_ID
    fi

    rm ${RECOVERYFS_BASE}/usr/bin/qemu-arm-static


    # BEGIN -- REVO i.MX7D cleanup
    # Prepare /var/log to be mounted as tmpfs.
    # NB: *~ is excluded from recoveryfs tarball.
    mv ${RECOVERYFS_BASE}/var/log{,~}
    install -d -m 755 ${RECOVERYFS_BASE}/var/log
    # END -- REVO i.MX7D cleanup
}

# Must be called after make_debian_recoveryfs in main script
# function generate ubi recoveryfs in input dir
# $1 - recoveryfs ubifs base dir
prepare_recovery_ubifs_recoveryfs ()
{
    local UBIFS_RECOVERYFS_BASE=$1
    pr_info "Make debian(${DEB_RELEASE}) recoveryfs for UBIFS start..."

    # Below removals are to free space to fit in a NAND flash
    # Remove foreign man pages and locales
    rm -rf ${UBIFS_RECOVERYFS_BASE}/usr/share/man/??
    rm -rf ${UBIFS_RECOVERYFS_BASE}/usr/share/man/??_*
    rm -rf ${UBIFS_RECOVERYFS_BASE}/var/cache/man/??
    rm -rf ${UBIFS_RECOVERYFS_BASE}/var/cache/man/??_*
    (cd ${UBIFS_RECOVERYFS_BASE}/usr/share/locale; ls | grep -v en_[GU] | xargs rm -rf)

    # Remove document files
    rm -rf ${UBIFS_RECOVERYFS_BASE}/usr/share/doc

    # Remove deb package lists
    rm -rf ${UBIFS_RECOVERYFS_BASE}/var/lib/apt/lists/deb.*
}

# make bootable image for device
# $1 -- block device
# $2 -- output images dir
make_recovery_image ()
{
    local LPARAM_BLOCK_DEVICE=$1
    local LPARAM_OUTPUT_DIR=$2

    local P1_MOUNT_DIR="${G_TMP_DIR}/p1"
    local P2_MOUNT_DIR="${G_TMP_DIR}/p2"
    local DEBIAN_IMAGES_TO_RECOVERYFS_POINT="opt/images/Debian"

    local BOOTLOAD_RESERVE_SIZE=4
    local SPARE_SIZE=8
    local part=''

    format_device ()
    {
        pr_info "Formating device partitions"
        if ! mkfs.vfat "${LPARAM_BLOCK_DEVICE}${part}1" -n BOOT ||
                ! mkfs.ext4 "${LPARAM_BLOCK_DEVICE}${part}2" -L recoveryfs; then
            pr_error "Format did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi
    }

    flash_u-boot ()
    {
        pr_info "Flashing U-Boot"
        dd if="${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC}" \
           of="$LPARAM_BLOCK_DEVICE" bs=1K seek=1
        sync
        if ! dd if="${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC}" \
             of="$LPARAM_BLOCK_DEVICE" bs=1K seek=69; then
            pr_error "Flash did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi
    }

    flash_device ()
    {
        pr_info "Flashing \"BOOT\" partition"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/"*.dtb	"$P1_MOUNT_DIR"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${BUILD_IMAGE_TYPE}" "$P1_MOUNT_DIR"
        sync

        pr_info "Flashing \"recoveryfs\" partition"
        if ! tar -C "$P2_MOUNT_DIR" -xpf "${LPARAM_OUTPUT_DIR}/${DEF_RECOVERYFS_TARBALL_NAME}"; then
            pr_error "Flash did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi
    }

    copy_debian_images ()
    {
        mkdir -p "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"

        pr_info "Copying Debian images to /${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${BUILD_IMAGE_TYPE}" \
           "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        # if test ."$MACHINE" = .'imx6ul-var-dart' ||
        #        test ."$MACHINE" = .'var-som-mx7' ||
        #        test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        #     cp ${LPARAM_OUTPUT_DIR}/recoveryfs.ubi.img \
        #        ${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}/
        # fi
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBALL_NAME}" \
           "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"

        install -m 0644 "${LPARAM_OUTPUT_DIR}/"*.dtb \
           "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"

        # pr_info "Copying NAND U-Boot to /${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        # cp "${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_NAND}" \
        #    "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        # cp "${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_NAND}" \
        #    "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"

        pr_info "Copying MMC U-Boot to /${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC}" \
           "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC}" \
           "${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"

        return 0
    }

    copy_scripts ()
    {
        pr_info "Copying scripts to /${DEBIAN_IMAGES_TO_RECOVERYFS_POINT}"
        if test ."$MACHINE" = .'imx6ul-var-dart'  ||
               test ."$MACHINE" = .'var-som-mx7' ||
               test ."$MACHINE" = .'revo-roadrunner-mx7'; then
            install -m 0755 "${G_VENDOR_PATH}/recover_emmc.sh" \
               "${P2_MOUNT_DIR}/usr/sbin/flash_emmc"
        fi
    }

    if test ."$LPARAM_BLOCK_DEVICE" = .'na'; then
        LPARAM_BLOCK_DEVICE=$(sed -e 's/ .*//' <<<$(select_removable_device))
        if test ."$LPARAM_BLOCK_DEVICE" = .''; then
            pr_error "Device not available"
            exit 1
        fi
    fi

    if [[ ."$LPARAM_BLOCK_DEVICE" =~ \./dev/mmcblk ]] ||
       is_loop_device "$LPARAM_BLOCK_DEVICE"; then
        part="p"
    fi

    # Check that we're using a valid device
    if ! is_removable_device "$LPARAM_BLOCK_DEVICE"; then
        LPARAM_BLOCK_DEVICE=$(sed -e 's/ .*//' <<<$(select_removable_device))
        if test ."$LPARAM_BLOCK_DEVICE" = .''; then
            pr_error "Device not available"
            exit 1
        fi
    fi


    # Get total card size in blocks
    local total_size=$(blockdev --getsz "$LPARAM_BLOCK_DEVICE")
    local total_size_bytes=$(( total_size * 512 ))
    local total_size_gib=$(bc <<< "scale=1; ${total_size_bytes}/(1024*1024*1024)")

    # Convert to MB
    total_size=$(( total_size / 2048 ))
    local recoveryfs_offset=$(( BOOTLOAD_RESERVE_SIZE + SPARE_SIZE ))
    local recoveryfs_size=$(( total_size - recoveryfs_offset ))

    pr_info "Device: ${LPARAM_BLOCK_DEVICE}, ${total_size_gib}GiB"
    echo "============================================="
    read -p "Press Enter to continue"

    pr_info "Creating new partitions"
    pr_info "ROOT SIZE=$recoveryfs_size MiB, TOTAl SIZE=$total_size MiB"

    local part1_start="${BOOTLOAD_RESERVE_SIZE}MiB"
    local part1_size="${SPARE_SIZE}MiB"
    local part2_start="${recoveryfs_offset}MiB"

    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt "${LPARAM_BLOCK_DEVICE}${part}${i}")"; then
            umount "${LPARAM_BLOCK_DEVICE}${part}${i}"
        fi
        if test -e "${LPARAM_BLOCK_DEVICE}${part}${i}"; then
            wipefs -a "${LPARAM_BLOCK_DEVICE}${part}${i}"
        fi
    done
    wipefs -a "$LPARAM_BLOCK_DEVICE"

    dd if=/dev/zero of="$LPARAM_BLOCK_DEVICE" bs=1M count="$recoveryfs_offset"
    sleep 2
    sync

    flock "$LPARAM_BLOCK_DEVICE" sfdisk "$LPARAM_BLOCK_DEVICE" >/dev/null 2>&1 << EOF
$part1_start,$part1_size,c
$part2_start,-,L
EOF

    partprobe "$LPARAM_BLOCK_DEVICE"
    sleep 2
    sync

    # Format the partitions
    format_device || return 1
    sleep 2
    sync

    flash_u-boot || return 1
    sleep 2
    sync

    # Mount the partitions
    mkdir -p "$P1_MOUNT_DIR"
    mkdir -p "$P2_MOUNT_DIR"
    sync

    mount "${LPARAM_BLOCK_DEVICE}${part}1"  "$P1_MOUNT_DIR"
    mount "${LPARAM_BLOCK_DEVICE}${part}2"  "$P2_MOUNT_DIR"
    sleep 2
    sync

    flash_device || return 1
    copy_debian_images
    copy_scripts

    pr_info "Sync device..."
    sync
    umount "$P1_MOUNT_DIR"
    umount "$P2_MOUNT_DIR"

    rm -rf "$P1_MOUNT_DIR"
    rm -rf "$P2_MOUNT_DIR"

    pr_info "Done make bootable image!"
}
