#
# @(#) boot.scr
#
# This script probes for expansion modules and sets the appropriate
# flattened device tree (FDT) file.
#
# If bootable USB flash drive is detected, boot it. Otherwise,
# boot from MMC.
#

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
setenv green_pwr_led_off 'gpio clear 61'
setenv green_pwr_led_on 'gpio set 61'
setenv red_leds_on 'gpio set 60; gpio set 75; gpio set 74'
setenv red_leds_off 'gpio clear 60; gpio clear 75; gpio clear 74'
setenv hw_reset 'if gpio input $reset_pin; then enable_recovery=true; setenv reset_count 0xA; while itest.b $reset_count > 0; do setexpr reset_count $reset_count - 0x1; if $enable_recovery; then run red_leds_on; sleep 0.5; run red_leds_off; sleep 0.5; if gpio input $reset_pin; then true; else enable_recovery=false; fi; fi; done; $enable_recovery; else false; fi'

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
if run usbloadimage; then
    run usbboot
elif run loadimage; then
    if test $mmcdev = 1; then
        setenv silent 1
        run green_pwr_led_off
        if test ."$sw_reset" = .'true' || run hw_reset; then
            setenv kernelargs "$kernelargs recovery_request"
            setenv mmcrootpart 3
            run red_leds_on
            echo "Processing recovery request..."
            sleep 5
        else
            run green_pwr_led_on
        fi
        setenv silent
    fi
    run mmcboot
else
    run netboot
fi
