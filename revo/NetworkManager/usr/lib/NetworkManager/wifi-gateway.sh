#!/usr/bin/env bash
#
# @(#) wifi-gateway.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script creates and activates a NetworkManger WiFi gateway
# profile. Required arguments are as follows:
#
#     profile
#     interface (e.g., wlan0)
#     ssid
#     password
#
script_name=${0##*/}
script_dir=${0%/*}

: ${CAT:='/bin/cat'}

source "${script_dir}/ip-funcs.sh"
source "${script_dir}/nm-funcs.sh"

if (( $# != 4 )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] profile iface ssid password
where:
  -h        - Display help, then exit
  profile   - NetworkManger profile name
  iface     - WiFi interface
  ssid      - Name (SSID) of WiFi network to connect to
  password  - WiFi network password
EOF
    exit 0
fi

declare profile=$1
declare interface=$2
declare ssid=$3
declare password=$4

validate_interface "$interface" || exit $?

disconnect "$interface"
remove_previous "$profile"
create_wifi gw "$profile" "$interface" "$ssid" "$password"
activate "$profile"
