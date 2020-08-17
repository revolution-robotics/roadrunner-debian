# Building REVO board boot images

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite and kernel sources](#fetch-build-suite-and-kernel-sources)
- [Build U-Boot, Linux kernel and modules](#build-u-boot-linux-kernel-and-modules)
- [Populate root and recovery filesystems](#populate-root-and-recovery-filesystems)
- [Create bootable image file](#create-bootable-image-file)
- [Flash bootable image to SD card](#flash-bootable-image-to-sd-card-or-usb-flash-drive)
- [Subsequent builds](#subsequent-builds)

## Overview
This is a Debian GNU/Linux build suite for REVO boards.
The following build instructions have been verified on a Ubuntu 20.04 x86 host platform.

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
curl -L https://ftp-master.debian.org/keys/release-10.asc |
sudo gpg --import --no-default-keyring --keyring /usr/share/keyrings/debian-buster-release.gpg
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

## Build U-Boot, Linux kernel and modules
Build the primary (SPL) and secondary (U-Boot) bootloaders (and save
them as _output/SPL.mmc_ and _output/u-boot.img.mmc_, respecitvely.):


```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```

Build the Linux kernel (zImage) and Device Tree (DTB) files (and save
them to _output_):

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```

Build kernel modules (and install them under _rootfs_):

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```

## Populate root and recovery filesystems
Bootstrap Debian to _rootfs_ and install kernel modules and firmware:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```

Bootstrap Debian to _recoveryfs_ and install kernel modules and firmware:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c recoveryfs
```

## Create bootable image file

Create a  bootable image file (4 GB compressed and saved as
_output/\${MACHINE}-\${ISO8601}.img.gz_):

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```

## Flash bootable image to SD card or USB flash drive
Flash the bootable image file to SD card:

```shell
sudo ./revo_make_debian.sh -c flashimage
```

If multiple image files exist, select one when prompted from the list
printed on the console. If multiple removable drives exist, select one
when prompted from the list printed on the console.

## Subsequent builds
After editing kernel sources, the kernel and modules can be rebuilt
without re-running Debian bootstrap as follows:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rtar
```

Likewise, after editing U-Boot sources, rebuild U-Boot with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```
