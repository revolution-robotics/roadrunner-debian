# Building REVO board boot images

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite and kernel sources](#fetch-build-suite-and-kernel-sources)
- [Build U-Boot and Linux kernel](#build-u-boot-and-linux-kernel)
- [Bootstrap root filesystem](#bootstrap-root-filesystem)
- [Bootstrap recovery filesystem](#bootstrap-recovery-filesystem)
- [Archive root and recovery filesystems](#archive-root-and-recovery-filesystems)
- [Create bootable image file](#create-bootable-image-file)
- [Flash bootable image to SD card or USB flash drive](#flash-bootable-image-to-sd-card-or-usb-flash-drive)
- [Enable booting from USB flash drive](#enable-booting-from-usb-flash-drive)
- [Subsequent builds](#subsequent-builds)

## Overview
This is a Debian GNU/Linux build suite for REVO boards.
The following build instructions have been verified on a Ubuntu 20.04
x86 host platform. It's important that the commands are run in the
order listed.

## Prerequisites
Verify that required tools and libraries are available by running (on
the command line):

```shell
sudo apt update
sudo apt install -y autoconf automake autopoint binfmt-support \
    binutils bison build-essential chrpath cmake coreutils debootstrap \
    dialog device-tree-compiler diffstat docbook-utils flex \
    g++ gcc gcc-multilib git-core golang gpart groff help2man \
    lib32ncurses5-dev libarchive-dev libgl1-mesa-dev libglib2.0-dev \
    libglu1-mesa-dev libsdl1.2-dev libssl-dev libtool lzop m4 make \
    mtd-utils python3-git python3-m2crypto qemu qemu-user-static \
    socat sudo texi2html texinfo u-boot-tools unzip
sudo apt install -y binutils-arm-linux-gnueabihf
sudo apt install -y cpp-arm-linux-gnueabihf
sudo apt install -y gcc-arm-linux-gnueabihf
sudo apt install -y g++-arm-linux-gnueabihf

```

Import a Debian GPG-signing key to verify repository integrity:

```shell
curl -L https://ftp-master.debian.org/keys/release-10.asc | sudo apt-key add
```

## Fetch build suite and kernel sources
Clone the build suite repository under the current directory:

```shell
git clone https://github.com/revolution-robotics/roadrunner-debian.git \
    -b debian_buster_rr01 roadrunner_debian
```

Download U-Boot and Linux kernel sources:

```shell
cd roadrunner_debian
MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy
```

## Build U-Boot and Linux kernel
To build the primary (SPL) and secondary (U-Boot) bootloaders (and save
them as _output/SPL.mmc_ and _output/u-boot.img.mmc_, respecitvely.), use:


```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```

To build the Linux kernel + U-Boot wrapper (uImage) and compile Device
Tree (DTS) files (and save them to _output_), use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```

## Bootstrap root filesystem

To bootstrap Debian buster and install firmware to the filesystem
_rootfs_, use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```

To install kernel modules and headers to _rootfs_, use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```

## Bootstrap recovery filesystem

The rescue filesystem,  _recoveryfs_, can be built in either of two ways:

* By running Debian bootstrap a second time, or
* From a copy of _rootfs_.

Building _recoveryfs_ from _rootfs_ is fast, but requires some
preparation, including that _rootfs_ is fully populated with Debian,
kernel modules (and headers) and firmware. See the
script
[express_recoveryfs.sh](https://github.com/revolution-robotics/roadrunner-debian/blob/debian_buster_rr01/contrib/express-recoveryfs/express-recoveryfs.sh) for
details. Choose which method to use by setting the variable
`USE_ALT_RECOVERYFS` in the script *revo_make_debian.sh*. Then run:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c recoveryfs
```

To install kernel modules and headers to _recoveryfs_, use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c remodules
```

## Archive root and recovery filesystems

To archive the root and recovery filesystems (as
_output/rootfs.tar.gz_ and _output/recoveryfs.tar.gz_, respectively)
run:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c fstar
```

## Create bootable image file

To create a  bootable image file (4 GB compressed and saved as
_output/\${MACHINE}-\${ISO8601}.img.gz_), use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```

## Flash bootable image to SD card or USB flash drive
To flash a bootable image file (from subdirectory _output_, by
default) to SD card or USB flash drive, use:

```shell
sudo ./revo_make_debian.sh -c flashimage
```

If multiple image files exist, you'll be prompted to select one. Likewise, if
multiple removable drives exist.

## Enable booting from USB flash drive
The U-Boot script that enables booting from USB flash drive is always
read from either SD card or eMMC. To enable booting from USB flash
drive without an SD card installed, it is necessary to first flash
eMMC, which can be done as follows. Ensure that the pins labeled
__BMO__ are not jumpered,¹ then with a bootable SD card installed,
power cycle the board. At the console, log in and run the command:

```
flash-emmc
```

This installs a U-Boot boot loader, Debian root file system and
recovery file system onto eMMC. Once the `flash-emmc` command
completes successfully, jumper the __BMO__ pins and reboot. Now,
whenever the system boots, it first looks for a USB flash drive and
uses that if it's bootable.

¹ On currents boards, U-Boot is read from eMMC if the __BMO__ pins are
jumpered and SD otherwise. In future builds, this may be reversed.

## Subsequent builds
After commiting changes to the kernel or U-Boot source trees, to
incorporate the changes into new builds, update the file
*\${G\_VENDOR\_PATH}/\${MACHINE}/\${MACHINE}.sh*. Then a new disk image can
be created without re-running Debian bootstrap as follows:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c remodules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c fstar
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```

Likewise, after editing U-Boot sources, create a new disk image with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```
