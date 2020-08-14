#!/usr/bin/env bash
#
# @(#) nm-funcs.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
: ${AWK:='/bin/awk'}
: ${NMCLI:='/bin/nmcli'}
: ${SED:='/bin/sed'}
: ${TR:='/bin/tr'}

# Access points use base address 10.X.0.1 where X is WIFI_CLASS_B or
# ETHERNET_CLASS_B.
declare -ri WIFI_CLASS_B=100
declare -ri ETHERNET_CLASS_B=200

# activate_profile: Activate given NetworkManager profile.
activate_profile ()
{
    local profile=$1

    if is_shared_profile "$profile" && ! internet_accessible; then
        echo "${FUNCNAME[0]}: Warning: No Internet access" >&2
    fi

    if ! is_active_profile "$profile"; then
        echo "${FUNCNAME[0]}: $profile: Bring up profile" >&2
        if is_wifi_profile "$profile"; then
            $NMCLI radio wifi on
        fi
        $NMCLI connection up "$profile"
    fi
}

# create_ethernet_profile: Create NetworkManager Ethernet profile.
#     Mode is either `ap' for an access point or `gw' for a gateway.
create_ethernet_profile ()
{
    local mode=$1
    local profile=$2
    local interface=$3
    local ipv4_addr=$4
    local ipv4_gateway=$5

    echo "$NMCLI connection add type ethernet con-name "\""$profile"\"" ifname "\""$interface"\""" >&2
    $NMCLI connection add type ethernet con-name "$profile" ifname "$interface"

    if test ."$ipv4_addr" != .''; then
        $NMCLI connection modify "$profile" ipv4.addresses "$ipv4_addr"
    fi

    if test ."mode" != .'ap' -a ."$ipv4_gateway" != .''; then
        $NMCLI connection modify "$profile" ipv4.gateway "$ipv4_gateway"
    fi

    if test ."$mode" = .'ap'; then
        $NMCLI connection modify "$profile" ipv4.method shared
    fi
}

# create_wifi_profile: Create NetworkManager WiFi profile.
#     Mode is either `ap' for an access point or `gw' for a gateway.
create_wifi_profile ()
{
    local mode=$1
    local profile=$2
    local interface=$3
    local ssid=$4
    local password=$5
    local wifi_band=$6
    local ipv4_addr=$7

    echo "$NMCLI connection add type wifi con-name "\""$profile"\"" ifname "\""$interface"\"" ssid "\""$ssid"\"""
    $NMCLI connection add type wifi con-name "$profile" ifname "$interface" ssid "$ssid"
    $NMCLI connection modify "$profile" wifi-sec.key-mgmt wpa-psk
    $NMCLI connection modify "$profile" wifi-sec.psk "$password"

    if test ."$ipv4_addr" != .''; then
        $NMCLI connection modify "$profile" ipv4.addresses "$ipv4_addr"
    fi

    if test ."mode" != .'ap' -a ."$ipv4_gateway" != .''; then
        $NMCLI connection modify "$profile" ipv4.gateway "$ipv4_gateway"
    fi

    if test ."$mode" = ."ap"; then
        $NMCLI connection modify "$profile" wifi.mode ap
        $NMCLI connection modify "$profile" wifi.band "$wifi_band"
        $NMCLI connection modify "$profile" ipv4.method shared
        $NMCLI connection modify "$profile" wifi-sec.proto rsn
        $NMCLI connection modify "$profile" wifi-sec.group ccmp
        $NMCLI connection modify "$profile" wifi-sec.pairwise ccmp
    fi
}

# disconnect_interface: Bring down any connection on the given interface.
disconnect_interface ()
{
    local interface=$1

    local profile=$(
        $NMCLI --terse connection show --active |
            $AWK -F: '$4 == "'$interface'" { print $1 }'
          )

    if test ."$profile" != .''; then
        echo "${FUNCNAME[0]}: $profile: Shutting down profile" >&2
        $NMCLI connection down "$profile"
    fi
}

# get_active_profiles: Return list of active NetworkManager profiles.
get_active_profiles ()
{
    local interface_type=$1

    $NMCLI --terse --fields NAME,TYPE connection show --active |
        $AWK -F : '$2 ~ /'"$interface_type"'/ { print $1 }'
}

# get_all_interfaces: Return list of interfaces known to NetworkManager.
get_all_interfaces ()
{
    $NMCLI --terse --fields GENERAL.DEVICE device show |
        $SED -e '/^$/d' -e 's/.*://'
}

