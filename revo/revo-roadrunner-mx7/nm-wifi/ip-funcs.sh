#!/usr/bin/env bash
#
# @(#) ip-funcs.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
shopt -s extglob

# Constants and masks for network ops
declare -i ONE_BYTE_MASK=$(( ( 1 << 8 ) - 1 ))
declare -i TWO_BYTE_MASK=$(( ( 1 << 16 ) - 1 ))
declare -i THREE_BYTE_MASK=$(( ( 1 << 24 ) - 1 ))
declare -i FOUR_BYTE_MASK=$(( ( 1 << 32 ) - 1 ))

# is_ip4_addr: Sanity check IP4 address.  Expected format: dotted-quad/netmask,
#     e.g., 192.168.0.1/24
is_ip4_addr ()
{
    local ip4_addr=$1

    local quad=${ip4_addr%/*}
    local mask=${ip4_addr#*/}

    is_dotted_quad "$quad" &&
        [[ ."$mask" =~ ^\.(0|[1-9]|[12][0-9]|3[0-2])$ ]]
}

# is_dotted_quad: Sanity check given dotted quad,
#     e.g., 255.255.255.0
is_dotted_quad ()
{
    local quad=$1
    local num

    OIFS=$IFS
    IFS='.'
    set -- $quad
    IFS=$OIFS

    [ $# -eq 4 ] || return 1
    for num; do
        [[ ."$num" =~ ^\.(0|[1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]] || return 1
    done
}

# inet_aton: Convert quad-dotted to 32-bit number,
#     e.g., 10.0.0.1 => 167772161
inet_aton ()
{
    local quad=$1

    local -i ip_no=0
    local -i class_no

    while test ."$quad" != .''; do
        class_no=${quad%%.*}
        ip_no=$(( ip_no << 8 | class_no ))
        quad=${quad/$class_no?(.)}
    done
    echo "$ip_no"
}

# inet_mask_ntoa: Convert netmask size to dotted-quad,
#     e.g., 24 => 255.255.255.0
inet_mask_ntoa ()
{
    local -i mask=$1

    local mask_complement=$(( ( 1 << ( 32 - mask ) ) - 1 ))
    local b4=$(( ( FOUR_BYTE_MASK & ~ mask_complement ) >> 24 ))
    local b3=$(( ( THREE_BYTE_MASK & ~ mask_complement ) >> 16 ))
    local b2=$(( ( TWO_BYTE_MASK & ~ mask_complement ) >> 8 ))
    local b1=$(( ( ONE_BYTE_MASK & ~ mask_complement ) >> 0 ))
    echo "$b4.$b3.$b2.$b1"
}

# inet_ntoa: Convert 32-bit number to dotted-quad,
#     e.g., 167772161 => 10.0.0.1
inet_ntoa ()
{
    local -i ip_no=$1

    local -a quad

    while (( ip_no > 0 )); do
        quad+=( $(( ip_no & ONE_BYTE_MASK )) )
        ip_no=$(( ip_no >> 8 ))
    done
    echo "${quad[3]:=0}.${quad[2]:=0}.${quad[1]:=0}.${quad[0]:=0}"
}

# network_exclusive: Given two IP4 addresses, check if either is in the
#     other's network. Expected format: dotted-quad/netmask,
#     e.g., 10.0.0.1/24
network_exclusive ()
{
    local ip4_addr1=$1
    local ip4_addr2=$2

    quad1=${ip4_addr1%/*}
    mask1=${ip4_addr1##*/}
    quad2=${ip4_addr2%/*}
    mask2=${ip4_addr2##*/}

    nq1=$(inet_aton "$quad1")
    qm1=$(inet_mask_ntoa "$mask1")
    nm1=$(inet_aton "$qm1")

    nq2=$(inet_aton "$quad2")
    qm2=$(inet_mask_ntoa "$mask2")
    nm2=$(inet_aton "$qm2")

    # addr2 in network1 and addr1 in network2
    if (( (nq1 & nm1) == (nq2 & nm1) )) && (( (nq1 & nm2) == (nq2 & nm2) )); then
        return 1
    # addr2 in network1
    elif (( (nq1 & nm1) == (nq2 & nm1) )); then
        return 2
    # addr1 in network2
    elif (( (nq1 & nm2) == (nq2 & nm2) )); then
        return 3
    fi
}
