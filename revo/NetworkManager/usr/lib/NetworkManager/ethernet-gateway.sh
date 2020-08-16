#!/usr/bin/env bash
#
# @(#) ethernet-gateway.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
# This script creates and activates a NetworkManger WiFi gateway
# profile. Required arguments are as follows:
#
#     profile
#     interface (e.g., wlan0)
#
script_name=${0##*/}
script_dir=${0%/*}

: ${CAT:='/bin/cat'}

source "${script_dir}/ip-funcs.sh"
source "${script_dir}/nm-funcs.sh"

if (( $# < 2 || 4 < $# )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] profile iface [ipv4_addr [ipv4_gateway]]
where:
  -h           - Display help, then exit
  profile      - NetworkManger profile name
  iface        - WiFi interface
  ipv4_addr    - IPv4 address and netmask (e.g., 10.100.0.25/24)
  ipv4_gateway - IPv4 gateway address (e.g., 10.100.0.1)
EOF
    exit 0
fi

declare profile=$1
declare interface=$2
declare ipv4_addr=$3
declare ipv4_gateway=$4

validate_interface "$interface" || exit $?

if test ."$ipv4_addr" != .''; then
    validate_ipv4_address "$ipv4_addr" || exit $?
fi

if test ."$ipv4_gateway" != .''; then
    validate_ipv4_gateway "$ipv4_gateway" || exit $?
fi

disconnect_interface "$interface"
remove_previous_profile "$profile"
create_ethernet_profile gw "$profile" "$interface" "$ipv4_addr" "$ipv4_gateway"
activate_profile "$profile"
