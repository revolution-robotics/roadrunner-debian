#!/usr/bin/env bash
#
# Must be called after make_prepare in main script
# function generate recoveryfs in input dir
# $1 - recoveryfs base dir
make_debian_recoveryfs ()
{
    local RECOVERYFS_BASE=$1

    remove-charmaps ()
    {
        # Remove non-essential charmaps from /usr/share/i18n/charmaps
        local charmap quoted
        local -a find_args=()
        local -a charmaps=(
            $(tr -s ' ' '\n' <<<"$LOCALES UTF-8 ISO-8859-1" |
                  sed -e 's/.*\.//' |
                  sort -u)
        )
        for charmap in "${charmaps[@]}"; do
            printf -v quoted "%q.gz" "$charmap";

            if (( ${#find_args[*]} == 0 )); then
                find_args=( -name "$quoted" )
            else
                find_args+=( -or -name "$quoted" )
            fi
        done
        eval find "${RECOVERYFS_BASE}/usr/share/i18n/charmaps" -type f \
             ${find_args[0]:+"-not \\( ${find_args[@]} \\)"} -delete
    }

    remove-locales ()
    {
        # Remove non-essential charmaps from /usr/share/i18n/locales
        local charmap quoted
        local -a find_args=()
        local -a locales=(
            $(tr -s ' ' '\n' <<<"$LOCALES" |
                  sed -n -e 's/\..*//' -e '/_/p' -e 's/_.*//p')
        )
        local locale

        locales+=( C POSIX )
        for locale in "${locales[@]}"; do
            printf -v quoted "%q" "$locale";

            if (( ${#find_args[*]} == 0 )); then
                find_args=( -name "$quoted" )

                # If keeping, e.g., `en_IE', also keep `en_IE@euro'.
                if [[ ."$quoted" =~ \.[^_]+_[^@]+$ ]]; then
                    find_args+=( -or -name "${quoted}@*" )
                fi
            else
                find_args+=( -or -name "$quoted" )

                # If keeping, e.g., `en_IE', also keep `en_IE@euro'.
                if [[ ."$quoted" =~ \.[^_]+_[^@]+$ ]]; then
                    find_args+=( -or -name "${quoted}@*" )
                fi
            fi
        done
        eval find "${RECOVERYFS_BASE}/usr/share/i18n/locales" -type f \
             ${find_args[0]:+"-not \\( ${find_args[@]} \\)"} -delete
    }

    umount-fs ()
    {
        local fs_base=$1

        umount -f "${fs_base}"/{sys,proc,dev/pts} 2>/dev/null || true
        umount -f "${fs_base}/dev" 2>/dev/null || true
    }

    mount-fs ()
    {
        local fs_base=$1

        install -d -m 0755 -o root -g root "${fs_base}"
        install -d -m 0555 -o root -g root "${fs_base}"/{dev,proc,sys}
        install -d -m 0755 -o root -g root "${fs_base}/dev/pts"

        if ! findmnt ${fs_base}/proc >/dev/null; then
            mount -t proc /proc ${fs_base}/proc
        fi

        for fs in /sys /dev /dev/pts; do
            if ! findmnt "${fs_base}/${fs}" >/dev/null; then
                mount -o bind "$fs" "${fs_base}${fs}"
            fi
        done
    }

    pr_info "recoveryfs: Begin Debian(${DEB_RELEASE}) filesystem..."

    ## umount previus mounts (if fail)
    umount-fs "${RECOVERYFS_BASE}"

    ## clear recoveryfs dir
    rm -rf "${RECOVERYFS_BASE}"

    pr_info "recoveryfs: First stage debootstrap"

    mount-fs "$RECOVERYFS_BASE"

    trap 'umount-fs "$RECOVERYFS_BASE"; exit 1' 0 1 2 15

    debootstrap --variant=minbase --verbose  --foreign --arch armhf \
                --keyring="/usr/share/keyrings/debian-${DEB_RELEASE}-release.gpg" \
                "${DEB_RELEASE}" "${RECOVERYFS_BASE}/" "${PARAM_DEB_LOCAL_MIRROR}"

    umount-fs "$RECOVERYFS_BASE"

    trap - 0 1 2 15

    ## Install /etc/passwd, et al.
    install -m 0644 "${G_VENDOR_PATH}/resources/etc"/{passwd,group} \
            "${RECOVERYFS_BASE}/etc"
    install -m 0640 -g shadow "${G_VENDOR_PATH}/resources/etc/shadow" \
            "${RECOVERYFS_BASE}/etc"

    ## Prepare qemu.
    install -m 0755 "${G_VENDOR_PATH}/qemu_32bit/qemu-arm-static" \
            "${RECOVERYFS_BASE}/usr/bin"

    trap 'umount-fs "$RECOVERYFS_BASE"; exit' 0 1 2 15

    if test ! -f "${RECOVERYFS_BASE}/debootstrap/mirror"; then
        echo "${PARAM_DEB_LOCAL_MIRROR}" > "${RECOVERYFS_BASE}/debootstrap/mirror"
    fi

    pr_info "recoveryfs: Second stage debootstrap"
    $CHROOTFS "$RECOVERYFS_BASE" /debootstrap/debootstrap --verbose \
              --second-stage

    ## Delete unused folder.
    $CHROOTFS "$RECOVERYFS_BASE" rm -rf  "${RECOVERYFS_BASE}/debootstrap"

    # pr_info "recoveryfs: Generate default configs"
    # install -d -m 0750 ${RECOVERYFS_BASE}/etc/sudoers.d/
    # echo "user ALL=(root) /usr/bin/apt, /usr/bin/apt-get, /usr/bin/dpkg, /sbin/reboot, /sbin/shutdown, /sbin/halt" > ${RECOVERYFS_BASE}/etc/sudoers.d/user
    # chmod 0440 ${RECOVERYFS_BASE}/etc/sudoers.d/user

    ## install local Debian packages
    install -d -m 0755 "${RECOVERYFS_BASE}/srv/local-apt-repository"

    ## udisk2
    # cp -r "${G_VENDOR_PATH}/deb/udisks2"/* \
    #    "${RECOVERYFS_BASE}/srv/local-apt-repository"

    ## gstreamer-imx
    # cp -r ${G_VENDOR_PATH}/deb/gstreamer-imx/* \
    #    ${RECOVERYFS_BASE}/srv/local-apt-repository

    ## shared-mime-info
    # cp -r ${G_VENDOR_PATH}/deb/shared-mime-info/* \
    #    ${RECOVERYFS_BASE}/srv/local-apt-repository

    ## Unix line editor
    cp -r "${G_VENDOR_PATH}/deb/ed"/* \
       "${RECOVERYFS_BASE}/srv/local-apt-repository"

    install -d -m 0755 "${RECOVERYFS_BASE}/var/lib/usbmux"

    ## BEGIN -- REVO i.MX7D security
    # pr_info "recoveryfs: Install security infrastructure"

    # for pkg in firewalld iptables libcurl libedit libnftnl nftables; do
    #     install -m 0644 "${G_VENDOR_PATH}/deb/${pkg}"/*.deb \
    #        "${RECOVERYFS_BASE}/srv/local-apt-repository"
    # done
    ## END -- REVO i.MX7D security

    ## add mirror to source list
    cat >"${RECOVERYFS_BASE}/etc/apt/sources.list" <<EOF
deb ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE} main contrib non-free
deb ${PARAM_DEB_LOCAL_MIRROR%/}-security/ ${DEB_RELEASE}-security main contrib non-free
deb ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE}-updates main contrib non-free
deb ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
# deb-src ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE} main contrib non-free
# deb-src ${PARAM_DEB_LOCAL_MIRROR%/}-security/ ${DEB_RELEASE}-security main contrib non-free
# deb-src ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE}-updates main contrib non-free
# deb-src ${PARAM_DEB_LOCAL_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
EOF

    ## raise backports priority
#     cat >"${RECOVERYFS_BASE}/etc/apt/preferences.d/backports" <<EOF
# Package: *
# Pin: release n=${DEB_RELEASE}-backports
# Pin-Priority: 500
# EOF

    ## maximize local repo priority
#     cat >"${RECOVERYFS_BASE}/etc/apt/preferences.d/local" <<EOF
# Package: *
# Pin: origin ""
# Pin-Priority: 1000
# EOF

    cat >"${RECOVERYFS_BASE}/etc/fstab" <<EOF

# /dev/mmcblk0p1  /boot           vfat    defaults        0       0
EOF

    ## Unique hostname generated on boot (see below), but in the mean time,
    ## hostname needs to be resolvable, e.g., for `sudo'.
    hostname >"${RECOVERYFS_BASE}/etc/hostname"

    ## "127.0.1.1 $hostname"  added when hostname generated on boot
    cat >"${RECOVERYFS_BASE}/etc/hosts" <<EOF
127.0.0.1	localhost
127.0.1.1       $(hostname)

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

    cat >"${RECOVERYFS_BASE}/debconf.set" <<EOF
locales locales/locales_to_be_generated multiselect $LOCALES
locales locales/default_environment_locale select ${LOCALES%% *}
keyboard-configuration keyboard-configuration/variant select 'English (US)'
openssh-server openssh-server/permit-root-login select true
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC
EOF

    pr_info "recoveryfs: Prevent Debian from running systemctl"

    ## Run apt install without invoking daemons.
    cat >"${RECOVERYFS_BASE}/usr/sbin/policy-rc.d" <<EOF
#!/bin/bash
exit 101
EOF

    trap 'rm -f "${RECOVERYFS_BASE}/usr/sbin/policy-rc.d"; exit 1' 0 1 2 15

    chmod +x "${RECOVERYFS_BASE}/usr/sbin/policy-rc.d"

    ## third packages stage
    cat >"${RECOVERYFS_BASE}/third-stage" <<EOF
#!/bin/bash
# apply debconfig options
echo 'LANG=${LOCALES%% *}' >/etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
debconf-set-selections /debconf.set
rm -f /debconf.set

protected_install ()
{
    local _name=\${1}
    local repeated_cnt=5
    local RET_CODE=1

    for (( c=0; c < \${repeated_cnt}; c++ )); do
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \\
                       apt -y install \${_name} && {
            RET_CODE=0
            break
        }

        echo ""
        echo "###########################"
        echo "## Fix missing packeges ###"
        echo "###########################"
        echo ""

        sleep 2
        apt -y --fix-broken install && {
                RET_CODE=0
                break
        }
    done

    return \${RET_CODE}
}

# BEGIN -- REVO i.MX7D: additions
# silence some apt warnings
protected_install dialog

## Replace mawk with gawk.
protected_install gawk
apt -y purge mawk

# END -- REVO i.MX7D: additions

## Host a local disk-based Debian repository...
protected_install local-apt-repository

## To host a private web-based Debian repository...
# protected_install reprepro
# reprepro rereference

## Update packages and install base.
apt update
apt -y full-upgrade

## Downgrade libcurl3-gnutls from 7.74.0-1.2~bpo10+1 to 7.64.0-4+deb10u2.
# apt install libcurl3-gnutls=7.64.0-4+deb10u2 <<<'y'

## Freeze libcurl3-gnutls version.
# dpkg --set-selections <<<'libcurl3-gnutls hold'

protected_install libcurl4

protected_install locales

## Use NTP-client only service, systemd-timesyncd.
# protected_install ntp

protected_install openssh-server

## NFS is huge, so don't install by default.
# protected_install nfs-common

## Packages required when flashing eMMC...
protected_install dosfstools

## Fix config for sshd (permit root login).
sed -i -e 's/^#* *\\(PermitRootLogin\\).*/\\1\tyes/g' /etc/ssh/sshd_config

## Hardware-based random-number generation daemon.
protected_install rng-tools

## udisk2
protected_install udisks2

## gvfs
# protected_install gvfs

## gvfs-daemons
# protected_install gvfs-daemons

## Legacy network tools (ifconfig, etc.)
# protected_install net-tools

## Enable graphical desktop.
# protected_install xorg
# protected_install xfce4
# protected_install xfce4-goodies

## Network Manager.
# protected_install network-manager-gnome

## Unix line editor
protected_install ed

## Fix lightdm config (added autologin x_user).
# sed -i -e 's/^#* *\\(autologin-user=\\)/\\1x_user/g' \\
#     -e 's/^#* *\\(autologin-user-timeout=0\\)/\\1/g' \\
#     /etc/lightdm/lightdm.conf

## Enable remote login to via XDMCP.
if test -f /etc/lightdm/lightdm.conf; then
   ed -s /etc/lightdm/lightdm.conf <<'EOT'
/^#* *\\(start-default-seat=\\).*/s//\\1false/
/^#* *\\(greeter-user=\\).*/s//\\1lightdm/
/^#* *\\(xserver-allow-tcp=\\).*/s//\\1true/
/^\\[XDMCPServer\\]/;+1,+2c
enabled=true
port=177
.
wq
EOT
fi

## lightdm-gtk-greeter wants to launch at-spi-bus-launcher via an old path
# install -d -m 0755 /usr/lib/at-spi2-core/
# ln -sf /usr/libexec/at-spi-bus-launcher /usr/lib/at-spi2-core/

# Create missing data directory.
# install -d -m 0755 /var/lib/lightdm/data

## Add ALSA & ALSA utilites.
# protected_install alsa-utils
# protected_install gstreamer1.0-alsa

# protected_install gstreamer1.0-plugins-bad
# protected_install gstreamer1.0-plugins-base
# protected_install gstreamer1.0-plugins-good
# protected_install gstreamer1.0-plugins-ugly
# protected_install gstreamer1.0-tools

## Add gstreamer-imx.
# protected_install gstreamer-imx

## Add libatomic1, pulled in gstreamer, but needed by Node.js.
protected_install libatomic1

## Add i2c tools.
protected_install i2c-tools

## Add usb tools.
protected_install usbutils

## Add network bandwidth metrics.
# protected_install iperf

## Add flash file system utilities.
# protected_install mtd-utils

## Add bluetooth support.
protected_install bluetooth
# protected_install bluez-obexd
# protected_install bluez-tools

# sed -i -e '/^ExecStart/s/\$/ --noplugin=sap/' \\
#      /lib/systemd/system/bluetooth.service

# protected_install blueman
# protected_install gconf2

## shared-mime-info
# protected_install shared-mime-info

## Add WiFi support packages.
# protected_install hostapd
# protected_install udhcpd

## Disable hostapd service by default.
# systemctl disable hostapd.service

## Add Controller Area Network (CAN) support.
protected_install can-utils

## Add power management utilities.
# protected_install pm-utils

# BEGIN -- REVO i.MX7D networking and security
protected_install chrony
protected_install nftables

## Remove entries from nftables.conf which might interfere with firewalld.
echo '#!/usr/sbin/nft -f' >/etc/nftables.conf

protected_install firewalld

# Switch firewalld backend to nftables.
sed -i -e '/^\(FirewallBackend=\).*\$/s//\1nftables/' \\
    /etc/firewalld/firewalld.conf

## ifupdown is superceded by NetworkManager...
apt -y purge ifupdown
rm -f /etc/network/interfaces

printf "\n\n" | DEBIAN_FRONTEND=noninteractive apt -y install network-manager

## iptables is superceded by nftables, but NetworkManager still depends
## on compatibility interface, iptables-nft, provided by iptables.
## See https://www.redhat.com/en/blog/using-iptables-nft-hybrid-linux-firewall.
# apt -y purge iptables

## iptables-persistent is superceded by firewalld.
# DEBIAN_FRONTEND=noninteractive apt -y install iptables-persistent
# rm -f /etc/iptables/rules.v[46]

## Defaults, starting with Debian buster:
# update-alternatives --set iptables /usr/sbin/iptables-nft
# update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
# update-alternatives --set arptables /usr/sbin/arptables-nft
# update-alternatives --set ebtables /usr/sbin/ebtables-nft
# END -- REVO i.MX7D networking

apt -y autoremove

# apt -y install --reinstall libgdk-pixbuf2.0-0

## Register GdkPixbuf loaders
# /usr/lib/arm-linux-gnueabihf/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders \\
#     --update-cache

## Create users and set password
echo "root:root" | chpasswd

# useradd -m -G audio,video -s /bin/bash user
# useradd -m -G audio,video -s /bin/bash x_user
# echo "user:user" | chpasswd
# passwd -d x_user

EOF

    if getent passwd revo >/dev/null; then
        cat >>"${RECOVERYFS_BASE}/third-stage" <<EOF
# BEGIN -- REVO i.MX7D users

groupadd -g $(id -g revo) revo
useradd -m -u $(id -u revo) -g $(id -g revo) -G audio,bluetooth,lp,pulse,pulse-access,video -s /bin/bash -c "REVO Roadrunner" revo
EOF
    else
        cat >>"${RECOVERYFS_BASE}/third-stage" <<EOF
# BEGIN -- REVO i.MX7D users

useradd -m -G audio,bluetooth,lp,pulse,pulse-access,video -s /bin/bash -c "REVO Roadrunner" revo
EOF
    fi

    if getent passwd step >/dev/null; then
        cat >>"${RECOVERYFS_BASE}/third-stage" <<EOF
groupadd -g $(id -g step) step
useradd -rm -u $(id -u step) -g $(id -g step) -s /bin/bash -c "Smallstep PKI" step

# END -- REVO i.MX7D users

rm -f /third-stage
EOF
    else
        cat >>"${RECOVERYFS_BASE}/third-stage" <<EOF
useradd -rm  -s /bin/bash -c "Smallstep PKI" step

# END -- REVO i.MX7D users

rm -f /third-stage
EOF
    fi

    pr_info "recoveryfs: Begin post-bootstrap package installation"
    chmod +x ${RECOVERYFS_BASE}/third-stage
    $CHROOTFS ${RECOVERYFS_BASE} /third-stage

    echo "revo ALL=(ALL:ALL) NOPASSWD: ALL" > ${RECOVERYFS_BASE}/etc/sudoers.d/revo
    chmod 0440 "${RECOVERYFS_BASE}/etc/sudoers.d/revo"

    ## Begin packages stage ##
    pr_info "recoveryfs: Install updates and local packages"

    ## BEGIN -- REVO i.MX7D updates

    ## Update logrotate
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/logrotate/logrotate.conf" \
            "${RECOVERYFS_BASE}/etc"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/logrotate/rsyslog" \
            "${RECOVERYFS_BASE}/etc/logrotate.d"

    ## Install REVO update-hostname script
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/update-hostname" \
            "${RECOVERYFS_BASE}/usr/sbin"

    ## Install REVO tls-generate-self-signed script
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/tls-generate-self-signed" \
            "${RECOVERYFS_BASE}/usr/sbin"

    ## Install REVO hostname-commit service to generate unique hostname
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/hostname-commit.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -d -m 0755 "${RECOVERYFS_BASE}/etc/systemd/system/network.target.wants"
    ln -sf '/lib/systemd/system/hostname-commit.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/network.target.wants"

    ## Install REVO commit-hostname script
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/commit-hostname" "${RECOVERYFS_BASE}/usr/sbin"

    ## Hostname and machine ID are removed in final cleanup.

    ## Exim mailname is updated when hostname generated
    # echo "$MACHINE" > "${RECOVERYFS_BASE}/etc/mailname"

    ## Regenerate SSH keys on first boot
    # install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/regenerate-ssh-host-keys.service" \
    #         "${RECOVERYFS_BASE}/lib/systemd/system"
    # ln -sf '/lib/systemd/system/regenerate-ssh-host-keys.service' \
    #    "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Support resizing a serial console - taken from Debian xterm package.
    if test ! -f "${RECOVERYFS_BASE}/usr/bin/resize"; then
        install -m 0755 ${G_VENDOR_PATH}/${MACHINE}/resize \
                ${RECOVERYFS_BASE}/usr/bin
    fi

    ## Set PATH and resize serial console window.
    install -m 0755 "${G_VENDOR_PATH}/resources/etc/bash.bashrc" \
            "${RECOVERYFS_BASE}/etc"
    install -m 0755 "${G_VENDOR_PATH}/resources/etc/profile" \
            "${RECOVERYFS_BASE}/etc"
    install -d -m 0755 "${RECOVERYFS_BASE}/etc/profile.d"
    install -m 0644 "${G_VENDOR_PATH}/resources/etc/profile.d/set_window_title.sh" \
            "${RECOVERYFS_BASE}/etc/profile.d"

    ## Allow memory overcommit (for Redis background saving)
    install -m 0644 "${G_VENDOR_PATH}/resources/etc/sysctl.d/99-memory" \
            "${RECOVERYFS_BASE}/etc/sysctl.d"

    install -m 0644 "${G_VENDOR_PATH}/resources/etc/"{motd,rc.local,hostapd.conf} \
            "${RECOVERYFS_BASE}/etc/"

    ## Build and install RS-485 mode configuration utility.
    make -C "${G_VENDOR_PATH}/resources/rs485" clean all
    install -m 0755 "${G_VENDOR_PATH}/resources/rs485/rs485" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Install and enable serial initialization systemd service
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/serial-init.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf '/lib/systemd/system/serial-init.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Install serial initialization default
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/etc/default/serial" \
            "${RECOVERYFS_BASE}/etc/default"

    ## Install front-end security utility for debsecan.
    install -m 0755 "${G_VENDOR_PATH}/resources/dpkg-security-updates" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Install utitlity to download Yandex shares.
    install -m 0755 "${G_VENDOR_PATH}/resources/fetch-yandex" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Install utitlity to download private GitHub content.
    install -m 0755 "${G_VENDOR_PATH}/resources/fetch-gh-content" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Mount /tmp, /var/tmp and /var/log on tmpfs.
    install -m 0644 "${RECOVERYFS_BASE}/usr/share/systemd/tmp.mount" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/var-"{log,tmp}.mount \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/var-log.conf" \
            "${RECOVERYFS_BASE}/usr/lib/tmpfiles.d"

    ## Install REVO U-Boot boot script.
    install -d -m 0755 "${RECOVERYFS_BASE}/usr/share/boot"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/u-boot/boot.sh" \
                "${RECOVERYFS_BASE}/usr/share/boot"

    ## Install support for /boot/cmdline.txt
    case "${ACCESS_CONTROL,,}" in
        apparmor)
            echo 'security=apparmor apparmor=1' \
                 >"${RECOVERYFS_BASE}/boot/cmdline.txt"
            ;;
        selinux)
            echo 'security=selinux selinux=1 enforcing=0' \
                 >"${RECOVERYFS_BASE}/boot/cmdline.txt"
            ;;
        unix|*)
            ;;
    esac
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/update-kernel-cmdline" \
            "${RECOVERYFS_BASE}/usr/sbin"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/kernel-cmdline".{path,service} \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf '/lib/systemd/system/kernel-cmdline.path' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Install REVO recover eMMC service.
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc" \
            "${RECOVERYFS_BASE}/usr/sbin"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/chrootfs" \
            "${RECOVERYFS_BASE}/usr/sbin"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    install -d -m 0755 "${RECOVERYFS_BASE}/lib/systemd/system/system-update.target.wants"
    ln -sf '../recover-emmc.service' \
       "${RECOVERYFS_BASE}/lib/systemd/system/system-update.target.wants"
    ln -sf "$G_IMAGES_DIR" "${RECOVERYFS_BASE}/system-update"

    ## Install REVO eMMC-recovery monitor service
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc-monitor" \
            "${RECOVERYFS_BASE}/usr/sbin"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/recover-emmc-monitor.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf '/lib/systemd/system/recover-emmc-monitor.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Enable NetworkManager dispatcher
    ln -sf '/lib/systemd/system/NetworkManager-dispatcher.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service"

    ## Fix NetworkManager dispatch permissions set by Git
    chmod -R g-w "${G_VENDOR_PATH}/resources/NetworkManager/"*
    chmod 750 "${G_VENDOR_PATH}/resources/NetworkManager/etc/NetworkManager/dispatcher.d/30-link-led"

    ## Install REVO NetworkManager scripts
    tar -C "${G_VENDOR_PATH}/resources/NetworkManager" -cf - . |
        tar -C "${RECOVERYFS_BASE}" -oxf -

    rm -f "${RECOVERYFS_BASE}/etc/NetworkManager/dispatcher.d/"*ifupdown

    ## Update NetworkManager udev rule.
    install -m 0644 "${G_VENDOR_PATH}/resources/udev/84-nm-drivers.rules" \
            "${RECOVERYFS_BASE}/usr/lib/udev/rules.d"

    ## Add REVO default firewalld configuration.
    install -m 0644 "${G_VENDOR_PATH}/resources/firewalld/revo-web-ui.xml" \
            "${RECOVERYFS_BASE}/etc/firewalld/services"
    install -m 0644 "${G_VENDOR_PATH}/resources/firewalld/public.xml" \
            "${RECOVERYFS_BASE}/etc/firewalld/zones"

    ## Add Random Number Generator daemon (rngd) service
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/rngd.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf '/lib/systemd/system/rngd.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Add Exim4 service
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/exim4.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"

    # ln -sf '/lib/systemd/system/exim4.service' \
    #    "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Disable Exim4 service
    rm -f "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/exim4.service"

    ## Update systemd dbus socket
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/dbus.socket" \
            "${RECOVERYFS_BASE}/lib/systemd/system"

    ## Add headless Xorg config
    # install -m 0644 "${G_VENDOR_PATH}/resources/10-headless.conf" \
    #         "${RECOVERYFS_BASE}/usr/share/X11/xorg.conf.d"

    ## Install MIME databases
    # tar -C "$RECOVERYFS_BASE" -Jxf "${G_VENDOR_PATH}/resources/mime.txz"

    ## Create /var/www/html. TODO: Add index.html.
    install -d -m 0755 "${RECOVERYFS_BASE}/var/www/html"

    # Add golang to PATH.
    if test -f /root/.asdf/asdf.sh; then
        source /root/.asdf/asdf.sh
    fi

    ## Build and install REVO web dispatch.
    make -C "${G_REVO_WEB_DISPATCH_SRC_DIR}" clean all
    install -m 0755 "${G_REVO_WEB_DISPATCH_SRC_DIR}/revo-web-dispatch" \
            "${RECOVERYFS_BASE}/usr/sbin"

    ## Install REVO web dispatch config
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/etc/default/web-dispatch" \
            "${RECOVERYFS_BASE}/etc/default"

    ## Install REVO web dispatch service
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-web-dispatch.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf '/lib/systemd/system/revo-web-dispatch.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Install redirect-web-ports.
    install -m 0755 "${G_VENDOR_PATH}/resources/redirect-web-ports" \
            "${RECOVERYFS_BASE}/usr/sbin"

    ## Build and install Smallstep CLI with asdf-vm golang.
    pr_info "recoveryfs: Install Smallstep"

    GOOS=linux GOARCH=$ARCH_ARGS GOARM=$ARCH_VERSION go \
               -C "${G_SMALLSTEP_CLI_SRC_DIR}/cmd/step" build -ldflags='-s -w'
    install -m 0755 "${G_SMALLSTEP_CLI_SRC_DIR}/cmd/step/step" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Build and install Smallstep CERTIFICATES.
    GOOS=linux GOARCH=$ARCH_ARGS GOARM=$ARCH_VERSION go \
               -C "${G_SMALLSTEP_CERTIFICATES_SRC_DIR}/cmd/step-ca" \
               build -ldflags='-s -w'
    install -m 0755 "${G_SMALLSTEP_CERTIFICATES_SRC_DIR}/cmd/step-ca/step-ca" \
            "${RECOVERYFS_BASE}/usr/bin"
    if command -v upx >/dev/null; then
        upx "${RECOVERYFS_BASE}/usr/bin/step-ca"
    fi

    ## END -- REVO i.MX7D update

    ## Build and install brcm_patchram_plus utility.
    make -C "${G_VENDOR_PATH}/resources/bluetooth" clean all
    install -m 0755 "${G_VENDOR_PATH}/resources/bluetooth/brcm_patchram_plus" \
            "${RECOVERYFS_BASE}/usr/bin"

    ## Install bluetooth service
    install -d -m 0755 "${RECOVERYFS_BASE}/etc/bluetooth"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/etc/bluetooth/revo-bluetooth.conf" \
            "${RECOVERYFS_BASE}/etc/bluetooth"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-bluetooth" \
            "${RECOVERYFS_BASE}/etc/bluetooth"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-bluetooth.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf /lib/systemd/system/revo-bluetooth.service \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Install BT audio and main config
    install -m 0644 "${G_VENDOR_PATH}/resources/bluez5/files/audio.conf" \
            "${RECOVERYFS_BASE}/etc/bluetooth/"
    install -m 0644 "${G_VENDOR_PATH}/resources/bluez5/files/main.conf" \
            "${RECOVERYFS_BASE}/etc/bluetooth/"

    ## Install obexd configuration
    install -m 0644 "${G_VENDOR_PATH}/resources/bluez5/files/obexd.conf" \
            "${RECOVERYFS_BASE}/etc/dbus-1/system.d"

    install -m 0644 "${G_VENDOR_PATH}/resources/bluez5/files/obex.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    # ln -sf /lib/systemd/system/obex.service \
    #    "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/obex.service"

    ## Disable obex service
    rm -f "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/obex.service"

    ## Install pulse audio configuration
    install -m 0644 "${G_VENDOR_PATH}/resources/pulseaudio/pulseaudio.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"

    # Mask pulseaudio and rtkit-daemon services - per
    # https://www.kernel.org/doc/Documentation/cgroup-v2.txt:
    #   WARNING: cgroup2 doesn't yet support control of realtime processes and
    #   the cpu controller can only be enabled when all RT processes are in
    #   the root cgroup.
    # In particular, container runtime, crun, requires:
    #   echo +cpu >/sys/fs/cgroup/cgroup.subtree_control
    # but fails with error "Invalid argument" when rtkit-daemon
    # makes pulseaudio a realtime process.

    # ln -sf "/lib/systemd/system/pulseaudio.service" \
    #    "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"
    rm -f "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/pulseaudio.service"
    rm -f "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/rtkit-daemon.service"
    rm -f "${RECOVERYFS_BASE}/lib/systemd/system/sound.target.wants"/*
    ln -s /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/rtkit-daemon.service"
    ln -s /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/pulseaudio.service"

    install -m 0644 "${G_VENDOR_PATH}/resources/pulseaudio/pulseaudio-bluetooth.conf" \
            "${RECOVERYFS_BASE}/etc/dbus-1/system.d"
    install -m 0644 "${G_VENDOR_PATH}/resources/pulseaudio/system.pa" \
            "${RECOVERYFS_BASE}/etc/pulse/"

    ## Add alsa default configs
    # install -m 0644 "${G_VENDOR_PATH}/resources/asound.state" \
    #         "${RECOVERYFS_BASE}/var/lib/alsa/"
    # install -m 0644 "${G_VENDOR_PATH}/resources/asound.conf" \
    #         "${RECOVERYFS_BASE}/etc/"

    ## Install WiFi service
    install -d "${RECOVERYFS_BASE}/etc/wifi"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/etc/wifi/blacklist.conf" \
            "${RECOVERYFS_BASE}/etc/wifi"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/etc/wifi/revo-wifi.conf" \
            "${RECOVERYFS_BASE}/etc/wifi"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-wifi-common.sh" \
            "${RECOVERYFS_BASE}/etc/wifi"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-wifi" \
            "${RECOVERYFS_BASE}/etc/wifi"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/revo-wifi.service" \
            "${RECOVERYFS_BASE}/lib/systemd/system"
    ln -sf /lib/systemd/system/revo-wifi.service \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants"

    ## Remove pm-utils default scripts and install WiFi / Bluetooth scripts
    rm -rf "${RECOVERYFS_BASE}/usr/lib/pm-utils/sleep.d/"
    rm -rf "${RECOVERYFS_BASE}/usr/lib/pm-utils/module.d/"
    rm -rf "${RECOVERYFS_BASE}/usr/lib/pm-utils/power.d/"
    install -d -m 0755 "${RECOVERYFS_BASE}/etc/pm/sleep.d"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/etc/pm/sleep.d/wifi.sh" \
            "${RECOVERYFS_BASE}/etc/pm/sleep.d/"
    install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/etc/pm/sleep.d/bluetooth.sh" \
            "${RECOVERYFS_BASE}/etc/pm/sleep.d"

    # Derive CA root certificate name from CA URL, e.g.,
    #     https://ca.revo.io:14727 -> RevoIO_Root_CA
    declare -a tld=( $(sed -E -e 's/^.*\.([^.]+)\.([^.]+):.*/\1 \2/' <<<"$CA_URL") )
    declare ca_root_cert=${tld[0]^}${tld[1]^^}_Root_CA.crt

    ## Bootstrap local certificate authority and install root certificate.
    # step ca bootstrap --ca-url "$CA_URL" --fingerprint "$CA_FINGERPRINT"
    install -d -m 0755 "${RECOVERYFS_BASE}/usr/local/share/ca-certificates"
    install -m 0644 ~/".step/certs/root_ca.crt" \
            "${RECOVERYFS_BASE}/usr/local/share/ca-certificates/${ca_root_cert}"

    ## Add missing CAcert root and class3 certificates.
    curl -sSLo  "${ROOTFS_BASE}/usr/local/share/ca-certificates/root.crt" \
         http://www.cacert.org/certs/root.crt
    curl -sSLo  "${ROOTFS_BASE}/usr/local/share/ca-certificates/class3.crt" \
         http://www.cacert.org/certs/class3.crt

    ## End packages stage ##
    if test ."${G_USER_MINIMAL_PACKAGES}" != .''; then

        pr_info "recoveryfs: Install user-requested packages:"
        pr_info "            \"${G_USER_MINIMAL_PACKAGES}\""

        cat >"${RECOVERYFS_BASE}/user-stage" <<EOF
#!/bin/bash
# update packages
apt update

# install all user packages from backports
DEBIAN_FRONTEND=noninteractive apt -yq -t ${DEB_RELEASE}-backports install ${G_USER_MINIMAL_PACKAGES}

pip3 install https://github.com/zeromq/pyre/archive/master.zip
pip3 install minimalmodbus
pip3 install pystemd
pip3 install pytz

update-ca-certificates

# Allow Python to load root CA certificate bundle.
ln -s /etc/ssl/certs/ca-certificates.crt /usr/lib/ssl/cert.pem

rm -f /user-stage
EOF

        chmod +x "${RECOVERYFS_BASE}/user-stage"
        LANG=C $CHROOTFS "$RECOVERYFS_BASE" /user-stage
    fi

    ## recoveryfs startup patches
    pr_info "recoveryfs: Adjust start-up scripts and configuration"

    ## Mount systemd journal on tmpfs, /run/log/journal.
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/systemd/journald.conf" \
            "${RECOVERYFS_BASE}/etc/systemd"

    install -d -m 0755 "${RECOVERYFS_BASE}/boot"
    install -m 0644 "${G_VENDOR_PATH}/splash.bmp" "${RECOVERYFS_BASE}/boot/"
    install -d -m 0755 "${RECOVERYFS_BASE}/usr/share/images/desktop-base"
    install -m 0644 "${G_VENDOR_PATH}/wallpaper.png" \
            "${RECOVERYFS_BASE}/usr/share/images/desktop-base/default"

    ## Disable LightDM session locking
    # install -m 0755 "${G_VENDOR_PATH}/resources/disable-lightlocker" \
    #         "${RECOVERYFS_BASE}/usr/local/bin/"
    # install -m 0644 "${G_VENDOR_PATH}/resources/disable-lightlocker.desktop" \
    #         "${RECOVERYFS_BASE}/etc/xdg/autostart/"

    ## Redirect all system mail user `revo'.
    if test -f "${RECOVERYFS_BASE}/etc/aliases"; then
        sed -i "\$a root: revo" "${RECOVERYFS_BASE}/etc/aliases"
    fi

    ## Remove /etc/init.d/rng-tools (started by rngd.service)
    rm -f "${RECOVERYFS_BASE}/etc/init.d/rng-tools"

    ## Disable ssh.service (ssh.socket listens on port 22 instead).
    rm -f "${ROOTFS_BASE}/etc/systemd/system/sshd.service" \
       "${ROOTFS_BASE}/etc/systemd/system/multi-user.target.wants/ssh.service"

    ## Configure /etc/default/zramswap
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/zramswap" \
            "${RECOVERYFS_BASE}/etc/default"

    ## Enable zramswap service
    ln -sf '/lib/systemd/system/zramswap.service' \
       "${RECOVERYFS_BASE}/etc/systemd/system/multi-user.target.wants/"

    ## Enable sysstat data collection
    # sed -i -e 's;^\(ENABLED=\).*;\1"true";' "${RECOVERYFS_BASE}/etc/default/sysstat"

    # if test -d "${RECOVERYFS_BASE}/usr/lib/pcp/bin"; then

    #     ## Keep 12 hours of pmlogger logs.
    #     install -m 0755 "${G_VENDOR_PATH}/resources/pmlogger_rotate" \
    #             "${RECOVERYFS_BASE}/usr/lib/pcp/bin"
    #     printf "30 */6\t* * *\troot\t/usr/lib/pcp/bin/pmlogger_rotate" \
    #            >>"${RECOVERYFS_BASE}/etc/crontab"
    # fi

    ## Mask e2scrub_{all,reap} services.
    ln -sf /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/e2scrub_all.timer"
    ln -sf /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/e2scrub_all.service"
    ln -sf /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/e2scrub_reap.service"

    ## Disable systemd-networkd-wait-online service.
    rm -f "${RECOVERYFS_BASE}/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service"
    ln -sf /dev/null "${RECOVERYFS_BASE}/etc/systemd/system/systemd-networkd-wait-online.service"

    ## Fix network connectivity check
    sed -i -e '$s;.*;uri=http://connectivity-check.ubuntu.com./;' \
        "${RECOVERYFS_BASE}/usr/lib/NetworkManager/conf.d/20-connectivity.conf"

    ## Allow non-root users to run ping.
    echo 'net.ipv4.ping_group_range = 0 2147483647' >"${RECOVERYFS_BASE}/etc/sysctl.d/99-ping.conf"

    ## Enable colorized `ls' and alias h='history 50' for `root'.
    sed -i -e '/export LS/s/^# *//' \
        -e '/eval.*dircolors/s/^# *//' \
        -e '/alias ls/s/^# *//' \
        -e '/alias l=/a alias h="history 50"' \
        "${RECOVERYFS_BASE}/root/.bashrc"

    ## Installing kernel modules to recoveryfs is redundant. This is
    ## already done by cmd_make_kmodules.

    # pr_info "recoveryfs: Install kernel modules"

    # install_kernel_modules \
    #     "${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}" \
    #     "${G_LINUX_KERNEL_DEF_CONFIG}" "${G_LINUX_KERNEL_SRC_DIR}" \
    #     "${RECOVERYFS_BASE}"


    ## Install kernel headers to rootfs
    # install -d -m 0755 "${RECOVERYFS_BASE}/usr/local/src/linux-imx/drivers/staging/android/uapi"
    # cp "${G_LINUX_KERNEL_SRC_DIR}/drivers/staging/android/uapi/"* \
    #    "${RECOVERYFS_BASE}/usr/local/src/linux-imx/drivers/staging/android/uapi"
    # cp -r "${G_LINUX_KERNEL_SRC_DIR}/include" \
    #    "${RECOVERYFS_BASE}/usr/local/src/linux-imx/"

    ## Install U-Boot environment editor
    pr_info "recoveryfs: Install U-Boot environment editor"

    install -m 0755 "${PARAM_OUTPUT_DIR}/fw_printenv-mmc" \
            "${RECOVERYFS_BASE}/usr/bin"
    ln -sf 'fw_printenv-mmc' "${RECOVERYFS_BASE}/usr/bin/fw_printenv"
    ln -sf 'fw_printenv' "${RECOVERYFS_BASE}/usr/bin/fw_setenv"
    install -m 0644 "${G_VENDOR_PATH}/${MACHINE}/fw_env.config" \
            "${RECOVERYFS_BASE}/etc"

    # install -m 0755 "${G_VENDOR_PATH}/${MACHINE}/kobs-ng" \
    #         "${RECOVERYFS_BASE}/usr/bin"
    # install -m 0755 "${PARAM_OUTPUT_DIR}/fw_printenv-nand" \
    #         "${RECOVERYFS_BASE}/usr/bin"
    # ln -sf 'fw_printenv' "${RECOVERYFS_BASE}/usr/bin/fw_printenv-nand"

    # if test -f "${RECOVERYFS_BASE}/etc/pcp/pmlogger/control.d/local"; then

    #     ## Restrict pmlogger volume size
    #     sed -i -e 's/[0-9]\{1,\}Mb/20Mb/' \
    #         "${RECOVERYFS_BASE}/etc/pcp/pmlogger/control.d/local"
    # fi

    ## BEGIN -- REVO i.MX7D post-packages stage
    pr_info "recoveryfs: Begin late package installation"

    ## Run curl with system root certificates file.
    # mv "${RECOVERYFS_BASE}/usr/bin/curl"{,.dist}
    # install -m 755 "${G_VENDOR_PATH}/resources/curl/curl" \
    #         "${RECOVERYFS_BASE}/usr/bin/curl"

    ## Install nodejs/reverse-tunnel-server installation script.
    install -m 0755 "${G_VENDOR_PATH}/resources/reverse-tunnel-server/install-reverse-tunnel-server" \
            "${RECOVERYFS_BASE}/usr/bin/install-reverse-tunnel-server"

    ## post-packages command
    cat >"${RECOVERYFS_BASE}/post-packages" <<EOF
#!/bin/bash

## Install reverse-tunnel-server
install-reverse-tunnel-server "$NODE_USER" "$NODE_BASE"

## Remove non-default locales.
DEBIAN_FRONTEND=noninteractive apt -y install localepurge
sed -i -e 's/^USE_DPKG/#USE_DPKG/' /etc/locale.nopurge
localepurge

## XXX: Why is 'linux-image*' installed???
apt -y purge 'linux-image*' initramfs-tools{,-core} \\
    cryptsetup cryptsetup-bin cryptsetup-initramfs cryptsetup-run \\
    dmeventd dmraid dracut dracut-core lvm2 mdadm \\
    thin-provisioning-tools

apt -y purge build-essential g++-10 gcc-10 libx11-6 manpages{,-dev}
apt -y autoremove --purge

# apt -y install apparmor-profiles-extra
apt -y install apparmor{,-utils,-profiles}

# Set apparamor profiles to complain mode by default.
find /etc/apparmor.d -maxdepth 1 -type f -exec aa-complain {} \\; 2>/dev/null

apt clean

rm -f /post-packages
EOF
    pr_info "recoveryfs: Install reverse-tunnel server"

    chmod +x "${RECOVERYFS_BASE}/post-packages"
    $CHROOTFS "$RECOVERYFS_BASE" /post-packages
    ## END -- REVO i.MX7D post-packages stage

    ## BEGIN -- REVO i.MX7D cleanup
    pr_info "recoveryfs: Begin final cleanup"

    remove-charmaps
    remove-locales
    rm -rf "${RECOVERYFS_BASE}/usr/share/doc/"*
    rm -rf "${RECOVERYFS_BASE}/var/lib/apt/lists/"*

    ## Restore APT source list to default Debian mirror.
    cat >"${RECOVERYFS_BASE}/etc/apt/sources.list" <<EOF
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE} main contrib non-free
deb ${DEF_DEBIAN_MIRROR%/}-security/ ${DEB_RELEASE}-security main contrib non-free
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-updates main contrib non-free
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
# deb-src ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE} main contrib non-free
# deb-src ${DEF_DEBIAN_MIRROR%/}-security/ ${DEB_RELEASE}-security main contrib non-free
# deb-src ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-updates main contrib non-free
# deb-src ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
EOF

    pr_info "rootfs: Allow Debian to run systemctl"

    rm -f "${RECOVERYFS_BASE}/usr/sbin/policy-rc.d"

    trap - 0 1 2 15

    ## Limit kernel messages to the console.
    sed -i -e '/^#* *kernel.printk/s/^#* *//' "${RECOVERYFS_BASE}/etc/sysctl.conf"

    ## Remove misc. artifacts.
    find "${RECOVERYFS_BASE}/usr/local/include" -name ..install.cmd -delete
    find "${RECOVERYFS_BASE}/usr/local/include" -name .install -delete

    ## Prepare /var/log to be mounted as tmpfs.
    ## NB: *~ is excluded from recoveryfs tarball.
    rm -rf "${RECOVERYFS_BASE}/var/log"
    install -d -m 755 "${RECOVERYFS_BASE}/var/log"

    ## Remove machine ID and hostname to force generation of unique ones
    rm -f "${RECOVERYFS_BASE}/etc/machine-id" \
       "${RECOVERYFS_BASE}/var/lib/dbus/machine-id" \
       "${RECOVERYFS_BASE}/etc/hostname"
    sed -i -e '/^127.0.1.1/d' "${RECOVERYFS_BASE}/etc/hosts"

    ## kill latest dbus-daemon instance due to qemu-arm-static
    QEMU_PROC_ID=$(ps axf | grep dbus-daemon | grep qemu-arm-static | awk '{print $1}')
    if test -n "$QEMU_PROC_ID"; then
        kill -9 "$QEMU_PROC_ID"
    fi

    rm -f "${RECOVERYFS_BASE}/usr/bin/qemu-arm-static"
    ## END -- REVO i.MX7D cleanup
}

# Must be called after make_debian_recoveryfs in main script
# function generate ubi recoveryfs in input dir
# $1 - recoveryfs ubifs base dir
prepare_recovery_ubifs_recoveryfs ()
{
    local UBIFS_RECOVERYFS_BASE=$1
    pr_info "UBI recoveryfs: Begin Debian(${DEB_RELEASE}) filesystem..."

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
# $3 -- recoveryfs tarball
make_recovery_image ()
{
    local LPARAM_BLOCK_DEVICE=$1
    local LPARAM_OUTPUT_DIR=$2
    local LPARAM_TARBALL=$3

    local P1_MOUNT_DIR=${G_TMP_DIR}/p1
    local P2_MOUNT_DIR=${G_TMP_DIR}/p2

    local BOOTLOAD_RESERVE_SIZE=4
    local SPARE_SIZE=12
    local part=''

    format_device ()
    {
        pr_info "Formating device partitions"
        if ! mkfs.vfat -n BOOT "${LPARAM_BLOCK_DEVICE}${part}1" >/dev/null 2>&1; then
            pr_error "Format did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        elif ! mkfs.ext4 -L recoveryfs "${LPARAM_BLOCK_DEVICE}${part}2" >/dev/null 2>&1; then
            pr_error "Format did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi
    }

    flash_device ()
    {
        local cmdline

        pr_info "Flashing \"${LPARAM_TARBALL%%.*}\" partition"
        # if ! tar -C "$P2_MOUNT_DIR" -zxpf "${LPARAM_OUTPUT_DIR}/${LPARAM_TARBALL}"; then
        if ! $ZCAT "${LPARAM_OUTPUT_DIR}/${LPARAM_TARBALL}" | tar -C "$P2_MOUNT_DIR" -xpf -; then
            pr_error "Flash did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi

        if test -f "${P2_MOUNT_DIR}/boot/cmdline.txt"; then

            pr_info "Building U-Boot script"
            cmdline=$(
                sed -n -e '/^[[:space:]]*#/d' \
                    -e '/^[[:space:]]*$/d' \
                    -e '/[[:alnum:]]/{s/^[[:space:]]*//;p;q}' \
                    "$P2_MOUNT_DIR/boot/cmdline.txt"
                   )
            if test ."$cmdline" != .''; then
                pr_info "Kernel args from: ${P2_MOUNT_DIR}/boot/cmdline.txt: $cmdline"
                sed -e "/^setenv kernelargs/s;\$; ${cmdline};" \
                    "${P2_MOUNT_DIR}/usr/share/boot/boot.sh" >"${G_TMP_DIR}/boot.sh"
            else
                cp "${P2_MOUNT_DIR}/usr/share/boot/boot.sh" \
                   "${G_TMP_DIR}/boot.sh"
            fi
            make -C "$G_TMP_DIR" -f "${P2_MOUNT_DIR}/usr/share/boot/Makefile" \
                 clean all
        fi

        pr_info "Flashing \"BOOT\" partition"
        if test -f "${G_TMP_DIR}/boot.scr"; then
            pr_info "Installing new boot script"
            install -m 0644 "${G_TMP_DIR}/boot.scr" "$P1_MOUNT_DIR"
        elif test -f "${LPARAM_OUTPUT_DIR}/${UBOOT_SCRIPT}"; then
            install -m 0644 "${LPARAM_OUTPUT_DIR}/${UBOOT_SCRIPT}" \
                    "$P1_MOUNT_DIR"
        fi
        install -m 0644 "${LPARAM_OUTPUT_DIR}/"*.dtb	"$P1_MOUNT_DIR"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${BUILD_IMAGE_TYPE}" \
                "$P1_MOUNT_DIR"
        sync
    }

    copy_debian_images ()
    {
        install -d -m 0750 "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"

        pr_info "Copying Debian images to /${G_IMAGES_DIR}"
        if test -f "${G_TMP_DIR}/boot.scr"; then
            install -m 0644 "${G_TMP_DIR}/boot.scr" \
                    "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        elif test -f "${LPARAM_OUTPUT_DIR}/${UBOOT_SCRIPT}"; then
            install -m 0644 "${LPARAM_OUTPUT_DIR}/${UBOOT_SCRIPT}" \
                    "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        fi
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${BUILD_IMAGE_TYPE}" \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        # if test ."$MACHINE" = .'imx6ul-var-dart' ||
        #        test ."$MACHINE" = .'var-som-mx7' ||
        #        test ."$MACHINE" = .'revo-roadrunner-mx7'; then
        #     install -m 0644 ${LPARAM_OUTPUT_DIR}/recoveryfs.ubi.img \
        #        ${P2_MOUNT_DIR}/${G_IMAGES_DIR}/
        # fi
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBALL_NAME}" \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${DEF_RECOVERYFS_TARBALL_NAME}" \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/"*.dtb \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"

        # pr_info "Copying NAND U-Boot to /${G_IMAGES_DIR}"
        # install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_NAND}" \
        #    "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        # install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_NAND}" \
        #    "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"

        pr_info "Copying MMC U-Boot to /${G_IMAGES_DIR}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC}" \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"
        install -m 0644 "${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC}" \
                "${P2_MOUNT_DIR}/${G_IMAGES_DIR}"

        return 0
    }

    flash_u-boot ()
    {
        pr_info "Flashing U-Boot"
        if ! dd if="${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC}" \
             of="$LPARAM_BLOCK_DEVICE" bs=1K seek=1 >/dev/null 2>&1; then
            pr_error "Flash did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
        fi
        sync
        if ! dd if="${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC}" \
             of="$LPARAM_BLOCK_DEVICE" bs=1K seek=69 >/dev/null 2>&1; then
            pr_error "Flash did not complete successfully."
            echo "*** Please check media and try again! ***"
            return 1
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
    local total_size_gib=$(perl -e "printf '%.1f', $total_size_bytes / 1024 ** 3")

    # Convert to MB
    total_size=$(( total_size / 2048 ))
    local recoveryfs_offset=$(( BOOTLOAD_RESERVE_SIZE + SPARE_SIZE ))
    local recoveryfs_size=$(( total_size - recoveryfs_offset ))

    pr_info "Device: ${LPARAM_BLOCK_DEVICE}, ${total_size_gib} GiB"
    echo "============================================="
    read -p "Press Enter to continue"

    pr_info "Creating new partitions"
    pr_info "ROOT SIZE=$recoveryfs_size MiB, TOTAl SIZE=$total_size MiB"

    local part1_start="${BOOTLOAD_RESERVE_SIZE}MiB"
    local part1_size="${SPARE_SIZE}MiB"
    local part2_start="${recoveryfs_offset}MiB"

    for (( i=0; i < 10; i++ )); do
        if test -n "$(findmnt -n "${LPARAM_BLOCK_DEVICE}${part}${i}")"; then
            umount "${LPARAM_BLOCK_DEVICE}${part}${i}"
        fi
        if test -b "${LPARAM_BLOCK_DEVICE}${part}${i}"; then
            tune2fs -L '' "${LPARAM_BLOCK_DEVICE}${part}${i}" >/dev/null 2>&1 || true
            wipefs -a "${LPARAM_BLOCK_DEVICE}${part}${i}" >/dev/null 2>&1
        fi
    done
    wipefs -a "$LPARAM_BLOCK_DEVICE" >/dev/null 2>&1

    if ! dd if=/dev/zero of="$LPARAM_BLOCK_DEVICE" bs=1M count="$recoveryfs_offset" >/dev/null 2>&1; then
        pr_error "Flash did not complete successfully."
        echo "*** Please check media and try again! ***"
        return 1
    fi
    sleep 2
    sync

    flock "$LPARAM_BLOCK_DEVICE" sfdisk --wipe=always "$LPARAM_BLOCK_DEVICE" >/dev/null 2>&1 <<EOF
$part1_start,$part1_size,c
$part2_start,-,L
EOF

    # blockdev --rereadpt "$LPARAM_BLOCK_DEVICE"
    partprobe "$LPARAM_BLOCK_DEVICE"
    sleep 2
    sync

    # Format the partitions
    format_device || return 1
    sleep 2
    sync

    # Mount the partitions
    mkdir -p "$P1_MOUNT_DIR"
    mkdir -p "$P2_MOUNT_DIR"
    sync

    mount -t vfat "${LPARAM_BLOCK_DEVICE}${part}1"  "$P1_MOUNT_DIR" >/dev/null 2>&1 || return 1
    mount -t ext4 "${LPARAM_BLOCK_DEVICE}${part}2"  "$P2_MOUNT_DIR" >/dev/null 2>&1 || return 1
    sleep 2
    sync

    flash_device || return 1
    copy_debian_images

    flash_u-boot || return 1

    pr_info "Sync device..."
    sleep 2
    sync
    umount "$P1_MOUNT_DIR"
    umount "$P2_MOUNT_DIR"

    rm -rf "$P1_MOUNT_DIR"
    rm -rf "$P2_MOUNT_DIR"

    pr_info "Make bootable image completed successfully"
}
