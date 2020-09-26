#!/usr/bin/env bash
#
# @(#) provision.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This U-Boot script is intended for provisioning a new board from SD
# card. It probes for expansion modules and selects the appropriate
# flattened device tree (FDT) file.
#
# In the following, the variable `usbboot_request' is used for the
# "off-label" purpose of controlling provisioning. A better name
# would be something like `provision_request', but that would require
# updating the supporting systemd units as well.
#
# After the eMMC flash procedure, the U-Boot environment variable
# `usbboot_request' must be assigned the value `override' to prevent
# repeating the procedure on reboot. Upon reboot the systemd service
# `reset-usbboot.service' then clears `usbboot_request' so that
# provisioning is enabled on subsequent reboot.
#
# NB: U-Boot && and || operators are evidently grouped by right
#     associativity - i.e.,
#         cmd1 && cmd2 || cmd3
#     is equivalent to
#         cmd1 && { cmd2 || cmd3; }
#     (except that U-Boot doesn't have curly brackets). This differs
#     from all Unix shells (which use left associativity), so should be
#     considered a bug and not used.

if test ."$usbboot_request" = .''; then
    usbboot_request=allow
fi

usbdev=0
usbbootpart=1
usbrootpart=2
setenv usbloadimage 'load usb ${usbdev}:${usbbootpart} ${loadaddr} ${bootdir}/${image}'
setenv usbargs 'setenv bootargs console=${console},${baudrate} root=/dev/sda${usbrootpart} rootwait rw'
setenv usbloadfdt 'echo fdt_file=${fdt_file}; load usb ${usbdev}:${usbbootpart} ${fdt_addr} ${bootdir}/${fdt_file}'
setenv usbboot 'echo Booting from usb ...; run usbargs; run optargs; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if run usbloadfdt; then bootm ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootm; else echo WARN: Cannot load the DT; fi; fi;  else bootm; fi'

setenv silent 1
i2c dev 1
i2c probe 23
status23=$?
i2c probe 49
status49=$?
setenv silent

# If 0x23 is a valid I2C address...
if test $status23 -eq 0; then
    echo 'REVO digital GPIO expansion board detected'
    setenv fdt_file imx7d-roadrunner-dio.dtb
    setenv kernelargs "$kernelargs REVO_IND-GPIO-16_v1.0"

# If 0x49 is a valid I2C address...
elif test $status49 -eq 0; then
    echo 'REVO mixed-signal expansion board detected'
    setenv fdt_file imx7d-roadrunner-mixio.dtb
    setenv kernelargs "$kernelargs REVO_IOMIX-A_v1.0"

# Otherwise...
else
    echo 'Expansion board not detected'
fi

# Assert: $mmcdev -eq 0

# On first boot, flash eMMC...
if test ."$usbboot_request" != .'override'; then

    setenv kernelargs "$kernelargs flash_emmc_from_usb"

    # If bootable SD drive present...
    if run loadimage; then
        echo "Processing SD provisioning request..."
        run mmcboot

    # Otherwise, if bootable USB drive present...
    elif run usbloadimage; then
        echo "Processing USB provisioning request..."
        run usbboot

    # Otherwise, try booting over the network...
    else
        echo "Processing network provisioning request..."
        run netboot
    fi
fi

setenv kernelargs "$kernelargs reset_usbboot"

# Otherwise, if bootable SD drive present...
if run loadimage; then
    run mmcboot

    # Otherwise, if bootable USB drive present...
elif run usbloadimage; then
    run usbboot

# Otherwise, try booting over the network...
else
    run netboot
fi
