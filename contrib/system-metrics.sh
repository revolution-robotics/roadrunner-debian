#!/usr/bin/env bash
#
# @(#) system-metrics.sh
#
# This script displays a summary of system metrics.
#
declare script_name=${0##*/}

progress_bar ()
{
    declare -i runtime=${1:-60}

    declare dots=''
    declare -i dots_max=40
    declare -i interval=5
    declare -i i=0
    declare -i i_max=$(( (interval * 100 / runtime ) * (100 / (interval * 100 / runtime)) ))
    declare -i columns=$(
        stty -a </dev/tty |
            sed -n -e '/columns/s/.*columns \([^ ]*\);.*/\1/p'
            )

    while (( i < i_max )); do
        sleep $interval
        (( i += interval * 100 / runtime ))
        dots=$(eval printf ".%.0s" {1..$(( dots_max * i / 100 ))})
        printf "\r%-${dots_max}s(%2d%%)" "$dots" "$i"
    done
    printf '\r'
    eval printf '=%.0s' {1..$columns}
}

collect_metrics ()
{
    echo >>"$tmpfile"
    echo "**** BEGIN OUTPUT OF: uptime ****" >>"$tmpfile"
    uptime >>"$tmpfile"
    echo "**** END OUTPUT OF: uptime ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: dmesg -T ****" >>"$tmpfile"
    script -qc "dmesg -T" >> "$tmpfile"
    echo "**** END OUTPUT OF: dmesg -T ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: vmstat -a -SM 1 ****" >>"$tmpfile"
    vmstat -a -SM 1 >>"$tmpfile" &
    sleep 10
    kill $!
    echo "**** END OUTPUT OF: vmstat -a -SM 1 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: mpstat -P ALL 2 5 ****" >>"$tmpfile"
    script -qc "mpstat -P ALL 2 5" >>"$tmpfile"
    echo "**** END OUTPUT OF: mpstat -P ALL 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: mpstat -P ALL -I SCPU,SUM 2 5 ****" >>"$tmpfile"
    script -qc "mpstat -P ALL -I SCPU,SUM 2 5" >>"$tmpfile"
    echo "**** END OUTPUT OF: mpstat -P ALL -I SCPU,SUM 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: pidstat 2 5 ****" >>"$tmpfile"
    script -qc "pidstat 2 5" >>"$tmpfile"
    echo "**** END OUTPUT OF: pidstat 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: iostat -sxzh 2 5 ****" >>"$tmpfile"
    script -qc "iostat -sxzh 2 5" >>"$tmpfile"
    echo "**** END OUTPUT OF: iostat -sxzh 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: free -m ****" >>"$tmpfile"
    free -m >>"$tmpfile"
    echo "**** END OUTPUT OF: free -m ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: sar -n DEV 2 5 ****" >>"$tmpfile"
    script -qc "sar -n DEV 2 5" >>"$tmpfile"
    echo "**** END OUTPUT OF: sar -n DEV 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "**** BEGIN OUTPUT OF: sar -n TCP,ETCP 2 5 ****" >>"$tmpfile"
    script -qc "sar -n TCP,ETCP 2 5" >>"$tmpfile"
    echo "**** BEGIN OUTPUT OF: sar -n TCP,ETCP 2 5 ****" >>"$tmpfile"
    echo >>"$tmpfile"

    echo "$tmpfile"
}

if test ."$0" = ."${BASH_SOURCE[0]}"; then
    declare -i runtime=68
    declare tmpfile=$(mktemp -p /tmp "${script_name}.XXXXX")

    trap 'rm -f "$tmpfile"; exit' 0 1 2 15

    echo "Collectings metrics, please wait..."
    progress_bar $runtime &
    declare -i begin=$(date +%s)
    declare metrics=$(collect_metrics)
    declare -i end=$(date +%s)
    echo "Runtime: $(( end - begin ))s" >>"$metrics"
    wait
    less -R <"$metrics"
fi
