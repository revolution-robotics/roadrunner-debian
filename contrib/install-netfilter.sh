#!/usr/bin/env bash
#
# @(#) install-netfilter.sh
#
# This script is intended to be run chrooted to Roadrunner rootfs
# post-debootstrap (see contrib/mp-build-diskimage.sh). After building
# the packages, the `*.deb' files can be installed in their respective
# directories of the roadrunner_debian repositry under `revo/deb/'.
#
# Chroot from the root of roadrunner_debian repository to rootfs:
#
#    contrib/chrootfs.sh rootfs
#
apt update

apt install asciidoc-base bison devscripts doxygen flex libbsd-dev            \
    libgmp-dev libjansson-dev libmnl-dev                  \
    libnetfilter-conntrack-dev libnfnetlink-dev libnftnl-dev libnftnl-dev     \
    libxtables-dev python3-all

parentdir=/usr/src/iptables
mkdir -p "$parentdir"
git -C "$parentdir" clone \
    https://salsa.debian.org/pkg-netfilter-team/pkg-iptables.git
cd "${parentdir}/pkg-iptables"
version=$(sed -n -e '{s/.*(//;s/).*//;s/-[^-]*$//;p;q}' debian/changelog)
mv debian ../
git archive --format=tar --prefix="iptables_${version}/" master |
    xz - >"../iptables_${version}.orig.tar.xz"
mv ../debian .
dpkg-buildpackage -uc -us
cd ..
install -m 0644 *.deb /srv/local-apt-repository/

parentdir=/usr/src/libnftnl
mkdir -p "$parentdir"
git -C "$parentdir" clone \
    https://salsa.debian.org/pkg-netfilter-team/pkg-libnftnl.git
cd "${parentdir}/pkg-libnftnl"
version=$(sed -n -e '{s/.*(//;s/).*//;s/-[^-]*$//;p;q}' debian/changelog)
mv debian ../
git archive --format=tar --prefix="libnftnl_${version}/" master |
    xz - >"../libnftnl_${version}.orig.tar.xz"
mv ../debian .
dpkg-buildpackage -uc -us
cd ..
install -m 0644 *.deb /srv/local-apt-repository/

parentdir=/usr/src/libedit
mkdir -p "$parentdir"
git -C "$parentdir" clone \
     https://salsa.debian.org/debian/libedit.git
cd "${parentdir}/libedit"
version=$(sed -n -e '{s/.*(//;s/).*//;s/-[^-]*$//;p;q}' debian/changelog)
mv debian ../
git archive --format=tar --prefix="libnftnl_${version}/" master |
    xz - >"../libnftnl_${version}.orig.tar.xz"
mv ../debian .
dpkg-buildpackage -uc -us
cd ..
install -m 0644 *.deb /srv/local-apt-repository/

apt update
sudo apt install libeditreadline-dev

parentdir=/usr/src/nftables
mkdir -p "$parentdir"
git -C "$parentdir" clone \
      https://salsa.debian.org/pkg-netfilter-team/pkg-nftables.git
cd "${parentdir}/pkg-nftables"
version=$(sed -n -e '{s/.*(//;s/).*//;s/-[^-]*$//;p;q}' debian/changelog)
mv debian ../
git archive --format=tar --prefix="nftables_${version}/" master |
    xz - >"../nftables_${version}.orig.tar.xz"
mv ../debian .
dpkg-buildpackage -uc -us
cd ..
install -m 0644 *.deb /srv/local-apt-repository/
