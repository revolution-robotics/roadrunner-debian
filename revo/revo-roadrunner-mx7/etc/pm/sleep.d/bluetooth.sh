#!/usr/bin/env bash
#
# @(#) bluetooth.sh
#
# See also /etc/bluetooth/revo-bluetooth.
#
source /etc/bluetooth/revo-bluetooth.conf

case $1 in
    "suspend")
        if test ! -d "/sys/class/gpio/gpio${BT_GPIO}"; then
            echo "$BT_GPIO" >/sys/class/gpio/export
            echo "out" > "/sys/class/gpio/gpio${BT_GPIO}/direction"
        fi

        echo 0 > "/sys/class/gpio/gpio${BT_GPIO}/value"
        pkill -9 -f brcm_patchram_plus
        ;;
    "resume")
        : Handled by /etc/bluetooth/revo-bluetooth
        ;;
esac
