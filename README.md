# Building REVO i.MX7 board boot images
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite, cross-compiler and sources](#fetch-build-suite-cross-compiler-and-sources)
- [Build uBoot and Linux kernel and modules](#build-uboot-and-linux-kernel-and-modules)
- [Populate root filesystem with Debian, kernel modules and firmware](#populate-root-filesystem-with-debian-kernel-modules-and-firmware)
- [Create a bootable SD card](#create-a-bootable-sd-card)
- [Subsequent builds](#subsequent-builds)
## Overview
This is a Debian Linux build suite for REVO i.MX7 boards.
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
To download the cross-compiler and sources, enter the build suite directory:
```shell
cd roadrunner_debian
```
Download the cross-compiler and sources for uBoot and Linux kernel with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy
```
## Build uBoot and Linux kernel and modules
Build the uBoot bootloader with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```
Build the Linux kernel (zImage) and Device Tree (DTB) files with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```
Build kernel modules with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```
## Populate root filesystem with Debian, kernel modules and firmware
Bootstrap Debian to rootfs and install kernel modules and firmware with:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```
## Create a bootable SD card
With an SD card inserted and accessible as block device /dev/sdX (e..g., /dev/sdg), run:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c sdcard -d /dev/sdX
```
## Subsequent builds
When editing kernel sources only, the build sequence can avoid
re-running the Debian bootstrap as follows:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rtar
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rubi
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c sdcard -d /dev/sdX
```
Likewise, when editing uBoot sources only, use:
```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c sdcard -d /dev/sdX
```
