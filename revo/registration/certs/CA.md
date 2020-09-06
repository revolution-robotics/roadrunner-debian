# RevoEdge Certificate Authority
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

## Initialize Certificate Authority (SmallStep)
```
git
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
