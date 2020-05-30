#!/usr/bin/env bash
#
# @(#) access-point.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script creates and activates a NetworkManger access point WiFi
# profile. It's assumed that there's a separate network interface with
# Internet access.
#
# If no arguments are given, then the first WiFi interface managed by
# NetworkManager is used for the access point. Accepted arguments are
# as follows:
#
#     interface (e.g., wlan0)
#     profile (default: $(hostname))
#     ssid (default: $(hostname))
#     password (default: $(hostname))
#     wifi_band ('a' | 'bg', default: 'a')
#     ip4_addr (default: $DEFAULT_IP4_ADDR)
#
script_name=${0##*/}
script_dir=${0%/*}

: ${CAT:='/bin/cat'}

declare -r DEFAULT_IP4_ADDR='10.100.0.1/24'

source "${script_dir}/ip-funcs.sh"
source "${script_dir}/nm-funcs.sh"

if (( $# == 0 )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] [iface [profile [ssid [password]]]]
where:
  -h        - Display help, then exit
  iface     - WiFi interface (default: $(get_wifi_interface))
  profile   - NetworkManger profile name (default: $(hostname))
  ssid      - Name (SSID) of WiFi network (default: $(hostname))
  password  - WiFi network password (default: $(hostname))
  band      - WiFi band - either 'a' or 'bg' (default: 'a')
  ip4       - IP4 address and netmask (default: $DEFAULT_IP4_ADDR)
EOF
    exit 0
fi

declare interface=${1:-$(get_wifi_interface)}
declare profile=${2:-$(hostname)}
declare ssid=${3:-$(hostname)}
declare password=${4:-$(hostname)}
declare wifi_band=${5:-'a'}
declare ip4_addr=${6:-"$DEFAULT_IP4_ADDR"}

validate_wifi_interface "$interface" || exit $?
validate_wifi_band "$wifi_band" || exit $?
validate_ip4_network "$interface" "$ip4_addr" || exit $?

remove_previous "$profile"
disconnect "$interface"
create ap "$profile" "$interface" "$ssid" "$password" "$wifi_band" "$ip4_addr"
activate "$profile"
