#!/bin/bash
#
# @(#) mp-build-diskimage
#
# Copyright © 2021 Revolution Robotics, Inc.
#
# This script builds a REVO i.MX7D SD disk image in a multipass VM.
# The resulting image is written to $DEST_DIR on the local host.
#
# NB: Inside a VM, be careful not to overwrite user ubuntu's
#     authorized_keys (i.e., ~ubuntu/.ssh/authorized_keys). Multipass
#     is unable to accesses the VM without it.
#
#     In the event authorized_keys is lost, if SSH access is available
#     (see `multipass list` for IP address), authorized_keys can be
#     restored from the host machine via the command:
#
#         sudo ssh-keygen -y -f \
#              /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa |
#             ssh ubuntu@${vm_ipv4} 'cat >>.ssh/authorized_keys'
#
#     See the function `mpip' below for a way of defining of `vm_ipv4'.
#
# Exit immediately on errors
set -eE -o pipefail
shopt -s extglob

declare script_name=${0##*/}
declare use_alt_recoveryfs=${1:-'false'}
declare build_suite_commit=$2

# Edit these ...
: ${VMNAME:='roadrunner'}
: ${CODENAME:='hirsute'}
: ${NPROC:='4'}
: ${DISK_SIZE:='30G'}
: ${MEMORY_SIZE:='4G'}
: ${SSH_PUBKEY:="${HOME}/.ssh/id_ed25519.pub"}
: ${BUILD_SUITE_BRANCH_DEFAULT:='debian_bullseye_rr01'}
: ${BUILD_DIR:='roadrunner_debian'}
: ${OUTPUT_DIR:="${BUILD_DIR}/output"}
: ${DEST_DIR:="${HOME}/output"}

# Command paths
: ${APT:='/usr/bin/apt'}
: ${APT_KEY:='/usr/bin/apt-key'}
: ${AWK:='/usr/bin/awk'}
: ${BASH:='/bin/bash'}
: ${CAT:='/bin/cat'}
: ${CHMOD:='/bin/chmod'}
: ${CURL:='/usr/bin/curl'}
: ${EGREP:='/usr/bin/egrep'}
: ${FIREWALL_CMD:='/usr/bin/firewall-cmd'}
: ${FLOCK:='/usr/bin/flock'}
: ${GIT:='/usr/bin/git'}
: ${GPG:='/usr/bin/gpg'}
: ${GREP:='/usr/bin/grep'}
: ${HEAD:='/usr/bin/head'}
: ${HOSTNAME_CMD:='/bin/hostname'}
: ${LN:='/bin/ln'}
: ${LS:='/bin/ls'}
: ${LSOF:='/usr/bin/lsof'}
: ${MKDIR:='/bin/mkdir'}
: ${MKTEMP:='/usr/bin/mktemp'}
: ${PGREP:='/usr/bin/pgrep'}
: ${RM:='/bin/rm'}
: ${SED:='/bin/sed'}
: ${SSH_KEYGEN:='/usr/bin/ssh-keygen'}
: ${SORT:='/usr/bin/sort'}
: ${SUDO:='/usr/bin/sudo'}
: ${TAIL:='/usr/bin/tail'}
: ${TEE:='/usr/bin/tee'}
: ${UNAME:='/usr/bin/uname'}

: ${TTY:="$(tty)"}
: ${LOCKED:=''}

# Script not piped to bash ...
if test -t 0; then

    # And `flock' available ...
    if test -x "$FLOCK" -a ."$0" != ."$LOCKED"; then

        #  Avoid running multiple instances of this script.
        exec env ACNG_PROXY_URL=$ACNG_PROXY_URL LOCKED=$0 $FLOCK -en "$0" "$0" "$@" || true
    fi
else

    # TTY not exported ...
    if [[ ! ."$TTY" =~ \./dev/ ]]; then
        echo "$script_name: TTY must be exported before running this script:"
        echo "export TTY=\$(tty);"
        exit 1
    fi
fi

initialize-multipass-zone ()
{
    if $FIREWALL_CMD --get-zones | grep -q multipass; then
        return 0
    fi

    $SUDO $FIREWALL_CMD --permanent --new-zone=multipass

    $SUDO $FIREWALL_CMD --permanent --zone=multipass                          \
          --set-short='Firewall zone for multipass virtual machines'

    $SUDO $FIREWALL_CMD --permanent --zone=multipass                          \
          --set-description='
    The default policy of "ACCEPT" allows all packets to/from
    interfaces in the zone to be forwarded, while the (*low priority*)
    reject rule blocks any traffic destined for the host, except those
    services explicitly listed (that list can be modified as required
    by the local admin). This zone is intended to be used only by
    multipass virtual networks - multipass will add the bridge devices for
    all new virtual networks to this zone by default.
'

    $SUDO $FIREWALL_CMD --permanent --zone=multipass                          \
          --set-target=ACCEPT

    $SUDO $FIREWALL_CMD --reload

    $SUDO $FIREWALL_CMD --zone=multipass                                      \
          --add-service=dhcp                                                  \
          --add-service=dhcpv6                                                \
          --add-service=dns                                                   \
          --add-service=ssh                                                   \
          --add-service=tftp

    $SUDO $FIREWALL_CMD --zone=multipass                                      \
          --add-protocol=icmp                                                 \
          --add-protocol=ipv6-icmp

    $SUDO $FIREWALL_CMD --zone=multipass                                      \
          --add-rich-rule='rule priority="32767" reject'

    $SUDO $FIREWALL_CMD --runtime-to-permanent
}

populate-multipass-zone ()
{
    local interface=$1

    $SUDO $FIREWALL_CMD --zone=multipass --change-interface=$interface
}

# Return latest GIT repository tag of the form vX.Y.Z.
get-current-tag ()
{
    local uri=$1

    # GIT output format:
    # 5fe6c967a5ccea411eb1cf109e6af7ef6cdee311	refs/tags/v1.2.1
    # c80b31f6dbd956562ee723cd45ad593e9171b0e9	refs/tags/v1.2.1^{}
    # 482c2489abbd021c7a23e7c5c44bd01d5c31dd0c	refs/tags/v1.3.0
    # 6be5d9c067ecbd256af506e4d98d7454d9ea68e8	refs/tags/v1.3.0^{}
    # f1d51cd8f8918178292795bbd3235184e7bca09d	refs/tags/v1.3.0-dev
    # 99276d6140b97ef6b3bbcda07f0fb444f20430da	refs/tags/v1.3.0-rc
    #
    # After filtering and sorting:
    #     v1.2.1
    #     v1.3.0
    $GIT ls-remote --tags "$uri" |
        $EGREP -v -- '-|\{\}|/[0-9]'  |
        $SED -e 's;.*refs/tags/;;' |
        $SORT --version-sort -k1.2 |
        $TAIL -1
}

declare prompt
declare status
declare system=$($UNAME -s)
declare toplevel_dir=$(git rev-parse --show-toplevel)

case "$system" in
    Linux)
        : ${MULTIPASS:='/snap/bin/multipass'}
        : ${NMCLI:='/usr/bin/nmcli'}
        : ${SNAP:='/usr/bin/snap'}

        if test ! -x "$MULTIPASS"; then
            if test -x "$SNAP"; then
                echo "Installing multipass ..."
                $SUDO $SNAP install multipass --classic
            else
                echo "$script_name: multipass: Command not available" >&2
                exit 1
            fi
        fi
        if test ! -x "$NMCLI"; then
            echo "$script_name: NetworkManager: Not running" >&2
            exit 1
        fi
        declare host_gw_if=$(
            $NMCLI |
                $AWK -F':' '/^[^[:blank:]/]+:/ { iface=$1 }
                   /ip4 default/ { exit }
                   END { print iface }'
                  )
        declare host_gw_ipv4=$($NMCLI --get-values 'ip4.address' device show "$host_gw_if")

        if test -f /etc/redhat-release &&
                [[ ."$(< /etc/redhat-release)" =~ ^\.Fedora ]]; then
            initialize-multipass-zone
            populate-multipass-zone mpqemubr0
        fi
        ;;
    Darwin)

        : ${MULTIPASS:='/Library/Application Support/com.canonical.multipass/bin/multipass'}
        : ${OPEN:='/usr/bin/open'}
        : ${SCUTIL:='/usr/sbin/scutil'}

        if test ! -x "$MULTIPASS"; then
            declare uri='https://github.com/canonical/multipass'
            declare tag=$(get-current-tag "$uri")
            declare release="releases/download/${tag}/multipass-${tag#v}+mac-Darwin.pkg"
            declare tmpdir=$($MKTEMP -d "/tmp/${script_name}.XXXXX")

            trap 'rm -rf "$tmpdir"; exit' 0 1 2 15

            echo "Initiating Multipass install ..."
            cd "$tmpdir"

            $CURL -sS -C - -LO "${uri}/${release}"
            $OPEN "${release##*/}"

            prompt="After completing install, please return here, and then press any key to
