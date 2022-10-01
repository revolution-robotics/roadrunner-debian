#!/usr/bin/env bash
#
# @(#) system-metrics.sh
#
# Copyright © 2022 Revolution Robotics, Inc.
#
# This script displays a summary of system metrics.
#
progress_bar ()
{
    local -i runtime=${1:-60}
    local -i update_interval=${2:-5}

    local dots=''
    local -i dots_max=40
    local -i i=0

    for (( i = 0; i < 100; i += update_interval * 100 / runtime )); do
        dots=$(eval printf ".%.0s" {0..$(( dots_max * i / 100 ))})
        printf "\r%-${dots_max}s(%2d%%)" "${dots%.}" "$i"
        sleep "$update_interval"
    done

    local -i columns=0

    columns=$(
        stty -a </dev/tty |
            sed -n -e '/columns/s/.*columns \([^ ]*\);.*/\1/p'
            ) || return $?

    printf '\r'
    eval printf '=%.0s' {1..$columns}
}

collect_metrics ()
{
    local output_file=$1


    echo >>"$output_file"
    echo "**** BEGIN OUTPUT OF: uptime ****" >>"$output_file"
    uptime >>"$output_file"  || return $?
    echo "**** END OUTPUT OF: uptime ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: dmesg -T ****" >>"$output_file"
    script -qc "dmesg -T" >> "$output_file"  || return $?
    echo "**** END OUTPUT OF: dmesg -T ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: mpstat -P ALL 2 5 ****" >>"$output_file"
    script -qc "mpstat -P ALL 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: mpstat -P ALL 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: mpstat -P ALL -I SCPU,SUM 2 5 ****" >>"$output_file"
    script -qc "mpstat -P ALL -I SCPU,SUM 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: mpstat -P ALL -I SCPU,SUM 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: pidstat 2 5 ****" >>"$output_file"
    script -qc "pidstat 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: pidstat 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: iostat -sxzh 2 5 ****" >>"$output_file"
    script -qc "iostat -sxzh 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: iostat -sxzh 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: free -m ****" >>"$output_file"
    free -m >>"$output_file" || return $?
    echo "**** END OUTPUT OF: free -m ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: sar -n DEV 2 5 ****" >>"$output_file"
    script -qc "sar -n DEV 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: sar -n DEV 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: sar -n TCP,ETCP 2 5 ****" >>"$output_file"
    script -qc "sar -n TCP,ETCP 2 5" >>"$output_file" || return $?
    echo "**** END OUTPUT OF: sar -n TCP,ETCP 2 5 ****" >>"$output_file"
    echo >>"$output_file"

    echo "**** BEGIN OUTPUT OF: vmstat -a -SM 1 10 ****" >>"$output_file"
    vmstat -a -SM 1 10 >>"$output_file"  || return $?
    echo "**** END OUTPUT OF: vmstat -a -SM 1 10 ****" >>"$output_file"
    echo >>"$output_file"
}

if test ."$0" = ."${BASH_SOURCE[0]}"; then
    declare script_name=${0##*/}
    declare -i runtime=60
    declare -i update_interval=5

    declare tmpfile=''

    tmpfile=$(mktemp -p /tmp "${script_name}.XXXXXXX") || exit $?

    trap 'rm -f "$tmpfile"; exit' 0 1 2 15

    echo "Collecting metrics, please wait..."

    declare -i start_time=0
    declare -i progress_bar_pid=0

    start_time=$(date +%s) || exit 1
    progress_bar "$runtime" "$update_interval" &
    progress_bar_pid=$!
    collect_metrics "$tmpfile" || { kill "$progress_bar_pid"; exit 1; }

    declare -i stop_time=0

    stop_time=$(date +%s) || exit 1
    actual_runtime=$(( stop_time - start_time ))
    printf "${script_name} runtime: ${actual_runtime}\n" >>"$tmpfile"

    if (( runtime > actual_runtime )); then
        sleep $(( runtime - actual_runtime ))
    fi

    less -R <"$tmpfile"
fi
