#!/usr/bin/env bash
#
# @(#) wifi.sh
#
# See also /etc/wifi/revo-wifi.
#
source /etc/wifi/revo-wifi-common.sh

som_is_mx7_5g || exit 0

case $1 in
    "suspend")
        wifi_down
        ;;
    "resume")
        wifi_up
        ;;
esac
