#
# @(#) boot.scr
#
# This script probes for expansion modules and sets the appropriate
# flattened device tree (FDT) file.
#
# If bootable USB flash drive is detected, boot it. Otherwise,
# boot from MMC.
#
setenv silent 1
i2c dev 1
i2c probe 23
status23=$?
i2c probe 49
status49=$?
setenv silent

if test $status23 -eq 0; then
    echo 'Digital GPIO expansion board found'
    setenv fdt_file imx7d-roadrunner_gpio-emmc.dtb
    setenv kernelargs REVO-GPIO-v1.0
elif test $status49 -eq 0; then
    echo 'Mixed signal expansion board found'
    # setenv fdt_file imx7d-roadrunner_mixio-emmc.dtb
    setenv fdt_file imx7d-roadrunner-emmc.dtb
    setenv kernelargs REVO-MIXIO-v1.0
else
    echo 'Expansion board not found'
fi

usbdev=0
usbbootpart=1
usbrootpart=2
setenv usbloadimage 'load usb ${usbdev}:${usbbootpart} ${loadaddr} ${bootdir}/${image}'
setenv usbargs 'setenv bootargs console=${console},${baudrate} root=/dev/sda${usbrootpart} rootwait rw'
setenv usbloadfdt 'echo fdt_file=${fdt_file}; load usb ${usbdev}:${usbbootpart} ${fdt_addr} ${bootdir}/${fdt_file}'
setenv usbboot 'echo Booting from usb ...; run usbargs; run optargs; if test ${boot_fdt} = yes || test ${boot_fdt} = try; then if run usbloadfdt; then bootz ${loadaddr} - ${fdt_addr}; else if test ${boot_fdt} = try; then bootz; else echo WARN: Cannot load the DT; fi; fi;  else bootz; fi'

usb start
if run usbloadimage; then
    run usbboot
elif run loadimage; then
    run mmcboot
else
    run netboot
fi