continue or CTRL + C to cancel ..."

            read -p "$prompt" -n 1 <"$TTY"
            cd "$OLDPWD"
            $RM -r "$tmpdir"

            trap - 0 1 2 15

            if test ! -x "$MULTIPASS"; then
                echo "$script_name: multipass: Command not available" >&2
                exit 1
            fi

            # Add `multipass' to command-line PATH.
            $SUDO $LN -sf "$MULTIPASS" /usr/bin
        fi
        declare host_gw_ipv4=$(
            $SCUTIL --nwi |
                $AWK '/address/ { print $3 }' |
                $HEAD -1
                  )
        ;;
    *)
        echo "$script_name: $system: Unsupported system" >&2
        exit 1
        ;;
esac

declare debian_proxy=''

if test ."${ACNG_PROXY_URL}" != .''; then
    debian_proxy="-p ${ACNG_PROXY_URL}"
else
    ACNG_PROXY_URL=http://${host_gw_ipv4%/*}:3142/deb.debian.org/debian/

    # If both `pgrep' and `lsof' are available ...
    if test -x "$PGREP" -a -x "$LSOF"; then

        # If `apt-cacher-ng' is listening on localhost:3142
        if  $PGREP apt-cacher-ng >/dev/null &&
                $SUDO $LSOF -ti :3142 >/dev/null; then
            debian_proxy="-p ${ACNG_PROXY_URL}"
        fi
    fi