# get_managed_interfaces: Return list of interfaces managed by NetworkManager.
get_managed_interfaces ()
{
    local interface_type=$1

    local -a devices
    local -a interfaces
    local managed_interface
    local interface
    local device
    local status

    mapfile -t devices < <(get_all_interfaces)

    for device in "${devices[@]}"; do
        device_type=$(
            $NMCLI --terse --fields GENERAL.TYPE device show "$device" |
                $SED -e 's/.*://'
                   )
        if test ."$device_type" = ."$interface_type"; then
            interfaces+=($device)
        fi
    done

    if (( ${#interfaces[*]} == 0 )); then
        echo "${FUNCNAME[0]}: ${interface_type^} interface not found" >&2
        return 1
    fi

    for interface in "${interfaces[@]}"; do
        status=$($NMCLI | $AWK '/^'$interface':/ { print $2 }')
        if test ."$status" = .'unmanaged'; then
            continue
        else
            echo $interface
        fi
    done
}

# network_accessible: Return true if network accessible, otherwise false.
network_accessible ()
{
    local status=$($NMCLI networking connectivity check)

    test ."$status" != .'none' && test ."$status" != .'unknown'
}

# internet_accessible: Return true if internet accessible, otherwise false.
internet_accessible ()
{
    local status=$($NMCLI networking connectivity check)

    test ."$status" = .'full'
}

# is_active_profile: Return true if given profile is active, otherwise false.
is_active_profile ()
{
    local profile=$1

    local active_state=$($NMCLI --terse -fields GENERAL.STATE connection show --active "$profile")

    if test ."$active_state" = .''; then
        return 1
    fi
}

# is_connected_interface: Return true if given interface is connected,
#     otherwise false.
is_connected_interface ()
{
    local interface=$1

    local profile=$(
        $NMCLI --terse --fields GENERAL.CONNECTION  device show "$interface" |
            $AWK -F: '{ print $2 }'
          )
    test ."$profile" != .''
}

# is_ethernet_interface: Return true if given interface is ethernet,
#     otherwise false.
is_ethernet_interface ()
{
    local interface=$1

    local status=$(
        $NMCLI --terse --fields GENERAL.TYPE device show "$interface" |
            $AWK -F : '{ print $2 }'
        )
    test ."$status" = .'ethernet'
}

# is_share_profile: Return true if given profile is shared, otherwise false.
is_shared_profile ()
{
    local profile=$1

    local status=$(
        $NMCLI --terse --fields ipv4.method connection show "$profile" |
            $AWK -F : '{ print $2 }'
        )
    test ."$status" = .'shared'
}

# is_wifi_profile: Return true if given profile is wifi, otherwise false.
is_wifi_profile ()
{
    local profile=$1

    local status=$(
        $NMCLI --terse --fields connection.type connection show "$profile" |
            $AWK -F : '{ print $2 }'
        )
    test ."$status" = .'802-11-wireless'
}

# remove_previous_profile: Remove given profile if it already exists.
remove_previous_profile ()
{
    local con_name=$1

    local -a nm_profile
    local active_state
    local profile

    # Save NetworkManger connection profile names to array `nm_profile'.
    mapfile -t nm_profile < <($NMCLI --terse --fields NAME connection show)
    for profile in "${nm_profile[@]}"; do

        # If profile name conflicts with an existing profile...
        if test ."$profile" = ."$con_name"; then

            # and profile is currently active...
            if is_active_profile "$profile"; then
                echo "${FUNCNAME[0]}: $profile: Shutting down profile" >&2
                $NMCLI connection down "$profile"
            fi

            # Remove existing profile.
            echo "${FUNCNAME[0]}: $profile: Deleting profile" >&2
            $NMCLI connection delete "$profile"
        fi
    done
}

# validate_interface: Verify that given interface exists and is
#     managed by NetworkManager.
validate_interface ()
{
    local interface=$1

    local exists=$($NMCLI --terse device | $AWK -F : '$1 == "'$interface'" { print $1 }')
    local status=$($NMCLI | $AWK '/^'$interface':/ { print $2 }')

    if test ."$exists" = .''; then
        echo "${FUNCNAME[0]}: $interface: Not a valid interface" >&2
        return 1
    elif test ."$status" = .'unmanaged'; then
        echo "${FUNCNAME[0]}: $interface: Unmanaged interface" >&2
        return 2
    fi
}

# validate_ipv4_address: Verify format of given IPv4 address.
validate_ipv4_address ()
{
    local ipv4_addr=$1

    if ! is_ipv4_addr "$ipv4_addr"; then
        echo "${FUNCNAME[0]}: $ipv4_addr: Invalid IPv4 address - expecting dotted-quad/netmask" >&2
        return 1
    fi
}

# validate_ipv4_gateway: Verify format of given dotted quad.
validate_ipv4_address ()
{
    local dotted_quad=$1

    if ! is_dotted_quad "$dotted_quad"; then
        echo "${FUNCNAME[0]}: $dotted_quad: Invalid IPv4 address - expecting dotted-quad" >&2
        return 1
    fi
}

# validate_ipv4_network: Verify that network of given IPv4 address doesn't
#     overlap with another interface.
validate_ipv4_network ()
{
    local interface=$1
    local ipv4_addr=$2

    local -a devices
    local device_addr
    local device

    if ! is_ipv4_addr "$ipv4_addr"; then
        echo "${FUNCNAME[0]}: $ipv4_addr: Invalid IPv4 address - expecting dotted-quad/netmask" >&2
        return 1
    fi

    mapfile -t devices < <(get_all_interfaces)

    for device in "${devices[@]}"; do
        test ."$device" != ."$interface" || continue

        device_addr=$(
            $NMCLI --terse --fields IP4.ADDRESS device show "$device" |
                $SED -e 's/.*://'
                   )

        is_ipv4_addr "$device_addr" || continue

        if ! network_exclusive "$ipv4_addr" "$device_addr"; then
            echo "${FUNCNAME[0]}: $ipv4_addr: Address already owned by interface $device" >&2
            return 2
        fi
    done
}

# validate_wifi_band: Verify that band is recognized.
validate_wifi_band ()
{
    local wifi_band=$1

    if ! [[ ."$wifi_band" =~ ^\.(a|bg)$ ]]; then
        echo "${FUNCNAME[0]}: $wifi_band: Band must be either 'a' or 'bg'" >&2
        return 1
    fi
}
