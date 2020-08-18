# Building REVO board boot images

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Fetch build suite and kernel sources](#fetch-build-suite-and-kernel-sources)
- [Build U-Boot, Linux kernel and modules](#build-u-boot-linux-kernel-and-modules)
- [Populate root and recovery filesystems](#populate-root-and-recovery-filesystems)
- [Create bootable image file](#create-bootable-image-file)
- [Flash bootable image to SD card or USB flash drive](#flash-bootable-image-to-sd-card-or-usb-flash-drive)
- [Enable booting from USB flash drive](#enable-booting-from-usb-flash-drive)
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
To build the primary (SPL) and secondary (U-Boot) bootloaders (and save
them as _output/SPL.mmc_ and _output/u-boot.img.mmc_, respecitvely.), use:


```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
```

To build the Linux kernel (zImage) and Device Tree (DTB) files (and save
them to _output_), use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
```

To build kernel modules (and install them under _rootfs_), use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
```

## Populate root and recovery filesystems
To bootstrap Debian to _rootfs_ and install kernel modules and
firmware, use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rootfs
```

To bootstrap Debian to _recoveryfs_ and install kernel modules and
firmware, use:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c recoveryfs
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

If multiple image files exist, select one when prompted from the list
printed on the console. If multiple removable drives exist, select one
when prompted from the list printed on the console.

## Enable booting from USB flash drive
The U-Boot script that enables booting from USB flash drive is always
read from either SD card or eMMC. To enable booting from USB flash
drive without an SD card installed, it is necessary to first flash
eMMC. The process for doing so is as follows:

Ensure that the onboard pins labeled __BMO__ are jumpered for booting from
SD.¹  Then with a bootable SD card installed, power cycle the board.
At the console, log in and run the command:

```
flash-emmc
```

This installs a U-Boot boot loader, a Debian root file system and a
recovery file system onto eMMC. Once the `flash-emmc` command
completes successfully, halt the system and remove the SD card,
then jumper the __BMO__ pins for booting from eMMC and boot up.

Now, whenever the system is booted, it first looks for a bootable USB
flash drive and uses that, if available.  Otherwise, it boots to either
eMMC or SD card, depending on how __BMO__ pins are jumpered.

¹ On my boards, the pins must not be jumpered in order to boot from SD
card. In subsequent builds, they may need to be jumpered.

## Subsequent builds
After editing kernel sources, the kernel and modules can be rebuilt
without re-running Debian bootstrap as follows:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c kernel
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c modules
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c rtar
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```

Likewise, after editing U-Boot sources, rebuild U-Boot with:

```shell
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c bootloader
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage
```
