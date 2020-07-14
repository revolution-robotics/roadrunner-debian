# Building REVO board boot images

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite, cross-compiler and sources](#fetch-build-suite-cross-compiler-and-sources)
- [Build U-Boot, Linux kernel and modules](#build-u-boot-linux-kernel-and-modules)
- [Populate root and recovery filesystems with Debian](#populate-root-and-recovery-filesystems-with-debian)
- [Create bootable SD card](#create-bootable-sd-card)
- [Create bootable image file](#create-bootable-image-file)
- [Flash bootable image to SD card](#flash-bootable-image-to-sd-card)
- [Subsequent builds](#subsequent-builds)

## Overview
This is a Debian GNU/Linux build suite for REVO boards.
The following build instructions have been verified on a Ubuntu 20.04 x86 host platform.

## Prerequisites
Verify that required tools and libraries are available by running (on the command line):
```shell
sudo apt install asciidoc autoconf automake autopoint bc \
    binfmt-support binutils bison build-essential chrpath cmake \
    colordiff coreutils curl cvs debootstrap desktop-file-utils \
    device-tree-compiler diffstat docbook-utils dosfstools \
    flex g++ gawk gcc gcc-multilib git git-core golang gpart \
    groff help2man kmod kpartx lib32ncurses5-dev libarchive-dev \
    libgl1-mesa-dev libglib2.0-dev libglu1-mesa-dev libsdl1.2-dev \
    libssl-dev libtool lvm2 lzop m4 make mercurial mtd-utils \
    openssh-server python-git python-m2crypto python-pysqlite2 \
    qemu qemu-user-static sed socat screen subversion texi2html \
    texinfo u-boot-tools unzip wget xterm
```

## Fetch build suite, cross-compiler and sources
Install the build suite under the current directory with the command:

```shell
git clone git@github.com:revolution-robotics/roadrunner-debian.git \
    -b debian_buster_rr01 roadrunner_debian
```

Download the cross-compiler and sources for U-Boot and Linux kernel with:

```shell
cd roadrunner_debian
MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy
```

## Build U-Boot, Linux kernel and modules
Build the U-Boot bootloader (and save it as _output/SPL.mmc_ and
_output/u-boot.img.mmc_) with:


```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```

Build the Linux kernel (and save it as _output/zImage_) and Device
Tree (DTB) files with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```

Build kernel modules (and install them under _rootfs_) with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```

## Populate root and recovery filesystems with Debian
Import a Debian GPG-signing key so that the integrity of installed packages
can be verified:

```shell
curl -L https://ftp-master.debian.org/keys/release-10.asc |
sudo gpg --import --no-default-keyring --keyring /usr/share/keyrings/debian-buster-release.gpg
```

Bootstrap Debian to _rootfs_ and install kernel modules and firmware with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```

Bootstrap Debian to _recoveryfs_ and install kernel modules and firmware with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c recoveryfs
```

## Create bootable SD card
After a successful build, a bootable SD card can be created directly
(i.e., without first creating an image file) by inserting a flash
drive (that can be fully overwritten) and then running:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c sdcard
```

If more than one removable drive is available, you'll be prompted to
select the drive to flash to.

## Create bootable image file
Alternatively, to create a Gzip-compressed 4 GB bootable
image file (saved as _output/\${MACHINE}-\${ISO8601}.img.gz_), run:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```

## Flash bootable image to SD card
Once a bootable image file is available, it can flashed to SD card by running:

```shell
sudo ./revo_make_debian.sh -c flashimage
```

whereupon you'll be prompted to select from the _output_ directory an
image to flash from as well as a removable drive to flash to.

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
