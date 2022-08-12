#!/usr/bin/env bash
#
# @(#) revo-wifi-common.sh
#
source /etc/wifi/revo-wifi.conf

MX7_5G_FILE=/etc/wifi/wifi-5g

# Check is SOM is VAR-SOM-MX7-5G
som_is_mx7_5g ()
{
    # Check is SoC is i.MX7
    grep -q MX7 /sys/devices/soc0/soc_id || return -1

    # If WIFI type was already detected, use it
    if test -f "$MX7_5G_FILE"; then
        return 0
    fi

    # Check that WIFI SDIO ID file exists
    if  test ! -f "$WIFI_SDIO_ID_FILE"; then
        return 1
    fi

    # Check WIFI chip SDIO ID
    test ."$(< $WIFI_SDIO_ID_FILE)" = ."$WIFI_5G_SDIO_ID"
}

cache_mx7_5g ()
{
    grep -q MX7 /sys/devices/soc0/soc_id || return

    for i in {1..10}; do
        if test -f "$WIFI_SDIO_ID_FILE"; then
            if test ."$(< $WIFI_SDIO_ID_FILE)" = ."$WIFI_5G_SDIO_ID"; then
                touch "$MX7_5G_FILE"
                sync
            fi
            break
        fi
        sleep 0.5
    done
}

# Power up WiFi chip
wifi_up ()
{
    # Unbind WIFI device from MMC controller
    if test -e "/sys/bus/platform/drivers/sdhci-esdhc-imx/${WIFI_MMC_HOST}"; then
        echo "$WIFI_MMC_HOST" > /sys/bus/platform/drivers/sdhci-esdhc-imx/unbind
    fi

    # WLAN_EN up
    echo 1 > "/sys/class/gpio/gpio${WIFI_EN_GPIO}/value"

    # BT_EN up
    echo 1 > "/sys/class/gpio/gpio${BT_EN_GPIO}/value"

    # Wait 150ms at least
    sleep 0.2

    # BT_EN down
    echo 0 > "/sys/class/gpio/gpio${BT_EN_GPIO}/value"

    # Bind WiFi device to MMC controller
    echo "$WIFI_MMC_HOST" > /sys/bus/platform/drivers/sdhci-esdhc-imx/bind

    # If found MX7-5G remember it
    cache_mx7_5g

    # Load WiFi kernel module
    modprobe brcmfmac
}

# Power down WiFi chip
wifi_down ()
{
    # Unload WiFi driver
    modprobe -r brcmfmac

    # Unbind WiFi device from MMC controller
    if test -e "/sys/bus/platform/drivers/sdhci-esdhc-imx/${WIFI_MMC_HOST}"; then
        echo "$WIFI_MMC_HOST" > /sys/bus/platform/drivers/sdhci-esdhc-imx/unbind
    fi

    # WLAN_EN down
    echo 0 > "/sys/class/gpio/gpio${WIFI_EN_GPIO}/value"

    # BT_EN down
    echo 0 > "/sys/class/gpio/gpio${BT_EN_GPIO}/value"
}
