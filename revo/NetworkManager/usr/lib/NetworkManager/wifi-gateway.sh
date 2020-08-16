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

if (( $# < 4 || 6 < $# )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] profile iface ssid password [ipv4_addr [ipv4_gateway]]
where:
  -h           - Display help, then exit
  profile      - NetworkManger profile name
  iface        - WiFi interface
  ssid         - Name (SSID) of WiFi network to connect to
  password     - WiFi network password
  ipv4_addr    - IPv4 address and netmask (e.g., 10.100.0.25/24)
  ipv4_gateway - IPv4 gateway address (e.g., 10.100.0.1)
EOF
    exit 0
fi

declare profile=$1
declare interface=$2
declare ssid=$3
declare password=$4
declare ipv4_addr=$5
declare ipv4_gateway=$6

validate_interface "$interface" || exit $?

if test ."$ipv4_addr" != .''; then
    validate_ipv4_address "$ipv4_addr" || exit $?
fi

if test ."$ipv4_gateway" != .''; then
    validate_ipv4_gateway "$ipv4_gateway" || exit $?
fi

disconnect_interface "$interface"
remove_previous_profile "$profile"
create_wifi_profile gw "$profile" "$interface" "$ssid" "$password"
activate_profile "$profile"
