#!/usr/bin/env bash
#
# @(#) mp-build-diskimage
#
# Copyright © 2020 Revolution Robotics, Inc.
#
# This script builds a REVO i.MX7D SD disk image in a multipass VM.
# The resulting image is written to $DEST_DIR on the local host.
#
# NB: Inside the VM, be careful not to overwrite user ubuntu's
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
#     See below for definition of vm_ipv4.
#
script_name=${0##*/}

: ${FLOCK:='/usr/bin/flock'}
: ${VMNAME:='roadrunner'}
: ${BUILD_DIR:='roadrunner_debian'}
: ${OUTPUT_DIR:="${BUILD_DIR}/output"}
: ${DEST_DIR:="${HOME}/output"}
: ${NCPUS:='2'}
: ${DISK_SIZE:='20G'}
: ${MEMORY_SIZE:='2G'}
: ${SSH_PUBKEY:="${HOME}/.ssh/id_rsa.pub"}

#  Avoid multiple instances of this script.
if test ."$0" != ."$LOCKED"; then
    exec env LOCKED=$0 $FLOCK -en "$0" "$0" "$@" || :
fi

# If a $VMNAME instance exists...
if multipass list  | awk 'NR > 1 { print $1 }' | grep -q "$VMNAME"; then

    # Prompt whether to overwrite.
    prompt="$VMNAME: Virtual machine instance already exists. Overwrite [y/N]? "
    if ! read -t 10 -n 1 -p "$prompt" || [[ ! ."$REPLY" =~ \.[yY] ]]; then
        echo
        exit 1
    fi
    multipass umount "$VMNAME"
    multipass stop "$VMNAME"
    multipass delete --purge "$VMNAME"
fi

# Launch VM and mount local $DEST_DIR on VM's $OUTPUT_DIR via SSHFS.
multipass launch --cpus "$NCPUS" --disk "$DISK_SIZE" --mem "$MEMORY_SIZE" --name "$VMNAME" focal
mkdir -p "$DEST_DIR"
multipass exec "$VMNAME" -- mkdir -p "$OUTPUT_DIR"
multipass mount "$DEST_DIR" "${VMNAME}:${OUTPUT_DIR}"

# Enable SSH access, e.g.:
#
#   vm_ipv4=$(multipass list | awk 'NR > 1 && $1 == "'$VMNAME'" { print $3 }')
#   ssh ubuntu@${vm_ipv4}
#
if test -f "$SSH_PUBKEY"; then
    cat "$SSH_PUBKEY" |
        multipass exec "$VMNAME" -- bash -c "cat >>.ssh/authorized_keys"
fi

# Install build script.
cat <<EOF | multipass exec "${VMNAME}" -- bash -c "cat >build_script"
#!/usr/bin/env bash
#
set -e
cd "./$BUILD_DIR"
echo "Installing toolchains and libraries..."
sudo apt update |& tee "/home/ubuntu/${OUTPUT_DIR}/apt.log"
sudo apt install -qy --no-install-recommends autoconf automake autopoint \\
    binfmt-support binutils bison build-essential chrpath cmake \\
    coreutils debootstrap device-tree-compiler diffstat docbook-utils \\
    flex g++ gcc gcc-multilib git-core golang gpart groff help2man \\
    lib32ncurses5-dev libarchive-dev libgl1-mesa-dev libglib2.0-dev \\
    libglu1-mesa-dev libsdl1.2-dev libssl-dev libtool lzop m4 make \\
    mtd-utils python3-git python3-m2crypto qemu qemu-user-static socat \\
    texi2html texinfo u-boot-tools unzip |& tee -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
sudo apt install -qy binutils-arm-linux-gnueabihf |& tee -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
sudo apt install -qy cpp-arm-linux-gnueabihf |& tee -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
sudo apt install -qy gcc-arm-linux-gnueabihf |& tee -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
sudo apt install -qy g++-arm-linux-gnueabihf |& tee -a "/home/ubuntu/${OUTPUT_DIR}/apt.log"
curl -sL https://ftp-master.debian.org/keys/release-10.asc |
    sudo gpg --quiet --import --no-default-keyring \\
    --keyring /usr/share/keyrings/debian-buster-release.gpg
echo "Cloning build suite..."
git init |& tee "/home/ubuntu/${OUTPUT_DIR}/git.log"
git remote add origin https://github.com/revolution-robotics/roadrunner-debian.git |& tee -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
git fetch |& tee -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
git checkout debian_buster_rr01 |& tee -a "/home/ubuntu/${OUTPUT_DIR}/git.log"
echo "Deploying sources..."
MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c deploy |& tee "/home/ubuntu/${OUTPUT_DIR}/deploy.log"
echo "Building all..."
sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -j "$NCPUS" -c all |& tee "/home/ubuntu/${OUTPUT_DIR}/all.log"
echo "Creating disk image..."
echo | sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c diskimage |& tee "/home/ubuntu/${OUTPUT_DIR}/diskimage.log"
echo | sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c usbimage |& tee "/home/ubuntu/${OUTPUT_DIR}/usbimage.log"
echo | sudo MACHINE=revo-roadrunner-mx7 ./revo_make_debian.sh -c provisionimage |& tee "/home/ubuntu/${OUTPUT_DIR}/provisionimage.log"
uptime >"/home/ubuntu/${OUTPUT_DIR}/runtime.log"
EOF

# Run build script.
multipass exec "$VMNAME" -- bash -c 'chmod +x build_script; ./build_script'
echo "Build complete!"
echo "ls -l $DEST_DIR"
ls -l "$DEST_DIR"
