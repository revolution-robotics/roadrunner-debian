# Building REVO board boot images

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite, cross-compiler and sources](#fetch-build-suite-cross-compiler-and-sources)
- [Build uBoot and Linux kernel and modules](#build-uboot-and-linux-kernel-and-modules)
- [Populate root filesystem with Debian, kernel modules and firmware](#populate-root-filesystem-with-debian-kernel-modules-and-firmware)
- [Create bootable SD card](#create-bootable-sd-card)
- [Create bootable image file](#create-bootable-image-file)
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
Download the cross-compiler and sources for uBoot and Linux kernel with:
```shell
cd roadrunner_debian
MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy
```
## Build uBoot and Linux kernel and modules
Build the uBoot bootloader (and save it as _output/SPL.mmc_ and _output/u-boot.img.mmc_) with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```
Build the Linux kernel (and save it as _output/zImage_) and Device Tree (DTB) files with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```
Build kernel modules (and install them under _rootfs_) with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```
## Populate root filesystem with Debian, kernel modules and firmware
Import a Debian GPG-signing key so that the integrity of installed packages
can be verified:
```shell
curl https://ftp-master.debian.org/keys/release-10.asc |
sudo gpg --import --no-default-keyring --keyring /usr/share/keyrings/debian-buster-release.gpg
```
Bootstrap Debian to _rootfs_ and install kernel modules and firmware with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```
## Create bootable SD card
After a successful build, to create a bootable SD card, with the card inserted and accessible as block device _/dev/sdX_ (e..g., _/dev/sdg_), run:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c sdcard -d /dev/sdX
```
## Create bootable image file
After a successful build, to create a Gzip-compressed 4 GB bootable image file (saved as
_output/\${MACHINE}-\${ISO8601}.img.gz_), run:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```
## Subsequent builds
When editing kernel sources only, the build sequence can avoid
re-running the Debian bootstrap as follows:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rtar
```
Likewise, when editing uBoot sources only, use:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```
