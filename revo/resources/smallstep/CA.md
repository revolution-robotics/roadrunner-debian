# Smallstep Certificate Authority
The scripts in this directory are for building, installing and
initializing a Smallstep certificate authority, used for issuing
private TLS and SSH certificates.  The scripts can be invoked as follows:

```shell
./build-step-certificates-debian-pkg
./build-step-cli-debian-pkg
sudo apt update
sudo apt install ./step-ca\*deb ./step-cli\*deb
if test ."$(hostname -s)" = ."$(hostname --fqdn)"; then
    ./enable-step-ca -f $(hostname -s).local
else
    ./enable-step-ca -f $(hostname --fqdn)
fi
```
