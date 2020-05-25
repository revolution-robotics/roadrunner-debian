#!/usr/bin/env bash
#
# @(#) wifi-funcs.sh
#
# Copyright © 2020, Revolution Robotics, Inc.
#
: ${AWK:='/bin/awk'}
: ${NMCLI:='/bin/nmcli'}
: ${SED:='/bin/sed'}
: ${TR:='/bin/tr'}

declare -a DEVICES

# Save `nmcli' output as array of devices.
mapfile -t DEVICES < <(
    $NMCLI --terse --field GENERAL.DEVICE device show |
        $SED -e '/^$/d' -e 's/.*://'
)

# get_wifi_interface: Return WiFi interface managed by NetworkManager.
get_wifi_interface ()
{
    # interface=$(ls /sys/class/ieee80211/*/device/net/)
    local -a interfaces
    local managed_interface
    local interface
    local device
    local status

    for device in "${DEVICES[@]}"; do
        device_type=$(
            $NMCLI --terse --field GENERAL.TYPE device show "$device" |
                $SED -e 's/.*://'
                   )
        if test ."$device_type" = .'wifi'; then
            interfaces+=($device)
        fi
    done

    if (( ${#interfaces[*]} == 0 )); then
        echo "${FUNCNAME[0]}: WiFi interface not found" >&2
        return 1
    fi

    for interface in "${interfaces[@]}"; do
        status=$($NMCLI | $AWK '/^'$interface':/ { print $2 }')
        if test ."$status" = .'unmanaged'; then
            continue
        else
            managed_interface=$interface
            break
        fi
    done

    if test ."$managed_interface" = .''; then
        echo "${FUNCNAME[0]}: Managed WiFi interface not found" >&2
        return 3
    fi
    echo $managed_interface
}

# validate_ip4_network: Verify that network of given IP4 address doesn't
#     overlap with another interface.
validate_ip4_network ()
{
    local interface=$1
    local ip4_addr=$2

    local device_addr
    local device

    if ! is_ip4_addr "$ip4_addr"; then
        echo "${FUNCNAME[0]}: $ip4_addr: Invalid IP4 address - expecting dotted-quad/netmask" >&2
        return 1
    fi

    for device in "${DEVICES[@]}"; do
        test ."$device" != ."$interface" || continue

        device_addr=$(
            $NMCLI --terse --field IP4.ADDRESS device show "$device" |
                $SED -e 's/.*://'
                   )

        is_ip4_addr "$device_addr" || continue

        if ! network_exclusive "$ip4_addr" "$device_addr"; then
            echo "${FUNCNAME[0]}: $ip4_addr: Address already owned by interface $device" >&2
            return 2
        fi
    done
}

# validate_wifi_interface: Verify that given WiFi interface exists and
#     is managed by NetworkManager.
validate_wifi_interface ()
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

# validate_wifi_band: Verify that band is recognized.
validate_wifi_band ()
{
    local wifi_band=$1

    if ! [[ ."$wifi_band" =~ ^\.(a|bg)$ ]]; then
        echo "${FUNCNAME[0]}: $wifi_band: Band must be either 'a' or 'bg'" >&2
        return 1
    fi
}

# is_active: Return true if given profile is active, otherwise false.
is_active ()
{
    local profile=$1

    local active_state=$($NMCLI --terse -field GENERAL.STATE connection show --active "$profile")

    if test ."$active_state" = .''; then
        return 1
    fi
}

# remove_previous: Remove given profile if it already exists.
remove_previous ()
{
    local con_name=$1

    local -a nm_profile
    local active_state
    local profile

    # Save NetworkManger connection profile names to array `nm_profile'
    # to avoid having to mess with IFS, since the names may contain spaces.
    mapfile -t nm_profile < <($NMCLI --terse --field NAME connection show)
    for profile in "${nm_profile[@]}"; do

        # If profile name conflicts with an existing profile...
        if test ."$profile" = ."$con_name"; then

            # and profile is currently active...
            if is_active "$profile"; then
                echo "${FUNCNAME[0]}: $profile: Shutting down profile" >&2
                $NMCLI connection down "$profile"
            fi

            # Remove existing profile.
            echo "${FUNCNAME[0]}: $profile: Deleting profile" >&2
            $NMCLI connection delete "$profile"
        fi
    done
}

# disconnect: Bring down any connections on the given interface.
disconnect ()
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

# create: Create NetworkManager profile for an access point.
create ()
{
    local mode=$1
    local profile=$2
    local interface=$3
    local ssid=$4
    local password=$5
    local wifi_band=$6
    local ip4_addr=$7

    echo "$NMCLI connection add type wifi con-name "\""$profile"\"" ifname "\""$interface"\"" ssid "\""$ssid"\"""
    $NMCLI connection add type wifi con-name "$profile" ifname "$interface" ssid "$ssid"
    $NMCLI connection modify "$profile" wifi-sec.key-mgmt wpa-psk
    $NMCLI connection modify "$profile" wifi-sec.psk "$password"

    if test ."$mode" = ."ap"; then
        $NMCLI connection modify "$profile" wifi.mode ap
        $NMCLI connection modify "$profile" wifi.band "$wifi_band"
        $NMCLI connection modify "$profile" ipv4.method shared
        $NMCLI connection modify "$profile" wifi-sec.proto rsn
        $NMCLI connection modify "$profile" wifi-sec.group ccmp
        $NMCLI connection modify "$profile" wifi-sec.pairwise ccmp
        $NMCLI connection modify "$profile" ipv4.addr "$ip4_addr"
    fi
}

# activate_ap: Activate given NetworkManager access point profile.
activate ()
{
    local profile=$1

    if test ."$($NMCLI networking connectivity)" != .'full'; then
        echo "Warning: No Internet access"
    fi

    if ! is_active "$profile"; then
        echo "${FUNCNAME[0]}: $profile: Bring up profile" >&2
        $NMCLI radio wifi on
        $NMCLI connection up "$profile"
    fi
}
