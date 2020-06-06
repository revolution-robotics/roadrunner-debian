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

if (( $# != 2 )) || [[ ."$1" =~ ^\.(-h|--h|-\?) ]]; then
    $CAT <<EOF
Usage: $script_name [-h] profile iface
where:
  -h        - Display help, then exit
  profile   - NetworkManger profile name
  iface     - WiFi interface
EOF
    exit 0
fi

declare profile=$1
declare interface=$2

validate_interface "$interface" || exit $?

disconnect_interface "$interface"
remove_previous_profile "$profile"
create_ethernet_profile gw "$profile" "$interface"
activate_profile "$profile"