fi

# If a $VMNAME instance exists ...
declare -a vmstate=( $($MULTIPASS list | $AWK '/^'$VMNAME' / { print $1, $2 }') )

if (( ${#vmstate[*]} == 2 )) && test ."${vmstate[1]}" != .'Deleted'; then

    # Prompt whether to overwrite.
    prompt="$VMNAME: Virtual machine instance already exists. Overwrite [y/N]? "
    read -t 10 -n 1 -p "$prompt" <"$TTY"
    status=$?
    if (( status == 0 )) && [[  ."$REPLY" =~ \.[yY] ]]; then
        if test ."${vmstate[1]}" = .'Running'; then
            "$MULTIPASS" umount "$VMNAME"
            "$MULTIPASS" stop "$VMNAME"
        fi
        "$MULTIPASS" delete --purge "$VMNAME"
        "$MULTIPASS" launch --cpus "$NPROC" --disk "$DISK_SIZE" \
                     --mem "$MEMORY_SIZE" --name "$VMNAME" "$CODENAME"
    else
        echo
        prompt="$VMNAME will not be overwritten. Proceed with build [y/N]? "
        read -t 10 -n 1 -p "$prompt" <"$TTY"
        status=$?
        if (( status != 0 )) || [[  ! ."$REPLY" =~ \.[yY] ]]; then
             printf "\nTerminating build.\n" >&2
            exit
        fi
    fi

# Launch VM and mount local $DEST_DIR on VM's $OUTPUT_DIR via SSHFS.
else
    if test ."${vmstate[1]}" = .'Deleted'; then
        "$MULTIPASS" purge
    fi
    "$MULTIPASS" launch --cpus "$NPROC" --disk "$DISK_SIZE" \
                 --mem "$MEMORY_SIZE" --name "$VMNAME" "$CODENAME"
fi

# Multipass evidently consumes/flushes stdin here, so redirect $TTY as
# a workaround when piping this script to bash.
$MKDIR -p "$DEST_DIR"
"$MULTIPASS" exec "$VMNAME" -- $MKDIR -p "$OUTPUT_DIR" <"$TTY"
"$MULTIPASS" mount "$DEST_DIR" "${VMNAME}:${OUTPUT_DIR}" <"$TTY"

# Enable SSH access, e.g.:
#
#   mpip() {
#       vmname=${1:-'roadrunner'}
#       "$MULTIPASS" list | awk 'NR > 1 && $1 == "'$vmname'" { print $3 }'
#   }
#
#   ssh ubuntu@$(mpip $VMNAME)
#
if test ! -f "$SSH_PUBKEY"; then
    echo "Generating SSH certificate"
    $SSH_KEYGEN -t rsa -b 4096 -C "${USER}@${HOSTNAME}" -P '' \
        -f "${SSH_PUBKEY%.pub}"
fi

if test -f "$SSH_PUBKEY"; then
    $CAT "$SSH_PUBKEY" |
        "$MULTIPASS" exec "$VMNAME" -- $BASH -c "$CAT >>.ssh/authorized_keys"
fi

# Add host to guest's /etc/hosts
$CAT <<EOF | "$MULTIPASS" exec "$VMNAME" -- $SUDO $BASH -c "$CAT >>/etc/hosts"
# localhosts
${host_gw_ipv4%/*} $HOSTNAME
EOF

# If apt-cacher-ng proxy available, add it to the VM's apt configuration.
if [[ ."${debian_proxy}" =~ \.-p\ (.*:[0-9]+) ]]; then
    $CAT <<EOF | "$MULTIPASS" exec "$VMNAME" -- $SUDO $BASH -c "$CAT >>/etc/apt/apt.conf.d/10acng-proxy"
Acquire::http::Proxy "${BASH_REMATCH[1]}";
EOF
fi

# Add bash aliases...
echo "alias h='history 50'" |
        "$MULTIPASS" exec "$VMNAME" -- $BASH -c "$CAT >>.bashrc"

# Install build script.
$CAT <<EOF | "$MULTIPASS" exec "${VMNAME}" -- $BASH -c "$CAT >build_script"
#!/bin/bash
#
set -e
cd "./$BUILD_DIR"
echo "Installing toolchains and libraries..."
$SUDO $APT update |& $TEE "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $APT install -qy autoconf automake autopoint \\
    binfmt-support binutils bison build-essential cmake \\
    coreutils debootstrap device-tree-compiler diffstat \\
    flex g++ gcc git golang gpart groff help2man \\
    libssl-dev libtool lzop m4 make qemu qemu-user-static \\
    u-boot-tools unzip upx-ucl |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $APT install -qy binutils-arm-linux-gnueabihf |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $APT install -qy cpp-arm-linux-gnueabihf |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $APT install -qy gcc-arm-linux-gnueabihf |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $APT install -qy g++-arm-linux-gnueabihf |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
$SUDO $CURL -sLo /usr/bin/install-smallstep \\
    "https://raw.githubusercontent.com/revolution-robotics/roadrunner-debian/debian_bullseye_rr01/revo/resources/smallstep/install-smallstep"
$SUDO $CHMOD 0755 /usr/bin/install-smallstep
install-smallstep
$CURL -sL https://ftp-master.debian.org/keys/release-11.asc |
    $SUDO $GPG --import --no-default-keyring \\
        --keyring /usr/share/keyrings/debian-bullseye-release.gpg
echo "Cloning build suite..."
$GIT init |& $TEE "/home/ubuntu/${OUTPUT_DIR}/git.log"
$GIT remote add origin https://github.com/revolution-robotics/roadrunner-debian.git |&
    $TEE -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
$GIT fetch |& $TEE -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
if test ."$build_suite_commit" != .''; then
    $GIT checkout -b "commit-${build_suite_commit:0:6}" "$build_suite_commit" |&
        $TEE -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
else
    $GIT checkout "$BUILD_SUITE_BRANCH_DEFAULT" |&
        $TEE -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
fi
echo "Deploying sources..."
CA_URL=\$CA_URL CA_FINGERPRINT=\$CA_FINGERPRINT MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy |& $TEE "/home/ubuntu/${OUTPUT_DIR}/deploy.log"
echo "Building all..."
if $use_alt_recoveryfs; then
    $SUDO -E CA_URL=\$CA_URL CA_FINGERPRINT=\$CA_FINGERPRINT MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -a -j "$NPROC" ${debian_proxy} -c all |&
        $TEE "/home/ubuntu/${OUTPUT_DIR}/all.log"
else
    $SUDO -E CA_URL=\$CA_URL CA_FINGERPRINT=\$CA_FINGERPRINT MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -j "$NPROC" ${debian_proxy} -c all |&
        $TEE "/home/ubuntu/${OUTPUT_DIR}/all.log"
fi
echo "Creating disk image..."
echo | $SUDO -E MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage |&
    $TEE "/home/ubuntu/${OUTPUT_DIR}/diskimage.log"
echo | $SUDO -E MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c usbimage |&
    $TEE "/home/ubuntu/${OUTPUT_DIR}/usbimage.log"
echo | $SUDO -E MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c provisionimage |&
    $TEE "/home/ubuntu/${OUTPUT_DIR}/provisionimage.log"
uptime >"/home/ubuntu/${OUTPUT_DIR}/runtime.log"
EOF

# Run build script.
"$MULTIPASS" exec "$VMNAME" -- $BASH -c 'chmod +x build_script'
sops exec-env "${toplevel_dir}/config/secrets.enc.json" \
     "$MULTIPASS exec $VMNAME -- $BASH -c \"env CA_URL=\$CA_URL CA_FINGERPRINT=\$CA_FINGERPRINT ./build_script\""
echo "Build complete!"
echo "$LS -l $DEST_DIR"
$LS -l "$DEST_DIR"
