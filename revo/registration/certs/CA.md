# REVO.io Certificate Authority
## Install Smallstep Certificate Authority
On Ubuntu x86\_64, run:

```
curl -L https://raw.githubusercontent.com/revolution-robotics/roadrunner-debian/debian_buster_rr01/revo/registration/certs/install-step-ca.sh | bash -s
```

[install-step-ca.sh](https://github.com/revolution-robotics/roadrunner-debian/blob/debian_buster_rr01/revo/registration/certs/install-step-ca.sh)

## Building `step` and `step-ca` for ARM
To build and package `step-cli` and `step-ca`, the following tools are needed:
- `go`
- `golangci-lint`
- `debuild`
- `debhelper`


To build `step-cli` for ARM,  create a Debian rootfs, e.g., see
 [Debian GNU/Linux build suite for REVO boards](https://github.com/revolution-robotics/roadrunner-debian))
with multipass VM manager, e.g., see
[mp-build-diskimage](https://github.com/revolution-robotics/roadrunner-debian/blob/debian_buster_rr01/contrib/mp-build-diskimage.sh),
then run:

```
chroot rootfs /bin/bash
```

then

```
sudo apt install golang-go
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.31.0
sudo install $(go env GOPATH)/bin/golangci-lint /usr/bin/
sudo apt install debhelper devscripts
mkdir $HOME/smallstep
cd $HOME/smallstep
git clone https://github.com/smallstep/cli.git
cd ./cli
latest_tag=$(git tag -l | sort -V -k1.2 | grep -v -- '-rc\.' | tail -1)
tag_commit=$(git rev-parse $latest_tag | cut -c-7)
head_commit=$(git rev-parse HEAD | cut -c-7)
if test ."$tag_commit" = ."$head_commit"; then
    version=${latest_tag#v}
else
    version=${latest_tag#v}~g${head_commit}
fi
sed -i -e "1s;(0.0.1);($version);" debian/changelog
make build
```

The Debian package step fails, so this must be created manually.
Build the package on amd64 and use that as the basis for the arm
package as follows:

```
cd debian
tar zxf ../step-cli_amd64.tgz
sed -i -e '/amd64/s//armhf/' step-cli/DEBIAN/control
install -m 0755 ../bin/step step-cli/usr/bin/step-cli
dpkg-deb --build step-cli
mv step-cli.deb step-cli-${version}_armhf.deb
```


## Initialize Certificate Authority (EasyRSA)
Clone and deploy Certificate Authority utility, easyrsa, from GitHub:
```
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa
revision=g$(git rev-parse HEAD | cut -c-7)
./build/build-dist.sh --version="$revision" --no-windows
ca_dist=EasyRSA-${revision}
sudo tar -C /etc -zxf dist-staging/${ca_dist}.tgz
cd /etc/${ca_dist}
sudo cp vars.example vars
diff_url=https://raw.githubusercontent.com/revolution-robotics/roadrunner-debian/debian_buster_rr01/revo/registration/certs/easyrsa-vars.diff
curl "$diff_url" | sudo patch
sudo ./easyrsa init-pki
sudo ./easyrsa build-ca nopass
sudo install -d -m 0755 /usr/share/certs
sudo install -m 0644 pki/ca.crt /usr/share/certs/
```
## Initialize Certificate Authority (CloudFlare)
Clone and deploy Certificate Authority utility, CFSSL, from GitHub:
```
snap install go --classic
git clone https://github.com/cloudflare/cfssl.git
cd cfssl
make
sudo install -d -m 755 /usr/local/bin
for cmd in bin/*; do sudo install -m 755 "$cmd" /usr/local/bin; done
```
