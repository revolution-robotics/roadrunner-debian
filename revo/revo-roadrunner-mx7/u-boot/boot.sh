#
# @(#) boot.scr
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script probes for expansion modules and sets the appropriate
# flattened device tree (FDT) file.
#
# It then checks if recovery is requested, either by software
# `recovery_request' or by hardware reset button. If so and a bootable
# USB drive is detected, then it's booted. Otherwise, the eMMC
# recovery partition is booted.
#
# If recovery is not requested, but `usbboot_request' is set to
# `allow' and a bootable USB drive is detected, then it's booted.
# Otherwise, the eMMC rootfs partition is booted.
#
# After recovery is run (e.g., from USB drive), the U-Boot environment
# variable `usbboot_request' is assigned the value `reset', which
# forces booting to eMMC rootfs. From rootfs, a systemd service then
# clears `usbboot_request' so that a USB drive can be booted in a
# subsequent power cycle.
#
# To prevent booting to USB drive, set the U-Boot environment variable
# `usbboot_request' to `deny'. This rule will enforced until a
# recovery is requested. In particular, if the reset button is
# continuously pressed for 10 seconds during boot (until all LEDs turn
# solid red for 5 seconds), then recovery is attempted from a bootable
# USB drive, if detected.

# To reset `usbboot_request' after boot, use:
#  fw_setenv usbboot_request reset
if test ."$usbboot_request" = .''; then
    usbboot_request=allow
fi

# Ensure that software recovery request doesn't persist across reboots.
sw_reset=$recovery_request
setenv recovery_request
saveenv

reset_pin=83
usbdev=0
usbbootpart=1
usbrootpart=2
setenv usbloadimage 'load usb ${usbdev}:${usbbootpart} ${loadaddr} ${bootdir}/${image}'
setenv usbargs 'setenv bootargs console=${console},${baudrate} root=/dev/sda${usbrootpart} rootwait rw'
setenv usbloadfdt 'echo fdt_file=${fdt_file}; load usb ${usbdev}:${usbbootpart} ${fdt_addr} ${bootdir}/${fdt_file}'
setenv usbboot 'echo Booting from usb ...; run usbargs; run optargs; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if run usbloadfdt; then bootz ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootz; else echo WARN: Cannot load the DT; fi; fi;  else bootz; fi'
setenv green_pwr_led_off 'setenv silent 1; gpio clear 61; setenv silent'
setenv green_pwr_led_on 'setenv silent 1; gpio set 61; setenv silent'
setenv red_leds_on 'setenv silent 1; gpio set 60; gpio set 75; gpio set 74; setenv silent'
setenv red_leds_off 'setenv silent 1; gpio clear 60; gpio clear 75; gpio clear 74; setenv silent'
setenv hw_reset 'setenv silent 1; if gpio input $reset_pin; then enable_recovery=true; setenv reset_count 0xA; while itest.b $reset_count > 0; do setexpr reset_count $reset_count - 0x1; if $enable_recovery; then run red_leds_on; sleep 0.5; run red_leds_off; sleep 0.5; if gpio input $reset_pin; then true; else enable_recovery=false; fi; fi; done; $enable_recovery; else false; fi; setenv silent'

setenv silent 1
i2c dev 1
i2c probe 23
status23=$?
i2c probe 49
status49=$?
setenv silent

# If 0x23 is a valid I2C address...
if test $status23 -eq 0; then
    echo 'Digital GPIO expansion board found'
    setenv fdt_file imx7d-roadrunner_gpio-emmc.dtb
    setenv kernelargs "$kernelargs REVO-GPIO-v1.0"

# If 0x49 is a valid I2C address...
elif test $status49 -eq 0; then
    echo 'Mixed signal expansion board found'
    # setenv fdt_file imx7d-roadrunner_mixio-emmc.dtb
    setenv fdt_file imx7d-roadrunner-emmc.dtb
    setenv kernelargs "$kernelargs REVO-MIXIO-v1.0"

# Otherwise...
else
    echo 'Expansion board not found'
fi

usb start
run green_pwr_led_off
if test $mmcdev = 1 && test ."$sw_reset" = .'true' || run hw_reset; then
    run red_leds_on
    sleep 5
    setenv kernelargs "$kernelargs recovery_request"
    if run usbloadimage; then
        echo "Processing USB recovery request..."
        run usbboot
    elif run loadimage; then
        setenv mmcrootpart 3
        echo "Processing eMMC recovery request..."
        run mmcboot
    else
        run netboot
    fi
elif test ."$usbboot_request" = .'allow' && run usbloadimage; then
    run green_pwr_led_on
    setenv kernelargs "$kernelargs recovery_request"
    echo "Processing USB recovery request..."
    run usbboot
elif run loadimage; then
    run green_pwr_led_on
    if test ."$usbboot_request" = .'reset'; then
       setenv kernelargs "$kernelargs reset_usbboot"
    fi
    run mmcboot
else
    run netboot
fi
