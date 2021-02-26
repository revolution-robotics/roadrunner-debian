#!/usr/bin/env bash
#
# @(#) alt-recoveryfs.sh
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
declare -r G_VENDOR_PATH=${ABSOLUTE_FILENAME%/*}
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
    local rootfs=$2
    local purge_lists=$3

    echo "tar -C $rootfs -cf - . |"
    echo "    tar -C $fs -xpf -"
    rm -rf "$fs"
    install -d -m 0755 "$fs"
    tar -C "$rootfs" -cf - . |
        tar -C "$fs" -xpf -
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
    # declare rootfs=${PWD}/rootfs
    # declare recoveryfs=${PWD}/recoveryfs
    # declare newfs=${PWD}/newfs
    declare rootfs=$1
    declare newfs=$2

    if test ."$USER" != .'root'; then
        echo "$script_name: Run as user root"
        exit
    fi

    # Clean up from any prior run.
    rm -f *.list

    # **** Generate pkgs-to-remove.list by uncommenting these lines ****
    # get-only-in-pkgs "$rootfs" "$recoveryfs"
    # get-only-in-auto-install "$rootfs" "$recoveryfs"

    # The packages common between lists pkgs-only-in-rootfs.list and
    # auto-install-only-in-rootfs.list are removed from a copy of
    # rootfs to produce the base of a recovery filesystem.
    # echo "comm -12 pkgs-only-in-rootfs.list auto-install-only-in-rootfs.list \\"
    # echo "    >pkgs-to-remove.list"
    # comm -12 pkgs-only-in-rootfs.list auto-install-only-in-rootfs.list \
    #      >pkgs-to-remove.list
    # ******************************************************************


    # The list pkgs-to-remove.list, generated by the commented lines
    # above, is appended to this script as a patch.

    # The list of packages to remove, pkgs-to-remove.list, is
    # augmented by a curated list of residual packages, appended as a
    # patch to this script. This list was produced after purging
    # pkgs-to-remove.list and comparing the remaining installed
    # packages against those in recoveryfs. So after enough iterations
    # and/or version changes, the list should be re-examined.

    # Extract and apply patch at the end of this script to create
    # `residual-to-remove.list'.
    sed -n '/BEGIN patch/,$s/^#//p' "${G_VENDOR_PATH}/${script_name}" |
        patch -p0

    # To produce recoveryfs, copy rootfs and remove from it all
    # packages in both lists `pkgs-to-remove.list' and
    # `residual-to-remove.list'.
    pare-fs "$newfs" "$rootfs" "pkgs-to-remove.list residual-to-remove.list"

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
#diff -Nru pkgs-to-remove.list~ pkgs-to-remove.list
#--- pkgs-to-remove.list~   1969-12-31 19:00:00.000000000 -0500
#+++ pkgs-to-remove.list    2020-12-29 02:08:49.534680534 -0500
#@@ -0,0 +1,524 @@
#+adwaita-icon-theme
#+at-spi2-core
#+bsdmainutils
#+build-essential
#+cockpit-bridge
#+cockpit-packagekit
#+cockpit-storaged
#+cockpit-system
#+cockpit-ws
#+console-setup
#+console-setup-linux
#+cpp
#+cpp-8
#+cracklib-runtime
#+dbus-user-session
#+dbus-x11
#+dconf-gsettings-backend
#+dconf-service
#+debconf-i18n
#+desktop-base
#+desktop-file-utils
#+ethtool
#+exim4-base
#+exim4-config
#+exim4-daemon-light
#+exo-utils
#+fontconfig
#+fontconfig-config
#+fonts-dejavu-core
#+fonts-quicksand
#+g++
#+g++-8
#+gcc
#+gcc-8
#+gconf-service
#+gconf2-common
#+gcr
#+gir1.2-appindicator3-0.1
#+gir1.2-atk-1.0
#+gir1.2-freedesktop
#+gir1.2-gdkpixbuf-2.0
#+gir1.2-gtk-3.0
#+gir1.2-notify-0.7
#+gir1.2-pango-1.0
#+glib-networking
#+glib-networking-common
#+glib-networking-services
#+gnome-accessibility-themes
#+gnome-icon-theme
#+gnome-keyring
#+gnome-keyring-pkcs11
#+gnome-themes-extra
#+gnome-themes-extra-data
#+gsettings-desktop-schemas
#+gstreamer1.0-gl
#+gstreamer1.0-plugins-base
#+gstreamer1.0-x
#+gtk-update-icon-cache
#+gtk2-engines-pixbuf
#+gtk2-engines-xfce
#+guile-2.2-libs
#+gvfs
#+gvfs-common
#+gvfs-daemons
#+gvfs-libs
#+hdparm
#+hicolor-icon-theme
#+iso-codes
#+kbd
#+keyboard-configuration
#+liba52-0.7.4
#+libaa1
#+libaacs0
#+libaom0
#+libappindicator3-1
#+libappstream4
#+libasan5
#+libasound2-plugins
#+libass9
#+libasyncns0
#+libatk-bridge2.0-0
#+libatk1.0-0
#+libatk1.0-data
#+libatkmm-1.6-1v5
#+libatomic1
#+libatspi2.0-0
#+libavahi-client3
#+libavc1394-0
#+libavcodec58
#+libavresample4
#+libavutil56
#+libayatana-appindicator3-1
#+libayatana-ido3-0.4-0
#+libayatana-indicator3-7
#+libbdplus0
#+libblockdev-mdraid2
#+libbluray2
#+libbs2b0
#+libbytesize1
#+libcaca0
#+libcairo-gobject2
#+libcairo2
#+libcairomm-1.0-1v5
#+libcanberra-gtk3-0
#+libcanberra-gtk3-module
#+libcanberra0
#+libcc1-0
#+libcdio18
#+libcdparanoia0
#+libchromaprint1
#+libcodec2-0.8.1
#+libcolord2
#+libcrack2
#+libcroco3
#+libcups2
#+libdatrie1
#+libdbus-glib-1-2
#+libdbusmenu-glib4
#+libdbusmenu-gtk3-4
#+libdc1394-22
#+libdca0
#+libdconf1
#+libde265-0
#+libdrm-amdgpu1
#+libdrm-common
#+libdrm-etnaviv1
#+libdrm-nouveau2
#+libdrm-radeon1
#+libdrm2
#+libdv4
#+libdvdnav4
#+libdvdread4
#+libegl-mesa0
#+libegl1
#+libegl1-mesa
#+libepoxy0
#+libevdev2
#+libevent-2.1-6
#+libexif12
#+libexo-1-0
#+libexo-2-0
#+libexo-common
#+libexo-helpers
#+libfaad2
#+libfftw3-double3
#+libfftw3-single3
#+libflac8
#+libflite1
#+libfluidsynth1
#+libfontconfig1
#+libfontenc1
#+libfreetype6
#+libgail-common
#+libgail18
#+libgarcon-1-0
#+libgarcon-common
#+libgbm1
#+libgc1c2
#+libgcc-8-dev
#+libgck-1-0
#+libgconf-2-4
#+libgcr-base-3-1
#+libgcr-ui-3-1
#+libgdk-pixbuf2.0-0
#+libgdk-pixbuf2.0-bin
#+libgdk-pixbuf2.0-common
#+libgl1
#+libgl1-mesa-dri
#+libglapi-mesa
#+libgles2
#+libglib2.0-bin
#+libglibmm-2.4-1v5
#+libglu1-mesa
#+libglvnd0
#+libglx-mesa0
#+libglx0
#+libgme0
#+libgnutls-dane0
#+libgomp1
#+libgraphene-1.0-0
#+libgraphite2-3
#+libgsasl7
#+libgsm1
#+libgssdp-1.0-3
#+libgstreamer-gl1.0-0
#+libgstreamer-plugins-bad1.0-0
#+libgstreamer-plugins-base1.0-0
#+libgstreamer1.0-0
#+libgtk-3-0
#+libgtk-3-bin
#+libgtk-3-common
#+libgtk2.0-0
#+libgtk2.0-bin
#+libgtk2.0-common
#+libgtkmm-3.0-1v5
#+libgupnp-1.0-4
#+libgupnp-igd-1.0-4
#+libharfbuzz0b
#+libical3
#+libice6
#+libiec61883-0
#+libilmbase23
#+libimobiledevice6
#+libindicator3-7
#+libinput-bin
#+libinput10
#+libisl19
#+libjack-jackd2-0
#+libjbig0
#+libjpeg62-turbo
#+libjson-glib-1.0-0
#+libjson-glib-1.0-common
#+libkate1
#+libkeybinder-3.0-0
#+libkyotocabinet16v5
#+liblcms2-2
#+liblightdm-gobject-1-0
#+liblilv-0-0
#+libllvm7
#+libltdl7
#+libmailutils5
#+libmariadb3
#+libmjpegutils-2.1-0
#+libmms0
#+libmodplug1
#+libmp3lame0
#+libmpc3
#+libmpcdec6
#+libmpeg2-4
#+libmpeg2encpp-2.1-0
#+libmpg123-0
#+libmplex2-2.1-0
#+libmtdev1
#+libnice10
#+libnma0
#+libnotify-bin
#+libnotify4
#+libntlm0
#+libofa0
#+libogg0
#+libopenal-data
#+libopenal1
#+libopencore-amrnb0
#+libopencore-amrwb0
#+libopenexr23
#+libopenjp2-7
#+libopenmpt0
#+libopus0
#+liborc-0.4-0
#+libpackagekit-glib2-18
#+libpam-gnome-keyring
#+libpango-1.0-0
#+libpangocairo-1.0-0
#+libpangoft2-1.0-0
#+libpangomm-1.4-1v5
#+libpangoxft-1.0-0
#+libpapi5.7
#+libpciaccess0
#+libpcp-gui2
#+libpcp-import1
#+libpcp-mmv1
#+libpcp-pmda-perl
#+libpcp-pmda3
#+libpcp-trace2
#+libpcp-web1
#+libpcp3
#+libpfm4
#+libpipeline1
#+libpixman-1-0
#+libplist3
#+libpng16-16
#+libpoppler-glib8
#+libpoppler82
#+libproxy1v5
#+libpulse-mainloop-glib0
#+libpulse0
#+libpulsedsp
#+libpwquality-common
#+libpwquality-tools
#+libpwquality1
#+libpython-stdlib
#+libpython2-stdlib
#+libpython2.7
#+libpython2.7-minimal
#+libpython2.7-stdlib
#+libraw1394-11
#+librest-0.7-0
#+librsvg2-2
#+librsvg2-common
#+libsamplerate0
#+libsbc1
#+libsecret-1-0
#+libsecret-common
#+libsensors-config
#+libsensors5
#+libserd-0-0
#+libshine3
#+libshout3
#+libsidplay1v5
#+libsigc++-2.0-0v5
#+libsm6
#+libsnappy1v5
#+libsndfile1
#+libsndio7.0
#+libsord-0-0
#+libsoundtouch1
#+libsoup-gnome2.4-1
#+libsoup2.4-1
#+libsoxr0
#+libspandsp2
#+libspeex1
#+libspeexdsp1
#+libsratom-0-0
#+libsrtp2-1
#+libssh-4
#+libstartup-notification0
#+libstdc++-8-dev
#+libstemmer0d
#+libswresample3
#+libtag1v5
#+libtag1v5-vanilla
#+libtdb1
#+libtext-charwidth-perl
#+libtext-iconv-perl
#+libtext-wrapi18n-perl
#+libthai-data
#+libthai0
#+libtheora0
#+libthunarx-3-0
#+libtiff5
#+libtumbler-1-0
#+libtwolame0
#+libubsan1
#+libunbound8
#+libunwind8
#+libupower-glib3
#+liburi-perl
#+libusbmuxd4
#+libutempter0
#+libv4l-0
#+libv4lconvert0
#+libva-drm2
#+libva-x11-2
#+libva2
#+libvdpau-va-gl1
#+libvdpau1
#+libvisual-0.4-0
#+libvo-aacenc0
#+libvo-amrwbenc0
#+libvorbis0a
#+libvorbisenc2
#+libvorbisfile3
#+libvpx5
#+libvulkan1
#+libwacom-bin
#+libwacom-common
#+libwacom2
#+libwavpack1
#+libwayland-client0
#+libwayland-cursor0
#+libwayland-egl1
#+libwayland-server0
#+libwebp6
#+libwebpmux3
#+libwebrtc-audio-processing1
#+libwildmidi2
#+libwnck-common
#+libwnck22
#+libx11-6
#+libx11-data
#+libx11-xcb1
#+libx264-155
#+libx265-165
#+libxau6
#+libxaw7
#+libxcb-dri2-0
#+libxcb-dri3-0
#+libxcb-glx0
#+libxcb-present0
#+libxcb-randr0
#+libxcb-render0
#+libxcb-shape0
#+libxcb-shm0
#+libxcb-sync1
#+libxcb-util0
#+libxcb-xfixes0
#+libxcb1
#+libxcomposite1
#+libxcursor1
#+libxdamage1
#+libxdmcp6
#+libxext6
#+libxfce4panel-2.0-4
#+libxfce4ui-1-0
#+libxfce4ui-2-0
#+libxfce4ui-common
#+libxfce4ui-utils
#+libxfce4util-bin
#+libxfce4util-common
#+libxfce4util7
#+libxfconf-0-2
#+libxfixes3
#+libxfont2
#+libxft2
#+libxi6
#+libxinerama1
#+libxkbcommon0
#+libxkbfile1
#+libxklavier16
#+libxmu6
#+libxmuu1
#+libxpm4
#+libxrandr2
#+libxrender1
#+libxres1
#+libxshmfence1
#+libxss1
#+libxt6
#+libxtst6
#+libxv1
#+libxvidcore4
#+libxxf86dga1
#+libxxf86vm1
#+libzbar0
#+libzvbi-common
#+libzvbi0
#+light-locker
#+lightdm
#+lightdm-gtk-greeter
#+lsof
#+mailutils
#+mailutils-common
#+man-db
#+manpages
#+manpages-dev
#+mariadb-common
#+mdadm
#+mesa-va-drivers
#+mesa-vdpau-drivers
#+mesa-vulkan-drivers
#+mobile-broadband-provider-info
#+mysql-common
#+notification-daemon
#+p11-kit
#+p11-kit-modules
#+packagekit
#+packagekit-tools
#+pavucontrol
#+pcp
#+pcp-conf
#+pinentry-gnome3
#+policykit-1-gnome
#+poppler-data
#+powermgmt-base
#+pulseaudio
#+pulseaudio-module-bluetooth
#+pulseaudio-utils
#+python
#+python-minimal
#+python2
#+python2-minimal
#+python2.7
#+python2.7-minimal
#+python3-cairo
#+python3-gi-cairo
#+python3-pcp
#+rtkit
#+sound-theme-freedesktop
#+tango-icon-theme
#+thunar
#+thunar-data
#+thunar-volman
#+tumbler
#+tumbler-common
#+upower
#+usbmuxd
#+va-driver-all
#+vdpau-driver-all
#+vim-runtime
#+wamerican
#+x11-apps
#+x11-common
#+x11-session-utils
#+x11-utils
#+x11-xkb-utils
#+x11-xserver-utils
#+xauth
#+xbitmaps
#+xfce4-appfinder
#+xfce4-notifyd
#+xfce4-panel
#+xfce4-pulseaudio-plugin
#+xfce4-session
#+xfce4-settings
#+xfconf
#+xfdesktop4
#+xfdesktop4-data
#+xfonts-100dpi
#+xfonts-75dpi
#+xfonts-base
#+xfonts-encodings
#+xfonts-scalable
#+xfonts-utils
#+xfwm4
#+xinit
#+xkb-data
#+xorg
#+xorg-docs-core
#+xserver-common
#+xserver-xorg
#+xserver-xorg-core
#+xserver-xorg-input-all
#+xserver-xorg-input-libinput
#+xserver-xorg-input-wacom
#+xserver-xorg-legacy
#+xserver-xorg-video-all
#+xserver-xorg-video-amdgpu
#+xserver-xorg-video-ati
#+xserver-xorg-video-dummy
#+xserver-xorg-video-fbdev
#+xserver-xorg-video-nouveau
#+xserver-xorg-video-radeon
#+xserver-xorg-video-vesa
#+xterm
