#!/usr/bin/env bash
#
# @(#) wifi-access-point.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script creates and activates a NetworkManger WiFi access point
# profile. It's assumed that there's a separate network interface with
# Internet access.
#
# The first argument, a NetworkManger profile name, is required.
# Arguments are as follows:
#
#     profile
#     interface (e.g., wlan0)
#     ssid (default: $(hostname))
#     password (default: $(hostname))
#     wifi_band ('a' | 'bg', default: 'a')
#     ip4_addr (default: $DEFAULT_IP4_ADDR)
#
script_name=${0##*/}
script_dir=${0%/*}

: ${CAT:='/bin/cat'}

source "${script_dir}/ip-funcs.sh"
source "${script_dir}/nm-funcs.sh"

declare -r DEFAULT_IP4_ADDR=10.${WIFI_CLASS_B}.0.1/24

if (( $# == 0 )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] profile [iface [ssid [password [wifi_band [ip4_addr]]]]]
where:
  -h        - Display help, then exit
  profile   - NetworkManger profile name
  iface     - WiFi interface (default: $(get_managed_interfaces wifi | head -1))
  ssid      - Name (SSID) of WiFi network (default: $(hostname))
  password  - WiFi network password (default: $(hostname))
  band      - WiFi band - either 'a' or 'bg' (default: 'a')
  ip4_addr  - IP4 address and netmask (default: $DEFAULT_IP4_ADDR)
EOF
    exit 0
fi

declare profile=$1
declare interface=${2:-$(get_managed_interfaces wifi | head -1)}
declare ssid=${3:-$(hostname)}
declare password=${4:-$(hostname)}
declare wifi_band=${5:-'a'}
declare ip4_addr=${6:-"$DEFAULT_IP4_ADDR"}

validate_interface "$interface" || exit $?
validate_wifi_band "$wifi_band" || exit $?
validate_ip4_network "$interface" "$ip4_addr" || exit $?

disconnect "$interface"
remove_previous "$profile"
create_wifi ap "$profile" "$interface" "$ssid" "$password" "$wifi_band" "$ip4_addr"
activate "$profile"
