# Debianization of a Git repository
The following command sequence demonstrates how to Debianize a Git
repository. A Debian package for ruby2.7 is created from the Git
branch *ruby_2_7* of the
[Ruby language repository on GitHub](https://github.com/ruby/ruby).

At the time of this writing, the HEAD of this branch is between releases
2.7.2 and 2.7.3, so following Debian conventions, the version prefix
is 2.7.3-1, to which is appended the commit ID of the branch HEAD (as
`~gID').

To begin, the Debian build system needs a tarball of the upstream
sources. This is created with the command `git archive` as follows:

```shell
PACKAGE=ruby2.7
BRANCH=ruby_2_7
git clone -b "$BRANCH" https://github.com/ruby/ruby.git
cd ./ruby
VERSION=2.7.3-1~g$(git rev-parse --short=7 HEAD)
PREFIX=${PACKAGE}_${VERSION}
git archive --format=tar --prefix=${PREFIX}/ $BRANCH |
    xz - > ../$PREFIX.orig.tar.xz
```

Next, the command `git-buildpackage` operates on orphan branches *upstream* and
*debian*, which are created as follows:

```shell
git checkout --orphan upstream
git rm -r --cached .
git clean -fdx
git config --global user.email 'slewsys@gmail.com'
git config --global user.name 'Andrew L. Moore'
git commit --allow-empty -m 'Initial commit: Debian git-buildpackage.'
git checkout -b debian
```

Then initialize the debian branch from Debian Ruby package for the
current release (i.e., Debian *buster*). We're only interested in the
*debian* subdirectory. A new version is added to the *changelog* file
per upstream, and the file *gbp.conf* is updated to reflect our choice
of branch names. Since the current package is based on Ruby 2.5,
update their names and contents accordingly.  Delete the symbols file.

```shell
curl -L http://deb.debian.org/debian/pool/main/r/ruby2.5/ruby2.5_2.5.5-3+deb10u3.debian.tar.xz |
    tar -Jxf -
ed -s debian/changelog <<EOF
0a
ruby2.7 ($VERSION) experimental; urgency=medium

  * New upstream version 2.7.3

 -- Andrew L. Moore <slewsys@gmail.com>  Sun, 24 Jan 2021 15:28:42 -0500

.
wq
EOF
ed -s debian/gbp.conf <<EOF
/pristine-tar/s/=.*/= False/
a
debian-branch = debian
upstream-branch = upstream
.
wq
EOF
git add .
git commit -m 'Import updated debian directory.'
```

Finally, import the upstream source to *debian* and *upstream* branches
and build the package:

```shell
gbp import-orig ../${PREFIX}.orig.tar.xz
git checkout upstream
git tag upstream/${VERSION%%-*}
git checkout debian
gbp buildpackage -uc -us --git-tag
```
