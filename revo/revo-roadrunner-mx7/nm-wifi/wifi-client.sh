#!/usr/bin/env bash
#
# @(#) wifi-client.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script creates and activates a NetworkManger WiFi client profile.
#
script_name=${0##*/}
script_dir=${0%/*}

: ${CAT:='/bin/cat'}

declare -r DEFAULT_IP4_ADDR='10.100.0.1/24'

source "${script_dir}/ip-funcs.sh"
source "${script_dir}/wifi-funcs.sh"

if (( $# != 4 )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] iface profile ssid password
where:
  -h        - Display help, then exit
  iface     - WiFi interface (default: $(get_wifi_interface))
  profile   - NetworkManger profile name (default: client)
  ssid      - Name of WiFi network to connect to
  password  - WiFi network password
EOF
    exit 0
fi

declare interface=$1
declare profile=$2
declare ssid=$3
declare password=$4

validate_wifi_interface "$interface" || exit $?
remove_previous "$profile"
disconnect "$interface"
create client "$profile" "$interface" "$ssid" "$password" "$wifi_band" "$ip4_addr"
activate "$profile"
