#!/usr/bin/env bash
#
# @(#) install-github-ruby.sh
#
# Debianization of a Git repository
#
# The following command sequence demonstrates how to Debianize a Git
# repository. A Debian package for ruby2.7 is created from the Git
# branch *ruby_2_7* of the
# [Ruby language repository on GitHub](https://github.com/ruby/ruby).

# At the time of this writing, the HEAD of this branch is between
# releases 2.7.2 and 2.7.3, so following Debian conventions, the
# version prefix is 2.7.3-1, to which is appended the commit ID of the
# branch HEAD (as `~gID').

# To begin, the Debian build system needs a tarball of the upstream
# sources. This is created with the command `git archive` as follows:

PACKAGE=ruby2.7
BRANCH=ruby_2_7
git clone -b "$BRANCH" https://github.com/ruby/ruby.git
cd ./ruby
VERSION=2.7.3-1~g$(git rev-parse --short=7 HEAD)
PREFIX=${PACKAGE}_${VERSION}
git archive --format=tar --prefix=${PREFIX}/ $BRANCH |
    xz - > ../$PREFIX.orig.tar.xz


# Next, the command `git-buildpackage` operates on orphan branches
# *upstream* and *debian*, which are created as follows:

git checkout --orphan upstream
git rm -r --cached .
git clean -fdx
git config --global user.email 'slewsys@gmail.com'
git config --global user.name 'Andrew L. Moore'
git commit --allow-empty -m 'Initial commit: Debian git-buildpackage.'
git checkout -b debian

# Then initialize the debian branch from Debian Ruby package for the
# current release (i.e., Debian *buster*). We're only interested in
# the *debian* subdirectory. A new version is added to the *changelog*
# file per upstream, and the file *gbp.conf* is updated to reflect our
# choice of branch names. Since the current package is based on Ruby 2.5,
# update their names and contents accordingly. Delete the symbols file.

# Extract and apply patch at the end of this script to create
# Debian subdirectory.
sed -n '/BEGIN debian patch/,$s/^# //p' $0 |
    patch -p0
chmod +x $(find debian -type f | xargs -n30 egrep -l '^#!')
git add .
git commit -m 'Import updated debian directory.'


# Finally, import the upstream source to *debian* and *upstream* branches
# and build the package:

gbp import-orig ../${PREFIX}.orig.tar.xz
git checkout upstream
git tag upstream/${VERSION%%-*}
git checkout debian
gbp buildpackage -uc -us --git-tag

## **** BEGIN debian patch ****
# diff -Nru debian~/changelog debian/changelog
# --- debian~/changelog	1969-12-31 19:00:00.000000000 -0500
# +++ debian/changelog	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,951 @@
# +ruby2.7 (2.7.3-1~gd069339) experimental; urgency=medium
# +
# +  * New upstream version 2.7.3
# +
# + -- Andrew L. Moore <slewsys@gmail.com>  Sun, 24 Jan 2021 15:28:42 -0500
# +
# +ruby2.7 (2.7.2-3) unstable; urgency=medium
# +
# +  * d/p/0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch:
# +    Backport an upstream patch. It includes enabling unaligned memory access,
# +    gc and vm_exec.c optimizations (LP: #1901074).
# +  * Refresh and sort patches numerically.
# +  * B-d on debhelper-compat instead of debhelper.
# +  * Drop debian/ruby2.7.lintian-overrides. The only override there is
# +    hyphen-used-as-minus-sign and it seems to not be a thing anymore.
# +    Moreover, it is malformed according to lintian.
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Fri, 30 Oct 2020 16:04:41 -0300
# +
# +ruby2.7 (2.7.2-2) unstable; urgency=medium
# +
# +  * Add patch to fix ENOENT error when cwd does not exists. (Closes: #969130)
# +    - Thanks, Antoni Villalonga, for the patch.
# +  * Place arch-qualified tools in rbconfig.rb. (Closes: #970469)
# +    - Thanks, Helmut Grohne, for the debdiff.
# +  * Disable test_find_proxy_no_proxy test. (Closes: #968203)
# +    - Tries to parse http://example.org and thus causes FTBFS on buster.
# +
# + -- Utkarsh Gupta <utkarsh@debian.org>  Tue, 13 Oct 2020 18:48:32 +0530
# +
# +ruby2.7 (2.7.2-1) unstable; urgency=medium
# +
# +  [ Utkarsh Gupta ]
# +  * New upstream version 2.7.2.
# +    - Ready for glibc 2.32.
# +  * Refresh d/patches.
# +  * Add patch to fix TestIRB::TestHistory tests.
# +  * Add patch to fix "real" autopkgtests failure wrt rubygems.
# +  * Update symbols file to add rb_ast_add_local_table@Base.
# +
# +  [ Cédric Boutillier ]
# +  * use C.UTF-8 locale
# +
# + -- Utkarsh Gupta <utkarsh@debian.org>  Tue, 13 Oct 2020 00:55:43 +0530
# +
# +ruby2.7 (2.7.1-4) unstable; urgency=medium
# +
# +  [ Pirate Praveen ]
# +  * Bump minimum version of rubygems-integration to 1.17.1~
# +
# +  [ Cédric Boutillier ]
# +  * [ci skip] Add .gitattributes to keep unwanted files out of the source package
# +
# +  [ Utkarsh Gupta ]
# +  * Add myself as an uploader
# +  * Add patch to fix a potential HTTP request smuggling
# +    vulnerability in WEBrick. (Fixes: CVE-2020-25613)
# +
# + -- Utkarsh Gupta <utkarsh@debian.org>  Thu, 01 Oct 2020 20:10:11 +0530
# +
# +ruby2.7 (2.7.1-3) unstable; urgency=medium
# +
# +  * Do not run TestJIT.rb test file on salsa and autopkgtest
# +  * Exclude all racc command related tests when running autopkgtest
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Mon, 11 May 2020 10:58:00 -0300
# +
# +ruby2.7 (2.7.1-2) unstable; urgency=medium
# +
# +  * Skip flaky DRbTest in i386
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Fri, 08 May 2020 18:02:58 -0300
# +
# +ruby2.7 (2.7.1-1) unstable; urgency=medium
# +
# +  * New upstream version 2.7.1
# +  * d/control: rules does not require root
# +  * d/copyright: update Debian packaging copyright
# +  * Mark ruby2.7-doc binary package as Multi-Arch: foreign (Closes: #956798)
# +  * B-d on libncurses-dev instead of libncurses{,w}5-dev (Closes: #956799)
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Thu, 07 May 2020 18:12:14 -0300
# +
# +ruby2.7 (2.7.0-7) unstable; urgency=medium
# +
# +  [ Lucas Kanashiro ]
# +  * d/rules: remove extra space from riscv configure line
# +
# +  [ Antonio Terceiro ]
# +  * libruby: calculate provides dynamically
# +  * libruby: do not provide ruby-bundler (Closes: #959393)
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Mon, 04 May 2020 15:38:31 -0300
# +
# +ruby2.7 (2.7.0-6) unstable; urgency=medium
# +
# +  * Add patch to fix FTBFS on x32: misdetected as i386 or amd64
# +    (Closes: #954293)
# +  * d/rules: add -fno-crossjumping to CFLAGS (Closes: #951714)
# +  * Make 64-bit-only symbols optional to fix FTBFS on i386/armhf
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Mon, 20 Apr 2020 10:39:35 -0300
# +
# +ruby2.7 (2.7.0-5) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * Add test excludes for salsa
# +
# +  [ Lucas Kanashiro ]
# +  * d/rules: build with -latomic on riscv64
# +  * Disable some tests that fail or time out on riscv64
# +  * d/control: list all libruby2.7 bundle gems in Provides field
# +  * d/libruby2.7.lintian-overrides:
# +    - ignore library-not-linked-against-libc errors, the *.so extension files
# +      are linked against libruby2.7 only
# +    - ignore wrong-path-to-the-ruby-interpreter errors, the scripts reported
# +      are not supposed to be used by users
# +  * d/libruby2.7.symbols: add missing symbols
# +  * d/control: use secure url in Homepage field
# +  * Declare compliance with Debian Policy 4.5.0
# +  * d/copyright: use secure urls in Format and Source fields
# +  * Bump debhelper compatibility level to 12
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Mon, 13 Apr 2020 11:54:17 -0300
# +
# +ruby2.7 (2.7.0-4) unstable; urgency=medium
# +
# +  * mipsel: exclude test that fails on buildd
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Wed, 19 Feb 2020 08:05:27 -0300
# +
# +ruby2.7 (2.7.0-3) unstable; urgency=medium
# +
# +  * Fix priority order of paths in -I option
# +
# + -- Cédric Boutillier <boutil@debian.org>  Tue, 04 Feb 2020 18:58:15 +0100
# +
# +ruby2.7 (2.7.0-2) unstable; urgency=medium
# +
# +  * Fix symbols file using dpkg-gensymbols (Closes: #948371)
# +  * debian/rules: fix dh_auto_clean override (Closes: #948187)
# +  * debian/tests/run-all: copy tool/ to $AUTOPKGTEST_TMP
# +  * Exclude some failing tests when executed via autopkgtest
# +  * Set OPENSSL_CONF to lower security level to 1
# +  * Skip some tests that need root permission to pass
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Wed, 22 Jan 2020 11:47:11 -0300
# +
# +ruby2.7 (2.7.0-1) unstable; urgency=medium
# +
# +  * No changes rebuild
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Tue, 07 Jan 2020 16:20:19 -0300
# +
# +ruby2.7 (2.7.0-1~exp1) experimental; urgency=medium
# +
# +  * New upstream version 2.7.0
# +  * Update d/libruby2.7.symbols
# +  * d/copyright: remove some files dropped in this new release
# +  * d/t/run-all: use AUTOPKGTEST_TMP instead of ADTTMP
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Thu, 02 Jan 2020 16:41:27 -0300
# +
# +ruby2.7 (2.7.0~preview2-1~exp1) experimental; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * New upstream version 2.5.7
# +  * autopkgtest: simplify test runner even more
# +
# +  [ Lucas Kanashiro ]
# +  * d/watch: track release 2.7.x
# +  * New upstream version 2.7.0~preview2
# +  * Ruby 2.7
# +  * Update patches
# +  * Exclude tests which fail due to ~ in version string
# +  * debian/rules: define $HOME since some tests rely on it
# +
# +  [ Antonio Terceiro ]
# +  * skip test-spec during build
# +  * Update symbols file with new symbols in ruby 2.7
# +
# +  [ Lucas Kanashiro ]
# +  * Add myself to Uploaders list
# +
# + -- Lucas Kanashiro <kanashiro@debian.org>  Wed, 13 Nov 2019 20:40:21 -0300
# +
# +ruby2.5 (2.5.7-1) unstable; urgency=medium
# +
# +  [ Utkarsh Gupta ]
# +  * Add salsa-ci.yml
# +
# +  [ Antonio Terceiro ]
# +  * New upstream version 2.5.7
# +  * Refresh patches
# +  * autopkgtest: rework "expected failures" mechanism. We now just skip the
# +    tests cases that are known to fail, and not load at all the test files
# +    that fail to load. This will make the output in case of failures a lot
# +    more clear.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Wed, 23 Oct 2019 12:48:04 -0300
# +
# +ruby2.5 (2.5.5-4) unstable; urgency=medium
# +
# +  [ HIGUCHI Daisuke (VDR dai) ]
# +  * debian/rules: do not compress debug sections for arch-dep Ruby packages with dh_compat 12
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 30 Jul 2019 09:41:10 -0300
# +
# +ruby2.5 (2.5.5-3) unstable; urgency=medium
# +
# +  * ia64: Don't clear register_stack_start (Closes: #928068)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 02 Jun 2019 10:16:57 -0300
# +
# +ruby2.5 (2.5.5-2) unstable; urgency=medium
# +
# +  * debian/tests/excludes/: fix exclusion of Rinda tests that depend on
# +    network availability, by moving the existing excludes files to the correct
# +    location. (Closes: #927122)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Mon, 13 May 2019 10:55:06 -0300
# +
# +ruby2.5 (2.5.5-1) unstable; urgency=medium
# +
# +  * New upstream version 2.5.5. Includes a series of bug fixes, most notably
# +    for 6 security bugs discovered in Rubygems:
# +    - CVE-2019-8320: Delete directory using symlink when decompressing tar
# +    - CVE-2019-8321: Escape sequence injection vulnerability in verbose
# +    - CVE-2019-8322: Escape sequence injection vulnerability in gem owner
# +    - CVE-2019-8323: Escape sequence injection vulnerability in API response
# +      handling
# +    - CVE-2019-8324: Installing a malicious gem may lead to arbitrary code
# +      execution
# +    - CVE-2019-8325: Escape sequence injection vulnerability in errors
# +  * Rebase patches. The following patches were applied upstream and dropped
# +    from the Debian package:
# +    - 0011-Update-for-tzdata-2018f.patch
# +    - 0012-test-update-test-certificate.patch
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 26 Mar 2019 17:12:34 -0300
# +
# +ruby2.5 (2.5.3-4) unstable; urgency=medium
# +
# +  * 0012-test-update-test-certificate.patch: update test certificate so
# +    SSL-related tests pass (Closes: 919516)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 23 Feb 2019 17:51:21 -0300
# +
# +ruby2.5 (2.5.3-3) unstable; urgency=medium
# +
# +  * arm64: also skip TestBugReporter#test_bug_reporter_add, which also fails~
# +    4% of the time.
# +  * mipsel: fix location of skiplist for OpenSSL::TestSSL, from TestSSL.rb to
# +    OpenSSL/TestSSL.rb.
# +  * Remove skiplist for OpenSSL::TestSSL on all architectures. It was in the
# +    wrong place to begin with.
# +  * Fix location of skiplist for Rinda-related tests.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 27 Nov 2018 09:58:02 -0200
# +
# +ruby2.5 (2.5.3-2) unstable; urgency=medium
# +
# +  * arm64: skip TestRubyOptions#test_segv_loaded_features, fails ~3% of the
# +    time
# +  * mipsel: skip OpenSSL::TestSSL tests that frequently timeout on the Debian
# +    buildds
# +    - test_dh_callback
# +    - test_get_ephemeral_key
# +    - test_post_connect_check_with_anon_ciphers
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 25 Nov 2018 13:05:27 -0200
# +
# +ruby2.5 (2.5.3-1) unstable; urgency=medium
# +
# +  * New upstream version 2.5.3
# +    - Includes fix for CVE-2018-16396, "Tainted flags are not propagated in
# +      Array#pack and String#unpack with some directives" (Closes: #911920)
# +  * Refresh patches:
# +    - Dropped 0009-merge-changes-in-ruby-openssl-v2.1.1.patch, already applied
# +      upstream.
# +  * Add tzdata to Build-Depends (Closes: #911717)
# +  * Cherry-pick upstream commmit with update to tests due to changes in tzdata
# +    2018f (Closes: #913181)
# +  * Update gemspec reproducibility patch to also make new default gems fiddle
# +    and ipaddr reproducible. (Closes: #898051)
# +  * debian/rules: don't install created.rid file produced by rdoc to make
# +    build reproducible. This file is used by rdoc to decide when to update
# +    documentation when in use in interactive settings, and containing a
# +    timestamp is one of its functions. Is is not necessary for a binary
# +    package, though, because the included documentation will never need to be
# +    updated in-place.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 24 Nov 2018 12:38:59 -0200
# +
# +ruby2.5 (2.5.1-6) unstable; urgency=medium
# +
# +  * Fix build with openssl 1.1.1 (Closes: #907790)
# +    - Apply Ruby upstream patch to update openssl extension to v2.1.1. This
# +      includes some, but not all, changes needed to make the tests pass
# +      against openssl 1.1.1
# +    - Apply ruby-openssl upstream patches to fix tests against openssl 1.1.1
# +    - Exclude tests that still fail with openssl 1.1.1
# +    - debian/rules: set OPENSSL_CONF to /dev/null when running tests to use
# +      the default openssl settings. Unfortunately there are too many tests for
# +      several parts of the Ruby standard library that use openssl and that take
# +      very long to complete under the Debian settings, and I don't have the
# +      cycles to go fix each one.
# +    - debian/tests/run-all: also run autopkgtest against the default openssl
# +      settings and not the Debian-specific ones.
# +  * debian/tests/run-all: fix reference to excludes dir
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 06 Oct 2018 14:15:02 -0300
# +
# +ruby2.5 (2.5.1-5) unstable; urgency=medium
# +
# +  * Fix spelling error in patch description
# +  * Remove always-on dh --parallel
# +  * Pass --host to configure when cross-building.
# +    We cannot just use dh_auto_configure because some of the added options
# +    then make configure need a baseruby, which we want to avoid when
# +    building for the native arch. (Closes: #893501)
# +
# + -- Chris Hofstaedtler <zeha@debian.org>  Tue, 24 Jul 2018 08:56:14 +0000
# +
# +ruby2.5 (2.5.1-4) unstable; urgency=medium
# +
# +  * Disable tests failing on Ubuntu builders (Closes: #886515)
# +  * Bump Standards-Version to 4.1.5
# +
# + -- Chris Hofstaedtler <zeha@debian.org>  Sun, 22 Jul 2018 14:18:07 +0000
# +
# +ruby2.5 (2.5.1-3) unstable; urgency=medium
# +
# +  * Exclude test that often fails on the Debian mips buildds
# +  * Add missing patch needed for kfreebsd-amd64 port (Closes: #899267)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 10 Jun 2018 22:08:34 -0300
# +
# +ruby2.5 (2.5.1-2) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * debian/tests/control: ignore output on stderr
# +  * debian/tests/bundled-gems: only fail on missing gems. Only warn if version
# +    found is not new enough
# +  * libruby2.5: add dependency on ruby-xmlrpc
# +
# +  [ Samuel Thibault ]
# +  * Fix FTBFS on hurd (Closes: #896509)
# +
# +  [ Svante Signell ]
# +  * Exclude tests that fail on kfreebsd (Closes: #899267)
# +
# +  [ Antonio Terceiro ]
# +  * Update symbols file for 64-bit architectures
# +
# +  [ Santiago R.R ]
# +  * Exclude Rinda TestRingFinger and TestRingServer test units requiring network access
# +    (Closes: #898917)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 09 Jun 2018 11:50:20 -0300
# +
# +ruby2.5 (2.5.1-1) unstable; urgency=medium
# +
# +  * New upstream version 2.5.1.
# +
# +    According to the release announcement, includes fixes for the following
# +    security issues:
# +
# +    - CVE-2017-17742: HTTP response splitting in WEBrick
# +    - CVE-2018-6914: Unintentional file and directory creation with directory
# +      traversal in tempfile and tmpdir
# +    - CVE-2018-8777: DoS by large request in WEBrick
# +    - CVE-2018-8778: Buffer under-read in String#unpack
# +    - CVE-2018-8779: Unintentional socket creation by poisoned NUL byte in
# +      UNIXServer and UNIXSocket
# +    - CVE-2018-8780: Unintentional directory traversal by poisoned NUL byte in
# +      Dir
# +    - Multiple vulnerabilities in RubyGems
# +  * Refresh patches.
# +
# +    Patches dropped for being already applied upstream:
# +
# +    - 0005-Fix-tests-to-cope-with-updates-in-tzdata.patch
# +    - 0006-Rubygems-apply-upstream-patch-to-fix-multiple-vulner.patch
# +  * Add patch to fix FTBFS on ia64 (Closes: #889848)
# +  * Add simple autopkgtest to check for builtin extensions that are build
# +    against external dependencies (ssl, yaml, *dbm etc)
# +  * Add build-dependency on libgdbm-compat-dev (Closes: #892099)
# +  * debian/tests/excludes/any/TestTimeTZ.rb: ignore tests failing due to
# +    assumptions that don't hold on newer tzdata update. Upstream bug:
# +    https://bugs.ruby-lang.org/issues/14655
# +  * debian/libruby2.5.symbols: update with new symbol added in this release
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 31 Mar 2018 13:22:48 -0300
# +
# +ruby2.5 (2.5.0-6) unstable; urgency=medium
# +
# +  * debian/rules: explicitly pass --runstatedir, --localstatedir, and
# +    --sysconfdir to ./configure
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 04 Mar 2018 13:30:49 -0300
# +
# +ruby2.5 (2.5.0-5) unstable; urgency=medium
# +
# +  * Change Maintainer: to Debian Ruby Team
# +  * debian/patches/0005-Fix-tests-to-cope-with-updates-in-tzdata.patch: fix
# +    test failures after updates in the Japan timezone data (Closes: #889046)
# +  * debian/patches/0006-Rubygems-apply-upstream-patch-to-fix-multiple-vulner.patch:
# +    upgrade to Rubygems 2.7.6 to fix multiple vulnerabilities
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 24 Feb 2018 12:20:04 -0300
# +
# +ruby2.5 (2.5.0-4) unstable; urgency=medium
# +
# +  * debian/rules: pass --excludes-dir options to `make check` via $TESTS
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 30 Dec 2017 10:50:04 -0300
# +
# +ruby2.5 (2.5.0-3) unstable; urgency=medium
# +
# +  * arm64: skip TestRubyOptimization#test_clear_unreachable_keyword_args. It
# +    works just fine on a porter box, but consistently hangs on the arm64
# +    buildd.
# +  * mipsel: skip some tests from TestNum2int; they fail on the buildd, but not
# +    on the porterbox.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Fri, 29 Dec 2017 21:14:34 -0300
# +
# +ruby2.5 (2.5.0-2) unstable; urgency=medium
# +
# +  * Move test exclusions from a patch to debian/tests/excludes/
# +    - debian/rules, debian/tests/run-all: pass the appropriate exclusion flags
# +      to the test runner
# +  * Exclude TestResolvMDNS. It will fail on some architectures, and be very
# +    slow on others.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Fri, 29 Dec 2017 12:57:39 -0300
# +
# +ruby2.5 (2.5.0-1) unstable; urgency=medium
# +
# +  * New upstream version 2.5.0
# +  * Refresh patches
# +  * debian/libruby2.5.symbols: update
# +  * debian/tests/known-failures.txt: add another 3 test files that assume the
# +    tests are being run against a built source tree
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 26 Dec 2017 11:48:55 -0200
# +
# +ruby2.5 (2.5.0~rc1-1) unstable; urgency=medium
# +
# +  * New upstream release candidate. Includes the following fixes:
# +    - Fix stack size on powerpc64 (Closes: #881772)
# +    - CVE-2017-17405: Command injection vulnerability in Net::FTP
# +      (Closes: #884437)
# +  * Refresh patches
# +  * debian/control:
# +    - Remove explicit Testsuite: header
# +    - ruby2.5-dev: Recommends: ruby2.5-doc
# +    - Declare compatibility with Debian Policy 4.1.2; no changes needed
# +    - Bump debhelper compatibility level to 10
# +      - change debian/rules to call ./configure directly, to use upstream's
# +        built-in multiarch support as before debhelper compatibility level 9
# +  * debian/watch: download release tarballs.
# +    Using release tarballs makes it possible to build ruby without having an
# +    existing ruby. This should help bootstrapping ruby on new
# +    architectures. (Closes: #832022)
# +  * debian/copyright: exclude embedded copies of bundled gems and libffi
# +  * debian/rules:
# +    - run tests in verbose mode during build
# +    - drop explicit usage of autotools-dev
# +    - drop usage of autoreconf debhelper sequence, it's not needed anymore
# +      since we are now using a complete upstream release tarball
# +    - drop passing --baseruby to configure, since do not require an existing
# +      ruby anymore
# +    - skip setting DEB_HOST_MULTIARCH if already set
# +    - replace manual call to dpkg-parsechangelog with including
# +      /usr/share/dpkg/pkg-info.mk and using variables from there.
# +  * autopkgtest: make use of the text exclusion rules under test/excludes/
# +  * debian/libruby2.5.symbols: update with symbols added/removed since the
# +    preview1 release
# +  * debian/tests/bundled-gems: handle extra field in gems/bundled_gems
# +  * debian/libruby2.5.lintian-overrides: remove unused override
# +    (possible-gpl-code-linked-with-openssl)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 24 Dec 2017 12:29:25 -0200
# +
# +ruby2.5 (2.5.0~preview1-1) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * New upstream version 2.5.0~preview1
# +  * debian/patches: import all of our remaining changes wrt upstream. All the
# +    changes to tests were transformed into exclude files under test/excludes/
# +  * ruby2.5-dev: don't install *.a files anymore; they are not installed by
# +    the upstream build system anymore.
# +  * debian/rules: adapt removal of embedded certificate store in Rubygems
# +  * debian/rules: also remove embedded certificate store from bundler
# +
# +  [ Christian Hofstaedtler ]
# +  * Remove packaging for tcltk extension; it has been removed from Ruby core
# +    upstream.
# +  * Drop migration from old -dbg package
# +  * Disable test for homedir expansion which fails in sbuild
# +  * Upstream tarballs no longer come from git
# +  * Update jquery in missing-sources
# +  * d/copyright: Add info for darkfish icon set
# +  * Build with default OpenSSL once again
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 10 Oct 2017 21:12:54 -0300
# +
# +ruby2.3 (2.3.3-1) unstable; urgency=medium
# +
# +  * New upstream version.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Tue, 22 Nov 2016 12:32:41 +0000
# +
# +ruby2.3 (2.3.2-1) unstable; urgency=medium
# +
# +  * New upstream version.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 16 Nov 2016 01:31:08 +0000
# +
# +ruby2.3 (2.3.1-6) unstable; urgency=medium
# +
# +  * debian/rules: honor 'nocheck' flag in DEB_BUILD_OPTIONS (Closes: #842768).
# +    Thanks to John Paul Adrian Glaubitz for the patch.
# +  * Build-Depends on libssl1.0-dev. Ruby 2.3 is not likely to get OpenSSL 1.1
# +    compatibility (see #828535)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Wed, 09 Nov 2016 14:38:59 -0200
# +
# +ruby2.3 (2.3.1-5) unstable; urgency=medium
# +
# +  * Increase timeout for test_array.rb test_permutation_stack_error,
# +    as Array#permutation is very slow on armel, mips, mipsel.
# +    Forwarded to upstream as issue #12502.
# +  * Disable test_process.rb test_aspawn_too_long_path, as it uses ~2GB
# +    of RAM and a lot of CPU time before finally failing on mips, mipsel.
# +    Forwarded to upstream as issue #12500.
# +  * Increase timeout for test_gc.rb test_gc_parameter, for mips, mipsel.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Fri, 17 Jun 2016 23:30:49 +0000
# +
# +ruby2.3 (2.3.1-4) unstable; urgency=medium
# +
# +  * Backport some test changes from Ruby trunk, to fix (some) build
# +    failures on archs other than amd64, i386, ppc64el, s390x.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 15 Jun 2016 07:32:02 +0000
# +
# +ruby2.3 (2.3.1-3) unstable; urgency=medium
# +
# +  * Replace libruby2.3-dbg with automatic dbgsym packages.
# +  * Avoid unreproducible rbconfig.rb (always use bash to build).
# +  * rdoc: sort input filenames in a consistent way (for reproducible).
# +  * Run full testsuite during build (make check instead of make test).
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Tue, 14 Jun 2016 20:47:45 +0000
# +
# +ruby2.3 (2.3.1-2) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * debian/tests/known-failures.txt: remove test that now passes
# +    (test/rinda/test_rinda.rb)
# +  * debian/rules: enable bindnow hardening option (Closes: #822288)
# +  * debian/copyright: update and simplify copyright annotations for Unicode
# +    files under enc/trans/JIS/
# +  * Bump Standards-Version to 3.9.8 (no changes needed)
# +
# +  [ Christian Hofstaedtler ]
# +  * Stop providing ruby-interpreter. Only packages providing
# +    /usr/bin/ruby can be a credible provider of ruby-interpreter.
# +    (Closes: #822072)
# +  * Raise priority to "optional", now that ruby2.2 is gone, although
# +    the value of this change is unclear. (Closes: #822911)
# +  * Apply patch from Reiner Herrmann <reiner@reiner-h.de> to help with
# +    reproducibility of mkmf.rb using packages. (Closes: #825569)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Mon, 30 May 2016 12:14:46 +0000
# +
# +ruby2.3 (2.3.1-1) unstable; urgency=medium
# +
# +  * Call make install-doc, install-nodoc with V=1, for diagnosing
# +    build failures.
# +  * New upstream TEENY version.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 27 Apr 2016 07:40:42 +0000
# +
# +ruby2.3 (2.3.0-5) unstable; urgency=medium
# +
# +  * Set gzip embedded mtime field to fixed value for rdoc-generated
# +    compressed javascript data. Helps with reproducibility of rdoc-using
# +    packages.
# +  * Build tcltk extension for Tcl/Tk 8.6.
# +  * Apply patch from upstream to fix crash in Proc binding.
# +    (ruby-core: 74100, trunk r54128, bug #12137). (Closes: #816161)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 16 Mar 2016 23:36:12 +0000
# +
# +ruby2.3 (2.3.0-4) unstable; urgency=medium
# +
# +  * Apply patch from upstream to fix deserializing OpenStruct via Psych,
# +    (ruby-core: 72501, trunk r53366). (Closes: #816358)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Tue, 01 Mar 2016 22:41:19 +0100
# +
# +ruby2.3 (2.3.0-3) unstable; urgency=medium
# +
# +  * Explicitly set bundled gem dates. Otherwise these multi-arch same files
# +    differ on different architectures depending on build date.
# +    (Closes: #810321)
# +  * Apply patch from upstream (ruby-core:72736, trunk r53455) to fix extension
# +    builds that use g++.
# +  * Bump Standards-Version to 3.9.7 with no addtl. changes
# +  * d/copyright: Remove rake, no longer bundled.
# +  * Switch Vcs-* URLs to https.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Mon, 29 Feb 2016 21:45:51 +0100
# +
# +ruby2.3 (2.3.0-2) unstable; urgency=medium
# +
# +  * debian/libruby2.3.symbols: update with new symbols introduced right before
# +    the final 2.3.0 release.
# +  * libruby2.3: add dependencies on rake, ruby-did-you-mean and
# +    ruby-net-telnet
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 30 Jan 2016 09:20:31 -0200
# +
# +ruby2.3 (2.3.0-1) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * Ruby 2.3
# +  * debian/tests/bundled-gems: check if all libraries that are supposed to be
# +    bundled are present, with a version greater than or equal to the one
# +    specified in gems/bundled_gems
# +  * debian/tests/run-all: filter failures against list of known failures. Pass
# +    if only the tests listed in debian/tests/known-failures.txt fail, fail
# +    otherwise. This will help catch regressions.
# +  * debian/copyright: update wrt new files in the distribution
# +
# +  [ Christian Hofstaedtler ]
# +  * autopkgtest: depend on all packages so we actually have header files
# +    installed.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Mon, 28 Dec 2015 09:17:47 -0300
# +
# +ruby2.2 (2.2.3-2) unstable; urgency=medium
# +
# +  * Add dependency on ruby-minitest to provide the same experience out of the
# +    box as the upstream package (Closes: #803665)
# +  * Apply upstream patch to not use SSLv3 methods if OpenSSL does not export
# +    them (Closes: #804089)
# +  * updated debian/libruby2.2.symbols with 1 new symbol.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Thu, 05 Nov 2015 18:43:02 -0200
# +
# +ruby2.2 (2.2.3-1) unstable; urgency=medium
# +
# +  * New upstream release
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Tue, 18 Aug 2015 22:22:21 +0000
# +
# +ruby2.2 (2.2.2-3) unstable; urgency=medium
# +
# +  [ Christian Hofstaedtler ]
# +  * Have libruby2.2 depend on ruby-test-unit, as upstream bundles this
# +    externally maintained package in their tarballs. (Closes: #791925)
# +
# +  [ Antonio Terceiro ]
# +  * Apply upstream patches to fix Request hijacking vulnerability in Rubygems
# +    [CVE-2015-3900] (Closes: #790111)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Wed, 29 Jul 2015 09:50:08 -0300
# +
# +ruby2.2 (2.2.2-2) unstable; urgency=medium
# +
# +  * Make Date in gemspec reproducible. Initial patch from Chris Lamb
# +    <lamby@debian.org>. (Closes: #779631, #784225)
# +  * Replace embedded copies of Lato with symlinks to fonts-lato.
# +    (Closes: #762348)
# +  * debian/copyright: improve DEP-5 compliance.
# +  * Provide debug symbols, in a new libruby2.2-dbg package. Patch from
# +    Matt Palmer <mpalmer@debian.org>. (Closes: #785685)
# +  * Build libruby.so with dpkg-buildflags supplied LDFLAGS.
# +    (Closes: #762350)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 01 Jul 2015 15:36:24 +0200
# +
# +ruby2.2 (2.2.2-1) unstable; urgency=medium
# +
# +  * New upstream release
# +    - includes fix for vulnerability with overly permissive matching of
# +      hostnames in OpenSSL extension [CVE-2015-1855]
# +  * debian/rules: add import-orig-source to automate importing orig tarballs
# +    generated from the upstream git mirror.
# +  * debian/tests: add a functional test that will run all tests under test/
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 03 May 2015 18:56:32 -0300
# +
# +ruby2.2 (2.2.1-1) unstable; urgency=medium
# +
# +  * New upstream release
# +  * debian/copyright: review
# +    - enc/* relicensed to the same license as Ruby
# +    - add license for ccan/* (CC0)
# +    - add license for enc/trans/JIS/*
# +      - some under the "Unicode" license
# +      - most under permissive "You can use, modify, distribute this table
# +        freely." terms
# +    - ext/nkf/ relicensed to zlib/libpng license
# +  * debian/upstream-changes: simpler and more accurate implementation
# +  * debian/libruby2.2.symbols: updated
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Fri, 03 Apr 2015 21:30:14 -0300
# +
# +ruby2.2 (2.2.0~1-1) UNRELEASED; urgency=medium
# +
# +  * Ruby 2.2 RC1
# +  * Dropped all Debian-specific changes to the upstream sources; everything we
# +    need is fixed upstream
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Fri, 19 Dec 2014 14:46:35 -0200
# +
# +ruby2.1 (2.1.5-1) unstable; urgency=medium
# +
# +  * New upstream release
# +    - Fixes CVE-2014-8090 Another Denial of Service XML Expansion
# +      (Closes: #770932)
# +    - Fixes build on SPARC (Closes: #769731)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sat, 29 Nov 2014 12:30:39 -0200
# +
# +ruby2.1 (2.1.4-1) unstable; urgency=high
# +
# +  * New upstream version
# +    - CVE-2014-8080: Denial of Service in XML Expansion
# +    - Changes default settings in OpenSSL bindings to not use deprecated and
# +      insecure ciphers; avoids issues associated to CVE-2014-3566 (i.e. the
# +      "POODLE" bug in OpenSSL)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Wed, 29 Oct 2014 12:07:22 -0200
# +
# +ruby2.1 (2.1.3-2) unstable; urgency=medium
# +
# +  [ Sebastian Boehm ]
# +  * Install SystemTap tap file (Closes: #765862)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Sun, 19 Oct 2014 20:07:50 +0200
# +
# +ruby2.1 (2.1.3-1) unstable; urgency=medium
# +
# +  * New upstream version
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Sat, 20 Sep 2014 16:55:47 +0200
# +
# +ruby2.1 (2.1.2-4) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * Move libjs-jquery dependency from libruby2.1 to ruby2.1, and turn it into
# +    Recommends:. This way programs that link against libruby2.1 won't pull in
# +    libjs-jquery; OTOH those using rdoc (and thus needing libjs-jquery) would
# +    be already using ruby2.1 anyway.
# +
# +  [ Christian Hofstaedtler ]
# +  * Update Vcs-Git URL, as we've moved from master2.1 to master.
# +  * Prepare libruby21.symbols for x32 (Closes: #759615)
# +  * Remove embedded copies of SSL certificates. Rubygems is advised by
# +    rubygems-integration to use the ca-certificates provided certificates.
# +    (Closes: #689074)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Fri, 05 Sep 2014 03:06:30 +0200
# +
# +ruby2.1 (2.1.2-3) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * debian/rules: call debian/split-tk-out.rb with $(baseruby) instead of
# +    `ruby` to actually support bootstrapping with ruby1.8 (and no `ruby`)
# +  * Break dependency loop (Closes: #747858)
# +    - ruby2.1: drop dependency on ruby
# +    - libruby2.1: drop dependency on ruby2.1
# +
# +  [ Christian Hofstaedtler ]
# +  * Add missing man pages for gem, rdoc, testrb (Closes: #756053, #756815)
# +  * Correct ruby2.1's Multi-Arch flag to 'allowed' (Closes: #745360)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Thu, 14 Aug 2014 10:45:29 -0300
# +
# +ruby2.1 (2.1.2-2) unstable; urgency=medium
# +
# +  * Support bootstrapping with Ruby 1.8 (which builds with gcc only) if another
# +    Ruby is not available.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Thu, 15 May 2014 23:20:49 -0300
# +
# +ruby2.1 (2.1.2-1) unstable; urgency=medium
# +
# +  [ Christian Hofstaedtler ]
# +  * New upstream version
# +  * Update watch file
# +
# +  [ Sebastian Boehm ]
# +  * Build with basic systemtap support. (Closes: #747232)
# +
# +  [ Antonio Terceiro ]
# +  * 2.1 is now the main development branch
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Sat, 10 May 2014 15:51:13 +0200
# +
# +ruby2.1 (2.1.1-4) unstable; urgency=medium
# +
# +  * Use Debian copy of config.{guess,sub}
# +    Instead of downloading it from the Internet, which could be down or
# +    insecure. Thanks to Scott Kitterman for the report AND patch.
# +    (Closes: 745699)
# +  * Move jquery source file to d/missing-sources
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Fri, 25 Apr 2014 00:57:13 +0200
# +
# +ruby2.1 (2.1.1-3) unstable; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * Disable rubygems-integration during the build. This fixes the install
# +    location of the gemspecs for the bundled libraries. (Closes: #745465)
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Tue, 22 Apr 2014 18:38:01 +0200
# +
# +ruby2.1 (2.1.1-2) unstable; urgency=medium
# +
# +  * Tie Tcl/Tk dependency to version 8.5, applying patch from Ubuntu.
# +    Thanks to Matthias Klose <doko@debian.org>
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Mon, 10 Mar 2014 13:38:41 +0100
# +
# +ruby2.1 (2.1.1-1) unstable; urgency=medium
# +
# +  * Imported Upstream version 2.1.1
# +  * Update lintian overrides
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Wed, 05 Mar 2014 18:22:58 +0100
# +
# +ruby2.1 (2.1.0-2) unstable; urgency=medium
# +
# +  * ruby2.1-dev: Depend on libgmp-dev.
# +    Thanks to John Leach <john@johnleach.co.uk>
# +  * Fix FTBFS with libreadline 6.x, by applying upstream r45225.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Mon, 03 Mar 2014 21:10:32 +0100
# +
# +ruby2.1 (2.1.0-1) unstable; urgency=medium
# +
# +  * Upload to unstable.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Sat, 22 Feb 2014 23:44:44 +0100
# +
# +ruby2.1 (2.1.0-1~exp2) experimental; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * ruby2.1-dev: add missing dependency on libruby2.1
# +
# +  [ Christian Hofstaedtler ]
# +  * Again depend on ruby without alternatives management
# +  * Tag 64bit-only symbols as such
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Thu, 13 Feb 2014 13:02:25 +0100
# +
# +ruby2.1 (2.1.0-1~exp1) experimental; urgency=medium
# +
# +  * New release train, branch off and rename everything to ruby2.1
# +    (Closes: #736664)
# +  * Build with GMP library for faster Bignum operations.
# +  * Target experimental as long as ruby 1:1.9.3.1 has not entered
# +    unstable, dropping the versioned dependency for now.
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Thu, 23 Jan 2014 19:25:19 +0100
# +
# +ruby2.0 (2.0.0.484-1) UNRELEASED; urgency=medium
# +
# +  [ Antonio Terceiro ]
# +  * New upstream snapshot.
# +  * Add patch by Yamashita Yuu to fix build against newer OpenSSL
# +    (Closes: #733372)
# +
# +  [ Christian Hofstaedtler ]
# +  * Use any valid Ruby interpreter to bootstrap
# +  * Bump Standards-Version to 3.9.5 (no changes)
# +  * Add myself to Uploaders:
# +  * Add Dependencies to facilitate upgrades from 1.8
# +    * libruby2.0 now depends on ruby2.0
# +    * ruby2.0 now depends on ruby
# +  * Stop installing alternatives/symlinks for binaries:
# +    * /usr/bin/{ruby,erb,testrb,irb,rdoc,ri}
# +
# + -- Christian Hofstaedtler <zeha@debian.org>  Fri, 17 Jan 2014 16:35:57 +0100
# +
# +ruby2.0 (2.0.0.353-1) unstable; urgency=low
# +
# +  * New upstream release
# +    + Includes fix for Heap Overflow in Floating Point Parsing (CVE-2013-4164)
# +      Closes: #730190
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Mon, 25 Nov 2013 22:34:25 -0300
# +
# +ruby2.0 (2.0.0.343-1) unstable; urgency=low
# +
# +  * New upstream version (snapshot from 2.0 maintainance branch).
# +  * fix typo in ruby2.0-tcltk description
# +  * Backported upstream patches from Tanaka Akira to fix FTBFS on:
# +    - GNU/kFreeBSD (Closes: #726095)
# +    - x32 (Closes: #727010)
# +  * Make date for io-console gemspec predictable (Closes: #724974)
# +  * libruby2.0 now depends on libjs-jquery because of rdoc (Closes: #725056)
# +  * Backport upstream patch by Nobuyoshi Nakada to fix include directory in
# +    `pkg-config --cflags` (Closes: #725166)
# +  * Document missing licenses in debian/copyright (Closes: #723161)
# +  * debian/libruby2.0.symbols: add new symbol rb_exec_recursive_paired_outer
# +    (not in the public API though)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Tue, 05 Nov 2013 20:33:23 -0300
# +
# +ruby2.0 (2.0.0.299-2) unstable; urgency=low
# +
# +  * Split Ruby/Tk out of libruby2.0 into its own package, ruby2.0-tcltk. This
# +    will reduce the footprint of a basic Ruby installation.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 15 Sep 2013 22:09:57 -0300
# +
# +ruby2.0 (2.0.0.299-1) unstable; urgency=low
# +
# +  * New upstream release
# +    + Includes a fix for override of existing LDFLAGS when building compiled
# +      extensions that use pkg-config (Closes: #721799).
# +  * debian/rules: forward-port to tcl/tk packages with multi-arch support.
# +    Thanks to Tristan Hill for reporting on build for Ubuntu saucy
# +  * debian/control: ruby2.0 now provides ruby-interpreter
# +  * Now using tarballs generated from the git mirror.
# +    + The released tarballs will modify shipped files on clean. Without this
# +      we can stop messing around with files that need to be recovered after a
# +      `debian/rules clean` to make them match the orig tarball and avoid
# +      spurious diffs.
# +    + This also lets us drop the diffs against generated files such as
# +      tool/config.* and configure.
# +    + documented in debian/README.source
# +  * debian/libruby2.0.symbols: refreshed with 2 new symbols added since last
# +    version.
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Sun, 08 Sep 2013 12:38:34 -0300
# +
# +ruby2.0 (2.0.0.247-1) unstable; urgency=low
# +
# +  * Initial release (Closes: #697703)
# +
# + -- Antonio Terceiro <terceiro@debian.org>  Mon, 07 Jan 2013 14:48:51 -0300
# diff -Nru debian~/control debian/control
# --- debian~/control	1969-12-31 19:00:00.000000000 -0500
# +++ debian/control	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,104 @@
# +Source: ruby2.7
# +Section: ruby
# +Priority: optional
# +Maintainer: Debian Ruby Team <pkg-ruby-extras-maintainers@lists.alioth.debian.org>
# +Uploaders: Antonio Terceiro <terceiro@debian.org>,
# +           Chris Hofstaedtler <zeha@debian.org>,
# +           Lucas Kanashiro <kanashiro@debian.org>,
# +           Utkarsh Gupta <utkarsh@debian.org>
# +Build-Depends: bison,
# +               chrpath,
# +               coreutils (>= 7.5),
# +               debhelper-compat (= 12),
# +               file,
# +               libffi-dev,
# +               libgdbm-compat-dev,
# +               libgdbm-dev,
# +               libgmp-dev,
# +               libncurses-dev,
# +               libreadline6-dev,
# +               libssl-dev,
# +               libyaml-dev,
# +               netbase,
# +               openssl,
# +               procps,
# +               ruby:native <cross>,
# +               rubygems-integration (>= 1.6),
# +               systemtap-sdt-dev [linux-any],
# +               tzdata,
# +               zlib1g-dev
# +Standards-Version: 4.5.0
# +Homepage: https://www.ruby-lang.org/
# +Vcs-Git: https://salsa.debian.org/ruby-team/ruby.git
# +Vcs-Browser: https://salsa.debian.org/ruby-team/ruby
# +Rules-Requires-Root: no
# +
# +Package: ruby2.7
# +Multi-Arch: allowed
# +Architecture: any
# +Depends: rubygems-integration (>= 1.11),
# +         ${misc:Depends},
# +         ${shlibs:Depends}
# +Recommends: fonts-lato,
# +            libjs-jquery
# +Description: Interpreter of object-oriented scripting language Ruby
# + Ruby is the interpreted scripting language for quick and easy
# + object-oriented programming.  It has many features to process text
# + files and to do system management tasks (as in perl).  It is simple,
# + straight-forward, and extensible.
# + .
# + In the name of this package, `2.7' indicates the Ruby library compatibility
# + version. This package currently provides the `2.7.x' branch of Ruby.
# +
# +Package: libruby2.7
# +Section: libs
# +Multi-Arch: same
# +Architecture: any
# +Depends: rake (>= 10.4.2),
# +         ruby-did-you-mean (>= 1.0),
# +         ruby-minitest (>= 5.4),
# +         ruby-net-telnet (>= 0.1.1),
# +         ruby-test-unit (>= 3.0.8~),
# +         ruby-xmlrpc (>= 0.3.0~),
# +         ${misc:Depends},
# +         ${shlibs:Depends}
# +Provides: ${libruby:Provides}
# +Description: Libraries necessary to run Ruby 2.7
# + Ruby is the interpreted scripting language for quick and easy
# + object-oriented programming.  It has many features to process text
# + files and to do system management tasks (as in perl).  It is simple,
# + straight-forward, and extensible.
# + .
# + This package includes the 'libruby-2.7' library, necessary to run Ruby 2.7.
# + (API version 2.7.0)
# +
# +Package: ruby2.7-dev
# +Multi-Arch: same
# +Architecture: any
# +Depends: libgmp-dev,
# +         libruby2.7 (= ${binary:Version}),
# +         ${misc:Depends},
# +         ${shlibs:Depends}
# +Recommends: ruby2.7-doc
# +Description: Header files for compiling extension modules for the Ruby 2.7
# + Ruby is the interpreted scripting language for quick and easy
# + object-oriented programming.  It has many features to process text
# + files and to do system management tasks (as in perl).  It is simple,
# + straight-forward, and extensible.
# + .
# + This package contains the header files and the mkmf library, necessary
# + to make extension library for Ruby 2.7. It is also required to build
# + many gems.
# +
# +Package: ruby2.7-doc
# +Multi-Arch: foreign
# +Section: doc
# +Architecture: all
# +Depends: ${misc:Depends}
# +Description: Documentation for Ruby 2.7
# + Ruby is the interpreted scripting language for quick and easy
# + object-oriented programming.  It has many features to process text
# + files and to do system management tasks (as in perl).  It is simple,
# + straight-forward, and extensible.
# + .
# + This package contains the autogenerated documentation for Ruby 2.7.
# diff -Nru debian~/copyright debian/copyright
# --- debian~/copyright	1969-12-31 19:00:00.000000000 -0500
# +++ debian/copyright	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,1002 @@
# +Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
# +Upstream-Name: ruby
# +Source: https://ftp.ruby-lang.org/pub/ruby/
# +Files-Excluded: gems/*-* ext/fiddle/libffi-*
# +
# +Files: *
# +Copyright: Yukihiro Matsumoto <matz@netlab.jp> and others
# +License: BSD-2-clause or Ruby
# +
# +Files:
# + include/ruby/oniguruma.h
# + regcomp.c
# + regerror.c
# + regexec.c
# + regint.h
# + regparse.c
# + regparse.h
# +Copyright:
# + 2002-2009  K.Kosako  <sndgk393 AT ybb DOT ne DOT jp>
# + 2011-2014  K.Takata  <kentkt AT csc DOT jp>
# +License: BSD-2-clause
# +
# +Files:
# + lib/rdoc/task.rb
# + lib/rubygems/package_task.rb
# +Copyright:
# + 2003, 2004 Jim Weirich
# + 2009 Eric Hodel
# +License: Expat
# +
# +Files: enc/*.c
# +Copyright: 2002-2008 K.Kosako <sndgk393@ybb@ne@jp>
# +License: BSD-2-clause
# +
# +Files: enc/ascii.c enc/euc_jp.c enc/shift_jis.c enc/windows_31j.c
# +Copyright:
# + 2002-2009 K.Kosako <sndgk393@ybb@ne@jp>
# + 2011 K.Takata <kentkt@csc@jp>
# +License: BSD-2-clause
# +
# +Files: enc/gb18030.c
# +Copyright: 2005-2007 KUBO.Takehiro <kubo@jiubao@org>
# +License: BSD-2-clause
# +
# +Files: enc/encdb.c
# +Copyright:2008 Yukihiro.Matsumoto
# +License: BSD-2-clause
# +
# +Files: enc/windows_1250.c enc/windows_1252.c
# +Copyright: 2006-2007  Byte   <byte AT mail DOT kna DOT ru>
# +  K.Kosako  <sndgk393 AT ybb DOT ne DOT jp>
# +License: BSD-2-clause
# +
# +Files: enc/windows_1251.c
# +Copyright: 2006-2007 Byte <byte@mail@kna@ru>
# +License: BSD-2-clause
# +
# +Files: lib/rdoc/generator/darkfish.rb lib/rdoc/generator/template/darkfish/*
# +Copyright: 2007, 2008, Michael Granger and others
# +License: BSD-2-clause
# +
# +Files: lib/rdoc/generator/template/darkfish/fonts/SourceCodePro*
# +Copyright:
# + 2010, 2012 Adobe Systems Incorporated with Reserved Font Name "Source"
# +License: SIL-1.1
# +Comment:
# + This license information was obtained from
# + lib/rdoc/generator/template/darkfish/fonts.css in the source tree.
# +
# +Files: lib/rdoc/generator/template/darkfish/fonts/Lato*
# +Copyright:
# + 2010 Łukasz Dziedzic with Reserved Font Name Lato
# +License: SIL-1.1
# +Comment:
# + This license information was obtained from
# + lib/rdoc/generator/template/darkfish/fonts.css in the source tree.
# +
# +Files: lib/rdoc/generator/template/darkfish/images/*
# +Copyright:
# + Mark James
# +License: CC-BY-3.0-famfamfam
# +
# +Files: lib/rdoc/generator/json_index.rb lib/rdoc/generator/template/json_index/*
# +Copyright: 2009 Vladimir Kolesnikov
# +License: Expat
# +
# +Files: lib/rubygems.rb lib/rubygems/*
# +Copyright: Chad Fowler, Rich Kilmer, Jim Weirich and others
# +License: Expat or Ruby
# +Comment:
# + This license information was obtained from lib/rubygems/LICENSE.txt in
# + the source tree.
# +
# +Files: util.c
# +Copyright:
# + 1991, 2000, 2001 by Lucent Technologies.
# + 2004-2008 David Schultz <das@FreeBSD.ORG> All rights reserved.
# +License: PreserveNotice
# + Permission to use, copy, modify, and distribute this software for any
# + purpose without fee is hereby granted, provided that this entire notice
# + is included in all copies of any software which is or includes a copy
# + or modification of this software and in all copies of the supporting
# + documentation for such software.
# + .
# + THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
# + WARRANTY.  IN PARTICULAR, NEITHER THE AUTHOR NOR LUCENT MAKES ANY
# + REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
# + OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
# +
# +Files: random.c
# +Copyright: 1997 - 2002, Makoto Matsumoto and Takuji Nishimura, All rights reserved.
# +License: BSD-2-clause
# +
# +Files: vsnprintf.c
# +Copyright:
# + 1990, 1993 The Regents of the University of California.  All rights reserved.
# + This code is derived from software contributed to Berkeley by Chris Torek.
# +License: 3C-BSD
# +
# +Files:
# + st.c missing/alloca.c missing/dup2.c missing/erf.c
# + missing/finite.c missing/hypot.c missing/isinf.c missing/isnan.c
# + missing/lgamma_r.c missing/memcmp.c missing/memmove.c missing/strchr.c
# + missing/strstr.c missing/tgamma.c
# + ext/digest/sha1/sha1.c ext/digest/sha1/sha1.h
# +Copyright: (none)
# +License: PublicDomain
# + Thise files have been placed in the Public Domain.
# +
# +Files: missing/crypt.c
# +Copyright:
# + 1989, 1993 The Regents of the University of California. All rights reserved.
# + This code is derived from software contributed to Berkeley by
# + Tom Truscott.
# +License: 3C-BSD
# +
# +Files: missing/setproctitle.c
# +Copyright:
# + 2003 Damien Miller
# + 1983, 1995-1997 Eric P. Allman
# + 1989, 1993 The Regents of the University of California. All rights reserved.
# +License: 3C-BSD
# +
# +Files: missing/strlcat.c missing/strlcpy.c
# +Copyright:
# + 1998 Todd C. Miller. All rights reserved.
# +License: BSD-3-clause
# +
# +Files: missing/langinfo.c
# +Copyright:
# + 2002-03-11 Markus.Kuhn@cl.cam.ac.uk
# +License: AllPermissions
# + Permission to use, copy, modify, and distribute this software
# + for any purpose and without fee is hereby granted. The author
# + disclaims all warranties with regard to this software.
# +
# +Files: win32/win32.*
# +Copyright:
# + Copyright (C) 1993 Intergraph Corporation
# + Copyright (C) 1993-2011 Yukihiro Matsumoto
# + Copyright (C) 2000 Network Applied Communication Laboratory, Inc.
# + Copyright (C) 2000 Information-technology Promotion Agency, Japan
# +License: PartialGplArtisticAndRuby
# + The file carries two distinct licenses, individual functions are licensed
# + under different licenses.
# + .
# + Applicable licenses are either "Artistic and GPL" or "Ruby".
# + .
# + On Debian systems, the full text of the GNU General Public
# + License version 2 can be found in the file
# + `/usr/share/common-licenses/GPL-2', and the Artistic License
# + in `/usr/share/common-licenses/Artistic'.
# + .
# + The full text of the Ruby license can be found further below.
# +
# +Files: ext/digest/md5/md5.c ext/digest/md5/md5.h
# +Copyright: 1999, 2000 Aladdin Enterprises.  All rights reserved.
# +License: zlib/libpng
# +
# +Files: ext/digest/rmd160/rmd160.c ext/digest/rmd160/rmd160.h
# +Copyright: 1996 Katholieke Universiteit Leuven. All Rights Reserved.
# +License: BSD-3-clause
# +
# +Files: ext/digest/sha2/sha2.c ext/digest/sha2/sha2.h
# +Copyright: 2000 Aaron D. Gifford.  All rights reserved.
# +License: BSD-3-clause
# +
# +Files: ext/nkf/nkf-utf8/config.h ext/nkf/nkf-utf8/nkf.c ext/nkf/nkf-utf8/utf8tbl.c
# +Copyright: 1987, Fujitsu LTD. (Itaru ICHIKAWA)
# + 1996-2013, The nkf Project.
# +License: zlib/libpng
# +
# +Files: ext/socket/addrinfo.h ext/socket/getaddrinfo.c ext/socket/getnameinfo.c
# +Copyright: 1995, 1996, 1997, 1998, and 1999 WIDE Project. All rights reserved.
# +License: BSD-3-clause
# +
# +Files: ext/win32ole/win32ole.c
# +Copyright:
# + 1995 Microsoft Corporation. All rights reserved.
# + Developed by ActiveWare Internet Corp.
# + Other modifications Copyright (c) 1997, 1998 by Gurusamy Sarathy
# + <gsar@umich.edu> and Jan Dubois <jan.dubois@ibm.net>
# +License: GPL-1+ or Artistic
# +
# +Files: ccan/list/list.h
# +Copyright: unspecified
# +License: Expat
# +
# +Files:
# + ccan/check_type/check_type.h
# + ccan/str/str.h
# + ccan/container_of/container_of.h
# + ccan/build_assert/build_assert.h
# +Copyright: unspecified
# +License: CC0
# +
# +Files:
# + enc/trans/JIS/JISX0201-KANA%UCS.src
# + enc/trans/JIS/JISX0208@1990%UCS.src
# + enc/trans/JIS/JISX0212%UCS.src
# + enc/trans/JIS/UCS%JISX0201-KANA.src
# + enc/trans/JIS/UCS%JISX0208@1990.src
# + enc/trans/JIS/UCS%JISX0212.src
# +Copyright: 2015 Unicode®, Inc.  All Rights reserved.
# +License: Unicode
# +
# +Files:
# + enc/trans/JIS/UCS@BMP%JISX0213-1.src
# + enc/trans/JIS/UCS@BMP%JISX0213-2.src
# + enc/trans/JIS/UCS@SIP%JISX0213-1.src
# + enc/trans/JIS/UCS@SIP%JISX0213-2.src
# +Copyright:
# + 2001 earthian@tama.or.jp, All Rights Reserved.
# + 2001 I'O, All Rights Reserved.
# +License: Permissive
# +
# +Files:
# + enc/trans/JIS/JISX0213-1%UCS@BMP.src
# + enc/trans/JIS/JISX0213-1%UCS@SIP.src
# + enc/trans/JIS/JISX0213-2%UCS@BMP.src
# + enc/trans/JIS/JISX0213-2%UCS@SIP.src
# +Copyright:
# + 2001 earthian@tama.or.jp, All Rights Reserved.
# + 2001 I'O, All Rights Reserved.
# + 2006 Project X0213, All Rights Reserved.
# +License: Permissive
# +
# +Files: debian/*
# +Copyright: 2013-2015 Antonio Terceiro <terceiro@debian.org>
# + 2014 Christian Hofstaedtler <zeha@debian.org>
# + 2020 Lucas Kanashiro <kanashiro@debian.org>
# +License: BSD-2-clause or Ruby
# +Comment:
# + The Debian packaging is licensed under the same terms as the original package.
# +
# +License: Artistic
# + On Debian systems, the full text of the Artistic License
# + can be found in the file `/usr/share/common-licenses/Artistic'.
# +
# +License: BSD-2-clause
# + Redistribution and use in source and binary forms, with or without
# + modification, are permitted provided that the following conditions
# + are met:
# + 1. Redistributions of source code must retain the above copyright
# + notice, this list of conditions and the following disclaimer.
# + 2. Redistributions in binary form must reproduce the above copyright
# + notice, this list of conditions and the following disclaimer in the
# + documentation and/or other materials provided with the distribution.
# + .
# + THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# + ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# + IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# + ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# + FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# + DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# + OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# + HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# + LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# + OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# + SUCH DAMAGE.
# +
# +License: 3C-BSD
# + Redistribution and use in source and binary forms, with or without
# + modification, are permitted provided that the following conditions
# + are met:
# + 1. Redistributions of source code must retain the above copyright
# +    notice, this list of conditions and the following disclaimer.
# + 2. Redistributions in binary form must reproduce the above copyright
# +    notice, this list of conditions and the following disclaimer in the
# +    documentation and/or other materials provided with the distribution.
# + 3. Neither the name of the University nor the names of its contributors
# +    may be used to endorse or promote products derived from this software
# +    without specific prior written permission.
# + .
# + THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# + ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# + IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# + ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# + FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# + DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# + OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# + HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# + LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# + OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# + SUCH DAMAGE.
# +
# +License: BSD-3-clause
# + Redistribution and use in source and binary forms, with or without
# + modification, are permitted provided that the following conditions are met:
# + .
# + * Redistributions of source code must retain the above copyright notice,
# +   this list of conditions and the following disclaimer.
# + .
# + * Redistributions in binary form must reproduce the above copyright notice,
# +   this list of conditions and the following disclaimer in the documentation
# +   and/or other materials provided with the distribution.
# + .
# + * Neither the name of the author/s, nor the names of the project's
# +   contributors may be used to endorse or promote products derived from this
# +   software without specific prior written permission.
# + .
# + THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# + AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# + IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# + DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# + FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# + DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# + SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# + CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# + OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# + OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# +
# +License: Expat
# + Permission is hereby granted, free of charge, to any person obtaining
# + a copy of this software and associated documentation files (the
# + 'Software'), to deal in the Software without restriction, including
# + without limitation the rights to use, copy, modify, merge, publish,
# + distribute, sublicense, and/or sell copies of the Software, and to
# + permit persons to whom the Software is furnished to do so, subject to
# + the following conditions:
# + .
# + The above copyright notice and this permission notice shall be
# + included in all copies or substantial portions of the Software.
# + .
# + THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# + EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# + MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# + IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# + CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# + TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# + SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# +
# +License: GPL-1+
# + On Debian GNU/Linux systems, the complete text of the GNU General
# + Public License can be found in `/usr/share/common-licenses/GPL-1'.
# +
# +License: Ruby
# + Ruby is copyrighted free software by Yukihiro Matsumoto <matz@netlab.jp>.  You
# + can redistribute it and/or modify it under either the terms of the 2-clause
# + BSDL (see the file BSDL), or the conditions below:
# + .
# +  1. You may make and give away verbatim copies of the source form of the
# +     software without restriction, provided that you duplicate all of the
# +     original copyright notices and associated disclaimers.
# + .
# + 2. You may modify your copy of the software in any way, provided that
# +     you do at least ONE of the following:
# + .
# +       a) place your modifications in the Public Domain or otherwise
# +          make them Freely Available, such as by posting said
# +          modifications to Usenet or an equivalent medium, or by allowing
# +          the author to include your modifications in the software.
# + .
# +       b) use the modified software only within your corporation or
# +          organization.
# + .
# +       c) give non-standard binaries non-standard names, with
# +          instructions on where to get the original software distribution.
# + .
# +       d) make other distribution arrangements with the author.
# + .
# + 3. You may distribute the software in object code or binary form,
# +     provided that you do at least ONE of the following:
# + .
# +       a) distribute the binaries and library files of the software,
# +          together with instructions (in the manual page or equivalent)
# +          on where to get the original distribution.
# + .
# +       b) accompany the distribution with the machine-readable source of
# +          the software.
# + .
# +       c) give non-standard binaries non-standard names, with
# +          instructions on where to get the original software distribution.
# + .
# +       d) make other distribution arrangements with the author.
# + .
# + 4. You may modify and include the part of the software into any other
# +     software (possibly commercial).  But some files in the distribution
# +     are not written by the author, so that they are not under these terms.
# + .
# +     For the list of those files and their copying conditions, see the
# +     file LEGAL.
# + .
# +  5. The scripts and library files supplied as input to or produced as
# +     output from the software do not automatically fall under the
# +     copyright of the software, but belong to whomever generated them,
# +     and may be sold commercially, and may be aggregated with this
# +     software.
# + .
# +  6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# +     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# +     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# +     PURPOSE.
# +
# +License: SIL-1.1
# + -----------------------------------------------------------
# + SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
# + -----------------------------------------------------------
# + .
# + PREAMBLE
# + The goals of the Open Font License (OFL) are to stimulate worldwide
# + development of collaborative font projects, to support the font creation
# + efforts of academic and linguistic communities, and to provide a free and
# + open framework in which fonts may be shared and improved in partnership
# + with others.
# + .
# + The OFL allows the licensed fonts to be used, studied, modified and
# + redistributed freely as long as they are not sold by themselves. The
# + fonts, including any derivative works, can be bundled, embedded,
# + redistributed and/or sold with any software provided that any reserved
# + names are not used by derivative works. The fonts and derivatives,
# + however, cannot be released under any other type of license. The
# + requirement for fonts to remain under this license does not apply
# + to any document created using the fonts or their derivatives.
# + .
# + DEFINITIONS
# + "Font Software" refers to the set of files released by the Copyright
# + Holder(s) under this license and clearly marked as such. This may
# + include source files, build scripts and documentation.
# + .
# + "Reserved Font Name" refers to any names specified as such after the
# + copyright statement(s).
# + .
# + "Original Version" refers to the collection of Font Software components as
# + distributed by the Copyright Holder(s).
# + .
# + "Modified Version" refers to any derivative made by adding to, deleting,
# + or substituting -- in part or in whole -- any of the components of the
# + Original Version, by changing formats or by porting the Font Software to a
# + new environment.
# + .
# + "Author" refers to any designer, engineer, programmer, technical
# + writer or other person who contributed to the Font Software.
# + .
# + PERMISSION & CONDITIONS
# + Permission is hereby granted, free of charge, to any person obtaining
# + a copy of the Font Software, to use, study, copy, merge, embed, modify,
# + redistribute, and sell modified and unmodified copies of the Font
# + Software, subject to the following conditions:
# + .
# + 1) Neither the Font Software nor any of its individual components,
# + in Original or Modified Versions, may be sold by itself.
# + .
# + 2) Original or Modified Versions of the Font Software may be bundled,
# + redistributed and/or sold with any software, provided that each copy
# + contains the above copyright notice and this license. These can be
# + included either as stand-alone text files, human-readable headers or
# + in the appropriate machine-readable metadata fields within text or
# + binary files as long as those fields can be easily viewed by the user.
# + .
# + 3) No Modified Version of the Font Software may use the Reserved Font
# + Name(s) unless explicit written permission is granted by the corresponding
# + Copyright Holder. This restriction only applies to the primary font name as
# + presented to the users.
# + .
# + 4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
# + Software shall not be used to promote, endorse or advertise any
# + Modified Version, except to acknowledge the contribution(s) of the
# + Copyright Holder(s) and the Author(s) or with their explicit written
# + permission.
# + .
# + 5) The Font Software, modified or unmodified, in part or in whole,
# + must be distributed entirely under this license, and must not be
# + distributed under any other license. The requirement for fonts to
# + remain under this license does not apply to any document created
# + using the Font Software.
# + .
# + TERMINATION
# + This license becomes null and void if any of the above conditions are
# + not met.
# + .
# + DISCLAIMER
# + THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# + EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
# + MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
# + OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
# + COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# + INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
# + DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# + FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
# + OTHER DEALINGS IN THE FONT SOFTWARE.
# +
# +License: zlib/libpng
# + This software is provided 'as-is', without any express or implied
# + warranty.  In no event will the authors be held liable for any damages
# + arising from the use of this software.
# + .
# + Permission is granted to anyone to use this software for any purpose,
# + including commercial applications, and to alter it and redistribute it
# + freely, subject to the following restrictions:
# + .
# + 1. The origin of this software must not be misrepresented; you must not
# +    claim that you wrote the original software. If you use this software
# +    in a product, an acknowledgment in the product documentation would be
# +    appreciated but is not required.
# + 2. Altered source versions must be plainly marked as such, and must not be
# +    misrepresented as being the original software.
# + 3. This notice may not be removed or altered from any source distribution.
# + .
# + L. Peter Deutsch
# + ghost@aladdin.com
# +
# +License: CC0
# + Statement of Purpose
# + .
# + The laws of most jurisdictions throughout the world automatically confer
# + exclusive Copyright and Related Rights (defined below) upon the creator and
# + subsequent owner(s) (each and all, an "owner") of an original work of
# + authorship and/or a database (each, a "Work").
# + .
# + Certain owners wish to permanently relinquish those rights to a Work for the
# + purpose of contributing to a commons of creative, cultural and scientific
# + works ("Commons") that the public can reliably and without fear of later
# + claims of infringement build upon, modify, incorporate in other works, reuse
# + and redistribute as freely as possible in any form whatsoever and for any
# + purposes, including without limitation commercial purposes. These owners may
# + contribute to the Commons to promote the ideal of a free culture and the
# + further production of creative, cultural and scientific works, or to gain
# + reputation or greater distribution for their Work in part through the use and
# + efforts of others.
# + .
# + For these and/or other purposes and motivations, and without any expectation
# + of additional consideration or compensation, the person associating CC0 with a
# + Work (the "Affirmer"), to the extent that he or she is an owner of Copyright
# + and Related Rights in the Work, voluntarily elects to apply CC0 to the Work
# + and publicly distribute the Work under its terms, with knowledge of his or her
# + Copyright and Related Rights in the Work and the meaning and intended legal
# + effect of CC0 on those rights.
# + .
# + 1. Copyright and Related Rights. A Work made available under CC0 may be
# + protected by copyright and related or neighboring rights ("Copyright and
# + Related Rights"). Copyright and Related Rights include, but are not limited
# + to, the following:
# + .
# +     the right to reproduce, adapt, distribute, perform, display, communicate,
# +     and translate a Work;
# + .
# +     moral rights retained by the original author(s) and/or performer(s);
# + .
# +     publicity and privacy rights pertaining to a person's image or likeness
# +     depicted in a Work;
# + .
# +     rights protecting against unfair competition in regards to a Work, subject
# +     to the limitations in paragraph 4(a), below;
# + .
# +     rights protecting the extraction, dissemination, use and reuse of data in
# +     a Work;
# + .
# +     database rights (such as those arising under Directive 96/9/EC of the
# +     European Parliament and of the Council of 11 March 1996 on the legal
# +     protection of databases, and under any national implementation thereof,
# +     including any amended or successor version of such directive); and
# + .
# +     other similar, equivalent or corresponding rights throughout the world
# +     based on applicable law or treaty, and any national implementations
# +     thereof.
# + .
# + 2. Waiver. To the greatest extent permitted by, but not in contravention of,
# + applicable law, Affirmer hereby overtly, fully, permanently, irrevocably and
# + unconditionally waives, abandons, and surrenders all of Affirmer's Copyright
# + and Related Rights and associated claims and causes of action, whether now
# + known or unknown (including existing as well as future claims and causes of
# + action), in the Work (i) in all territories worldwide, (ii) for the maximum
# + duration provided by applicable law or treaty (including future time
# + extensions), (iii) in any current or future medium and for any number of
# + copies, and (iv) for any purpose whatsoever, including without limitation
# + commercial, advertising or promotional purposes (the "Waiver"). Affirmer makes
# + the Waiver for the benefit of each member of the public at large and to the
# + detriment of Affirmer's heirs and successors, fully intending that such Waiver
# + shall not be subject to revocation, rescission, cancellation, termination, or
# + any other legal or equitable action to disrupt the quiet enjoyment of the Work
# + by the public as contemplated by Affirmer's express Statement of Purpose.
# + .
# + 3. Public License Fallback. Should any part of the Waiver for any reason be
# + judged legally invalid or ineffective under applicable law, then the Waiver
# + shall be preserved to the maximum extent permitted taking into account
# + Affirmer's express Statement of Purpose. In addition, to the extent the Waiver
# + is so judged Affirmer hereby grants to each affected person a royalty-free,
# + non transferable, non sublicensable, non exclusive, irrevocable and
# + unconditional license to exercise Affirmer's Copyright and Related Rights in
# + the Work (i) in all territories worldwide, (ii) for the maximum duration
# + provided by applicable law or treaty (including future time extensions), (iii)
# + in any current or future medium and for any number of copies, and (iv) for any
# + purpose whatsoever, including without limitation commercial, advertising or
# + promotional purposes (the "License"). The License shall be deemed effective as
# + of the date CC0 was applied by Affirmer to the Work. Should any part of the
# + License for any reason be judged legally invalid or ineffective under
# + applicable law, such partial invalidity or ineffectiveness shall not
# + invalidate the remainder of the License, and in such case Affirmer hereby
# + affirms that he or she will not (i) exercise any of his or her remaining
# + Copyright and Related Rights in the Work or (ii) assert any associated claims
# + and causes of action with respect to the Work, in either case contrary to
# + Affirmer's express Statement of Purpose.
# + .
# + 4. Limitations and Disclaimers.
# + .
# +     No trademark or patent rights held by Affirmer are waived, abandoned,
# +     surrendered, licensed or otherwise affected by this document.
# + .
# +     Affirmer offers the Work as-is and makes no representations or warranties
# +     of any kind concerning the Work, express, implied, statutory or otherwise,
# +     including without limitation warranties of title, merchantability, fitness
# +     for a particular purpose, non infringement, or the absence of latent or
# +      other defects, accuracy, or the present or absence of errors, whether or
# +      not discoverable, all to the greatest extent permissible under applicable
# +      law.
# + .
# +     Affirmer disclaims responsibility for clearing rights of other persons
# +     that may apply to the Work or any use thereof, including without
# +     limitation any person's Copyright and Related Rights in the Work. Further,
# +     Affirmer disclaims responsibility for obtaining any necessary consents,
# +     permissions or other rights required for any use of the Work.
# + .
# +     Affirmer understands and acknowledges that Creative Commons is not a party
# +     to this document and has no duty or obligation with respect to this CC0 or
# +     use of the Work.
# +
# +License: Unicode
# + Copyright © 1991-2016 Unicode, Inc. All rights reserved.
# + Distributed under the Terms of Use in
# + http://www.unicode.org/copyright.html.
# + .
# + Permission is hereby granted, free of charge, to any person obtaining
# + a copy of the Unicode data files and any associated documentation
# + (the "Data Files") or Unicode software and any associated documentation
# + (the "Software") to deal in the Data Files or Software
# + without restriction, including without limitation the rights to use,
# + copy, modify, merge, publish, distribute, and/or sell copies of
# + the Data Files or Software, and to permit persons to whom the Data Files
# + or Software are furnished to do so, provided that
# + (a) this copyright and permission notice appear with all copies
# + of the Data Files or Software,
# + (b) this copyright and permission notice appear in associated
# + documentation, and
# + (c) there is clear notice in each modified Data File or in the Software
# + as well as in the documentation associated with the Data File(s) or
# + Software that the data or software has been modified.
# + .
# + THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF
# + ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# + WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# + NONINFRINGEMENT OF THIRD PARTY RIGHTS.
# + IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS
# + NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL
# + DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
# + DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# + TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# + PERFORMANCE OF THE DATA FILES OR SOFTWARE.
# + .
# + Except as contained in this notice, the name of a copyright holder
# + shall not be used in advertising or otherwise to promote the sale,
# + use or other dealings in these Data Files or Software without prior
# + written authorization of the copyright holder.
# +
# +License: Permissive
# + You can use, modify, distribute this table freely.
# +
# +License: CC-BY-3.0-famfamfam
# + Creative Commons Legal Code
# + .
# + Attribution 3.0 Unported
# + .
# +    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
# +    LEGAL SERVICES. DISTRIBUTION OF THIS LICENSE DOES NOT CREATE AN
# +    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
# +    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
# +    REGARDING THE INFORMATION PROVIDED, AND DISCLAIMS LIABILITY FOR
# +    DAMAGES RESULTING FROM ITS USE.
# + .
# + License
# + .
# + THE WORK (AS DEFINED BELOW) IS PROVIDED UNDER THE TERMS OF THIS CREATIVE
# + COMMONS PUBLIC LICENSE ("CCPL" OR "LICENSE"). THE WORK IS PROTECTED BY
# + COPYRIGHT AND/OR OTHER APPLICABLE LAW. ANY USE OF THE WORK OTHER THAN AS
# + AUTHORIZED UNDER THIS LICENSE OR COPYRIGHT LAW IS PROHIBITED.
# + .
# + BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGREE
# + TO BE BOUND BY THE TERMS OF THIS LICENSE. TO THE EXTENT THIS LICENSE MAY
# + BE CONSIDERED TO BE A CONTRACT, THE LICENSOR GRANTS YOU THE RIGHTS
# + CONTAINED HERE IN CONSIDERATION OF YOUR ACCEPTANCE OF SUCH TERMS AND
# + CONDITIONS.
# + .
# + 1. Definitions
# + .
# + a. "Adaptation" means a work based upon the Work, or upon the Work and
# +    other pre-existing works, such as a translation, adaptation,
# +    derivative work, arrangement of music or other alterations of a
# +    literary or artistic work, or phonogram or performance and includes
# +    cinematographic adaptations or any other form in which the Work may be
# +    recast, transformed, or adapted including in any form recognizably
# +    derived from the original, except that a work that constitutes a
# +    Collection will not be considered an Adaptation for the purpose of
# +    this License. For the avoidance of doubt, where the Work is a musical
# +    work, performance or phonogram, the synchronization of the Work in
# +    timed-relation with a moving image ("synching") will be considered an
# +    Adaptation for the purpose of this License.
# + b. "Collection" means a collection of literary or artistic works, such as
# +    encyclopedias and anthologies, or performances, phonograms or
# +    broadcasts, or other works or subject matter other than works listed
# +    in Section 1(f) below, which, by reason of the selection and
# +    arrangement of their contents, constitute intellectual creations, in
# +    which the Work is included in its entirety in unmodified form along
# +    with one or more other contributions, each constituting separate and
# +    independent works in themselves, which together are assembled into a
# +    collective whole. A work that constitutes a Collection will not be
# +    considered an Adaptation (as defined above) for the purposes of this
# +    License.
# + c. "Distribute" means to make available to the public the original and
# +    copies of the Work or Adaptation, as appropriate, through sale or
# +    other transfer of ownership.
# + d. "Licensor" means the individual, individuals, entity or entities that
# +    offer(s) the Work under the terms of this License.
# + e. "Original Author" means, in the case of a literary or artistic work,
# +    the individual, individuals, entity or entities who created the Work
# +    or if no individual or entity can be identified, the publisher; and in
# +    addition (i) in the case of a performance the actors, singers,
# +    musicians, dancers, and other persons who act, sing, deliver, declaim,
# +    play in, interpret or otherwise perform literary or artistic works or
# +    expressions of folklore; (ii) in the case of a phonogram the producer
# +    being the person or legal entity who first fixes the sounds of a
# +    performance or other sounds; and, (iii) in the case of broadcasts, the
# +    organization that transmits the broadcast.
# + f. "Work" means the literary and/or artistic work offered under the terms
# +    of this License including without limitation any production in the
# +    literary, scientific and artistic domain, whatever may be the mode or
# +    form of its expression including digital form, such as a book,
# +    pamphlet and other writing; a lecture, address, sermon or other work
# +    of the same nature; a dramatic or dramatico-musical work; a
# +    choreographic work or entertainment in dumb show; a musical
# +    composition with or without words; a cinematographic work to which are
# +    assimilated works expressed by a process analogous to cinematography;
# +    a work of drawing, painting, architecture, sculpture, engraving or
# +    lithography; a photographic work to which are assimilated works
# +    expressed by a process analogous to photography; a work of applied
# +    art; an illustration, map, plan, sketch or three-dimensional work
# +    relative to geography, topography, architecture or science; a
# +    performance; a broadcast; a phonogram; a compilation of data to the
# +    extent it is protected as a copyrightable work; or a work performed by
# +    a variety or circus performer to the extent it is not otherwise
# +    considered a literary or artistic work.
# + g. "You" means an individual or entity exercising rights under this
# +    License who has not previously violated the terms of this License with
# +    respect to the Work, or who has received express permission from the
# +    Licensor to exercise rights under this License despite a previous
# +    violation.
# + h. "Publicly Perform" means to perform public recitations of the Work and
# +    to communicate to the public those public recitations, by any means or
# +    process, including by wire or wireless means or public digital
# +    performances; to make available to the public Works in such a way that
# +    members of the public may access these Works from a place and at a
# +    place individually chosen by them; to perform the Work to the public
# +    by any means or process and the communication to the public of the
# +    performances of the Work, including by public digital performance; to
# +    broadcast and rebroadcast the Work by any means including signs,
# +    sounds or images.
# + i. "Reproduce" means to make copies of the Work by any means including
# +    without limitation by sound or visual recordings and the right of
# +    fixation and reproducing fixations of the Work, including storage of a
# +    protected performance or phonogram in digital form or other electronic
# +    medium.
# + .
# + 2. Fair Dealing Rights. Nothing in this License is intended to reduce,
# + limit, or restrict any uses free from copyright or rights arising from
# + limitations or exceptions that are provided for in connection with the
# + copyright protection under copyright law or other applicable laws.
# + .
# + 3. License Grant. Subject to the terms and conditions of this License,
# + Licensor hereby grants You a worldwide, royalty-free, non-exclusive,
# + perpetual (for the duration of the applicable copyright) license to
# + exercise the rights in the Work as stated below:
# + .
# + a. to Reproduce the Work, to incorporate the Work into one or more
# +    Collections, and to Reproduce the Work as incorporated in the
# +    Collections;
# + b. to create and Reproduce Adaptations provided that any such Adaptation,
# +    including any translation in any medium, takes reasonable steps to
# +    clearly label, demarcate or otherwise identify that changes were made
# +    to the original Work. For example, a translation could be marked "The
# +    original work was translated from English to Spanish," or a
# +    modification could indicate "The original work has been modified.";
# + c. to Distribute and Publicly Perform the Work including as incorporated
# +    in Collections; and,
# + d. to Distribute and Publicly Perform Adaptations.
# + e . For the avoidance of doubt:
# + .
# +     i. Non-waivable Compulsory License Schemes. In those jurisdictions in
# +        which the right to collect royalties through any statutory or
# +        compulsory licensing scheme cannot be waived, the Licensor
# +        reserves the exclusive right to collect such royalties for any
# +        exercise by You of the rights granted under this License;
# +    ii. Waivable Compulsory License Schemes. In those jurisdictions in
# +        which the right to collect royalties through any statutory or
# +        compulsory licensing scheme can be waived, the Licensor waives the
# +        exclusive right to collect such royalties for any exercise by You
# +        of the rights granted under this License; and,
# +   iii. Voluntary License Schemes. The Licensor waives the right to
# +        collect royalties, whether individually or, in the event that the
# +        Licensor is a member of a collecting society that administers
# +        voluntary licensing schemes, via that society, from any exercise
# +        by You of the rights granted under this License.
# + .
# + The above rights may be exercised in all media and formats whether now
# + known or hereafter devised. The above rights include the right to make
# + such modifications as are technically necessary to exercise the rights in
# + other media and formats. Subject to Section 8(f), all rights not expressly
# + granted by Licensor are hereby reserved.
# + .
# + 4. Restrictions. The license granted in Section 3 above is expressly made
# + subject to and limited by the following restrictions:
# + .
# + a. You may Distribute or Publicly Perform the Work only under the terms
# +    of this License. You must include a copy of, or the Uniform Resource
# +    Identifier (URI) for, this License with every copy of the Work You
# +    Distribute or Publicly Perform. You may not offer or impose any terms
# +    on the Work that restrict the terms of this License or the ability of
# +    the recipient of the Work to exercise the rights granted to that
# +    recipient under the terms of the License. You may not sublicense the
# +    Work. You must keep intact all notices that refer to this License and
# +    to the disclaimer of warranties with every copy of the Work You
# +    Distribute or Publicly Perform. When You Distribute or Publicly
# +    Perform the Work, You may not impose any effective technological
# +    measures on the Work that restrict the ability of a recipient of the
# +    Work from You to exercise the rights granted to that recipient under
# +    the terms of the License. This Section 4(a) applies to the Work as
# +    incorporated in a Collection, but this does not require the Collection
# +    apart from the Work itself to be made subject to the terms of this
# +    License. If You create a Collection, upon notice from any Licensor You
# +    must, to the extent practicable, remove from the Collection any credit
# +    as required by Section 4(b), as requested. If You create an
# +    Adaptation, upon notice from any Licensor You must, to the extent
# +    practicable, remove from the Adaptation any credit as required by
# +    Section 4(b), as requested.
# + b. If You Distribute, or Publicly Perform the Work or any Adaptations or
# +    Collections, You must, unless a request has been made pursuant to
# +    Section 4(a), keep intact all copyright notices for the Work and
# +    provide, reasonable to the medium or means You are utilizing: (i) the
# +    name of the Original Author (or pseudonym, if applicable) if supplied,
# +    and/or if the Original Author and/or Licensor designate another party
# +    or parties (e.g., a sponsor institute, publishing entity, journal) for
# +    attribution ("Attribution Parties") in Licensor's copyright notice,
# +    terms of service or by other reasonable means, the name of such party
# +    or parties; (ii) the title of the Work if supplied; (iii) to the
# +    extent reasonably practicable, the URI, if any, that Licensor
# +    specifies to be associated with the Work, unless such URI does not
# +    refer to the copyright notice or licensing information for the Work;
# +    and (iv) , consistent with Section 3(b), in the case of an Adaptation,
# +    a credit identifying the use of the Work in the Adaptation (e.g.,
# +    "French translation of the Work by Original Author," or "Screenplay
# +    based on original Work by Original Author"). The credit required by
# +    this Section 4 (b) may be implemented in any reasonable manner;
# +    provided, however, that in the case of a Adaptation or Collection, at
# +    a minimum such credit will appear, if a credit for all contributing
# +    authors of the Adaptation or Collection appears, then as part of these
# +    credits and in a manner at least as prominent as the credits for the
# +    other contributing authors. For the avoidance of doubt, You may only
# +    use the credit required by this Section for the purpose of attribution
# +    in the manner set out above and, by exercising Your rights under this
# +    License, You may not implicitly or explicitly assert or imply any
# +    connection with, sponsorship or endorsement by the Original Author,
# +    Licensor and/or Attribution Parties, as appropriate, of You or Your
# +    use of the Work, without the separate, express prior written
# +    permission of the Original Author, Licensor and/or Attribution
# +    Parties.
# + c. Except as otherwise agreed in writing by the Licensor or as may be
# +    otherwise permitted by applicable law, if You Reproduce, Distribute or
# +    Publicly Perform the Work either by itself or as part of any
# +    Adaptations or Collections, You must not distort, mutilate, modify or
# +    take other derogatory action in relation to the Work which would be
# +    prejudicial to the Original Author's honor or reputation. Licensor
# +    agrees that in those jurisdictions (e.g. Japan), in which any exercise
# +    of the right granted in Section 3(b) of this License (the right to
# +    make Adaptations) would be deemed to be a distortion, mutilation,
# +    modification or other derogatory action prejudicial to the Original
# +    Author's honor and reputation, the Licensor will waive or not assert,
# +    as appropriate, this Section, to the fullest extent permitted by the
# +    applicable national law, to enable You to reasonably exercise Your
# +    right under Section 3(b) of this License (right to make Adaptations)
# +    but not otherwise.
# + .
# + 5. Representations, Warranties and Disclaimer
# + .
# + UNLESS OTHERWISE MUTUALLY AGREED TO BY THE PARTIES IN WRITING, LICENSOR
# + OFFERS THE WORK AS-IS AND MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY
# + KIND CONCERNING THE WORK, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,
# + INCLUDING, WITHOUT LIMITATION, WARRANTIES OF TITLE, MERCHANTIBILITY,
# + FITNESS FOR A PARTICULAR PURPOSE, NONINFRINGEMENT, OR THE ABSENCE OF
# + LATENT OR OTHER DEFECTS, ACCURACY, OR THE PRESENCE OF ABSENCE OF ERRORS,
# + WHETHER OR NOT DISCOVERABLE. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION
# + OF IMPLIED WARRANTIES, SO SUCH EXCLUSION MAY NOT APPLY TO YOU.
# + .
# + 6. Limitation on Liability. EXCEPT TO THE EXTENT REQUIRED BY APPLICABLE
# + LAW, IN NO EVENT WILL LICENSOR BE LIABLE TO YOU ON ANY LEGAL THEORY FOR
# + ANY SPECIAL, INCIDENTAL, CONSEQUENTIAL, PUNITIVE OR EXEMPLARY DAMAGES
# + ARISING OUT OF THIS LICENSE OR THE USE OF THE WORK, EVEN IF LICENSOR HAS
# + BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
# + .
# + 7. Termination
# + .
# + a. This License and the rights granted hereunder will terminate
# +    automatically upon any breach by You of the terms of this License.
# +    Individuals or entities who have received Adaptations or Collections
# +    from You under this License, however, will not have their licenses
# +    terminated provided such individuals or entities remain in full
# +    compliance with those licenses. Sections 1, 2, 5, 6, 7, and 8 will
# +    survive any termination of this License.
# + b. Subject to the above terms and conditions, the license granted here is
# +    perpetual (for the duration of the applicable copyright in the Work).
# +    Notwithstanding the above, Licensor reserves the right to release the
# +    Work under different license terms or to stop distributing the Work at
# +    any time; provided, however that any such election will not serve to
# +    withdraw this License (or any other license that has been, or is
# +    required to be, granted under the terms of this License), and this
# +    License will continue in full force and effect unless terminated as
# +    stated above.
# + .
# + 8. Miscellaneous
# + .
# + a. Each time You Distribute or Publicly Perform the Work or a Collection,
# +    the Licensor offers to the recipient a license to the Work on the same
# +    terms and conditions as the license granted to You under this License.
# + b. Each time You Distribute or Publicly Perform an Adaptation, Licensor
# +    offers to the recipient a license to the original Work on the same
# +    terms and conditions as the license granted to You under this License.
# + c. If any provision of this License is invalid or unenforceable under
# +    applicable law, it shall not affect the validity or enforceability of
# +    the remainder of the terms of this License, and without further action
# +    by the parties to this agreement, such provision shall be reformed to
# +    the minimum extent necessary to make such provision valid and
# +    enforceable.
# + d. No term or provision of this License shall be deemed waived and no
# +    breach consented to unless such waiver or consent shall be in writing
# +    and signed by the party to be charged with such waiver or consent.
# + e. This License constitutes the entire agreement between the parties with
# +    respect to the Work licensed here. There are no understandings,
# +    agreements or representations with respect to the Work not specified
# +    here. Licensor shall not be bound by any additional provisions that
# +    may appear in any communication from You. This License may not be
# +    modified without the mutual written agreement of the Licensor and You.
# + f. The rights granted under, and the subject matter referenced, in this
# +    License were drafted utilizing the terminology of the Berne Convention
# +    for the Protection of Literary and Artistic Works (as amended on
# +    September 28, 1979), the Rome Convention of 1961, the WIPO Copyright
# +    Treaty of 1996, the WIPO Performances and Phonograms Treaty of 1996
# +    and the Universal Copyright Convention (as revised on July 24, 1971).
# +    These rights and subject matter take effect in the relevant
# +    jurisdiction in which the License terms are sought to be enforced
# +    according to the corresponding provisions of the implementation of
# +    those treaty provisions in the applicable national law. If the
# +    standard suite of rights granted under applicable copyright law
# +    includes additional rights not granted under this License, such
# +    additional rights are deemed to be included in the License; this
# +    License is not intended to restrict the license of any rights under
# +    applicable law.
# + .
# + .
# + Creative Commons Notice
# + .
# +    Creative Commons is not a party to this License, and makes no warranty
# +    whatsoever in connection with the Work. Creative Commons will not be
# +    liable to You or any party on any legal theory for any damages
# +    whatsoever, including without limitation any general, special,
# +    incidental or consequential damages arising in connection to this
# +    license. Notwithstanding the foregoing two (2) sentences, if Creative
# +    Commons has expressly identified itself as the Licensor hereunder, it
# +    shall have all rights and obligations of Licensor.
# + .
# +    Except for the limited purpose of indicating to the public that the
# +    Work is licensed under the CCPL, Creative Commons does not authorize
# +    the use by either party of the trademark "Creative Commons" or any
# +    related trademark or logo of Creative Commons without the prior
# +    written consent of Creative Commons. Any permitted use will be in
# +    compliance with Creative Commons' then-current trademark usage
# +    guidelines, as may be published on its website or otherwise made
# +    available upon request from time to time. For the avoidance of doubt,
# +    this trademark restriction does not form part of this License.
# + .
# +    Creative Commons may be contacted at https://creativecommons.org/.
# + .
# + As an author, I would appreciate a reference to my authorship of
# + the Silk icon set contents within a readme file or equivalent documentation
# + for the software which includes the set or a subset of the icons contained
# + within.
# diff -Nru debian~/deleted_on_clean.txt debian/deleted_on_clean.txt
# --- debian~/deleted_on_clean.txt	1969-12-31 19:00:00.000000000 -0500
# +++ debian/deleted_on_clean.txt	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,29 @@
# +.revision.time
# +encdb.h
# +ext/dl/callback/callback-0.c
# +ext/dl/callback/callback-1.c
# +ext/dl/callback/callback-2.c
# +ext/dl/callback/callback-3.c
# +ext/dl/callback/callback-4.c
# +ext/dl/callback/callback-5.c
# +ext/dl/callback/callback-6.c
# +ext/dl/callback/callback-7.c
# +ext/dl/callback/callback-8.c
# +ext/dl/callback/callback.c
# +ext/ripper/eventids1.c
# +ext/ripper/eventids2table.c
# +ext/ripper/ripper.c
# +ext/ripper/ripper.y
# +ext/ripper/y.output
# +golf_prelude.c
# +insns.inc
# +insns_info.inc
# +known_errors.inc
# +miniprelude.c
# +node_name.inc
# +opt_sc.inc
# +optinsn.inc
# +optunifs.inc
# +transdb.h
# +vm.inc
# +vmtc.inc
# diff -Nru debian~/docs debian/docs
# --- debian~/docs	1969-12-31 19:00:00.000000000 -0500
# +++ debian/docs	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,5 @@
# +NEWS
# +README.EXT
# +README.EXT.ja
# +README.ja.md
# +README.md
# diff -Nru debian~/gbp.conf debian/gbp.conf
# --- debian~/gbp.conf	1969-12-31 19:00:00.000000000 -0500
# +++ debian/gbp.conf	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,4 @@
# +[DEFAULT]
# +pristine-tar = False
# +debian-branch = debian
# +upstream-branch = upstream
# diff -Nru debian~/genprovides debian/genprovides
# --- debian~/genprovides	1969-12-31 19:00:00.000000000 -0500
# +++ debian/genprovides	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,8 @@
# +#!/bin/sh
# +
# +set -eu
# +
# +printf 'libruby:Provides='
# +ls -1 "$@" \
# +	| grep -v bundler \
# +	| sed -e 's/_/-/g; s/\(.*\)-\([0-9.]\+\)\.gemspec/ruby-\1 (= \2), /' | xargs echo
# diff -Nru debian~/libruby2.7.install debian/libruby2.7.install
# --- debian~/libruby2.7.install	1969-12-31 19:00:00.000000000 -0500
# +++ debian/libruby2.7.install	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,4 @@
# +/usr/lib/*/*.so.*
# +/usr/lib/*/ruby
# +/usr/lib/ruby
# +/usr/share/systemtap/tapset/libruby*.stp
# diff -Nru debian~/libruby2.7.lintian-overrides debian/libruby2.7.lintian-overrides
# --- debian~/libruby2.7.lintian-overrides	1969-12-31 19:00:00.000000000 -0500
# +++ debian/libruby2.7.lintian-overrides	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,11 @@
# +ruby-script-but-no-ruby-dep
# +package-name-doesnt-match-sonames
# +image-file-in-usr-lib
# +package-contains-empty-directory
# +# The *.so extension files should not be linked against libc but libruby* which
# +# is already linked against libc
# +library-not-linked-against-libc
# +# The racc bundle gem contains 2 scripts (racc2y and y2racc) which have a wrong
# +# path to the ruby interpreter, since they are not in the users' path those
# +# lintian errors are ignored
# +wrong-path-for-interpreter
# diff -Nru debian~/libruby2.7.symbols debian/libruby2.7.symbols
# --- debian~/libruby2.7.symbols	1969-12-31 19:00:00.000000000 -0500
# +++ debian/libruby2.7.symbols	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,1654 @@
# +libruby-2.7.so.2.7 libruby2.7 #MINVER#
# + OnigDefaultCaseFoldFlag@Base 2.7.0~preview1
# + OnigDefaultSyntax@Base 2.7.0~preview1
# + OnigEncAsciiCtypeTable@Base 2.7.0~preview1
# + OnigEncAsciiToLowerCaseTable@Base 2.7.0~preview1
# + OnigEncAsciiToUpperCaseTable@Base 2.7.0~preview1
# + OnigEncDefaultCharEncoding@Base 2.7.0~preview1
# + OnigEncISO_8859_1_ToLowerCaseTable@Base 2.7.0~preview1
# + OnigEncISO_8859_1_ToUpperCaseTable@Base 2.7.0~preview1
# + OnigEncodingASCII@Base 2.7.0~preview1
# + OnigSyntaxASIS@Base 2.7.0~preview1
# + OnigSyntaxEmacs@Base 2.7.0~preview1
# + OnigSyntaxGnuRegex@Base 2.7.0~preview1
# + OnigSyntaxGrep@Base 2.7.0~preview1
# + OnigSyntaxJava@Base 2.7.0~preview1
# + OnigSyntaxPerl58@Base 2.7.0~preview1
# + OnigSyntaxPerl58_NG@Base 2.7.0~preview1
# + OnigSyntaxPerl@Base 2.7.0~preview1
# + OnigSyntaxPosixBasic@Base 2.7.0~preview1
# + OnigSyntaxPosixExtended@Base 2.7.0~preview1
# + OnigSyntaxPython@Base 2.7.0~preview1
# + OnigSyntaxRuby@Base 2.7.0~preview1
# + (optional)coroutine_transfer@Base 2.7.0
# + dln_find_exe_r@Base 2.7.0~preview1
# + dln_find_file_r@Base 2.7.0~preview1
# + dln_load@Base 2.7.0~preview1
# + mjit_call_p@Base 2.7.0~preview2
# + mjit_opts@Base 2.7.0~preview2
# + nucomp_canonicalization@Base 2.7.0~preview1
# + nurat_canonicalization@Base 2.7.0~preview1
# + onig_add_end_call@Base 2.7.0~preview1
# + onig_bbuf_init@Base 2.7.0~preview1
# + onig_compile@Base 2.7.0~preview1
# + onig_compile_ruby@Base 2.7.0~preview1
# + onig_copy_encoding@Base 2.7.0~preview1
# + onig_copy_syntax@Base 2.7.0~preview1
# + onig_end@Base 2.7.0~preview1
# + onig_error_code_to_format@Base 2.7.0~preview1
# + onig_error_code_to_str@Base 2.7.0~preview1
# + onig_foreach_name@Base 2.7.0~preview1
# + onig_free@Base 2.7.0~preview1
# + onig_free_body@Base 2.7.0~preview1
# + onig_get_case_fold_flag@Base 2.7.0~preview1
# + onig_get_default_case_fold_flag@Base 2.7.0~preview1
# + onig_get_encoding@Base 2.7.0~preview1
# + onig_get_match_stack_limit_size@Base 2.7.0~preview1
# + onig_get_options@Base 2.7.0~preview1
# + onig_get_parse_depth_limit@Base 2.7.0~preview1
# + onig_get_syntax@Base 2.7.0~preview1
# + onig_get_syntax_behavior@Base 2.7.0~preview1
# + onig_get_syntax_op2@Base 2.7.0~preview1
# + onig_get_syntax_op@Base 2.7.0~preview1
# + onig_get_syntax_options@Base 2.7.0~preview1
# + onig_init@Base 2.7.0~preview1
# + onig_initialize@Base 2.7.0~preview1
# + onig_is_code_in_cc@Base 2.7.0~preview1
# + onig_is_code_in_cc_len@Base 2.7.0~preview1
# + onig_is_in_code_range@Base 2.7.0~preview1
# + onig_match@Base 2.7.0~preview1
# + onig_memsize@Base 2.7.0~preview1
# + onig_name_to_backref_number@Base 2.7.0~preview1
# + onig_name_to_group_numbers@Base 2.7.0~preview1
# + onig_names_free@Base 2.7.0~preview1
# + onig_new@Base 2.7.0~preview1
# + onig_new_without_alloc@Base 2.7.0~preview1
# + onig_node_free@Base 2.7.0~preview1
# + onig_node_list_add@Base 2.7.0~preview1
# + onig_node_new_alt@Base 2.7.0~preview1
# + onig_node_new_anchor@Base 2.7.0~preview1
# + onig_node_new_enclose@Base 2.7.0~preview1
# + onig_node_new_list@Base 2.7.0~preview1
# + onig_node_new_str@Base 2.7.0~preview1
# + onig_node_str_cat@Base 2.7.0~preview1
# + onig_node_str_clear@Base 2.7.0~preview1
# + onig_node_str_set@Base 2.7.0~preview1
# + onig_noname_group_capture_is_active@Base 2.7.0~preview1
# + onig_null_warn@Base 2.7.0~preview1
# + onig_number_of_capture_histories@Base 2.7.0~preview1
# + onig_number_of_captures@Base 2.7.0~preview1
# + onig_number_of_names@Base 2.7.0~preview1
# + onig_parse_make_tree@Base 2.7.0~preview1
# + onig_reduce_nested_quantifier@Base 2.7.0~preview1
# + onig_reg_init@Base 2.7.0~preview1
# + onig_region_clear@Base 2.7.0~preview1
# + onig_region_copy@Base 2.7.0~preview1
# + onig_region_free@Base 2.7.0~preview1
# + onig_region_init@Base 2.7.0~preview1
# + onig_region_memsize@Base 2.7.0~preview1
# + onig_region_new@Base 2.7.0~preview1
# + onig_region_resize@Base 2.7.0~preview1
# + onig_region_set@Base 2.7.0~preview1
# + onig_renumber_name_table@Base 2.7.0~preview1
# + onig_scan@Base 2.7.0~preview1
# + onig_scan_env_set_error_string@Base 2.7.0~preview1
# + onig_scan_unsigned_number@Base 2.7.0~preview1
# + onig_search@Base 2.7.0~preview1
# + onig_search_gpos@Base 2.7.0~preview1
# + onig_set_default_case_fold_flag@Base 2.7.0~preview1
# + onig_set_default_syntax@Base 2.7.0~preview1
# + onig_set_match_stack_limit_size@Base 2.7.0~preview1
# + onig_set_meta_char@Base 2.7.0~preview1
# + onig_set_parse_depth_limit@Base 2.7.0~preview1
# + onig_set_syntax_behavior@Base 2.7.0~preview1
# + onig_set_syntax_op2@Base 2.7.0~preview1
# + onig_set_syntax_op@Base 2.7.0~preview1
# + onig_set_syntax_options@Base 2.7.0~preview1
# + onig_set_verb_warn_func@Base 2.7.0~preview1
# + onig_set_warn_func@Base 2.7.0~preview1
# + onig_st_init_strend_table_with_size@Base 2.7.0~preview1
# + onig_st_insert_strend@Base 2.7.0~preview1
# + onig_st_lookup_strend@Base 2.7.0~preview1
# + onig_strcpy@Base 2.7.0~preview1
# + onig_vsnprintf_with_pattern@Base 2.7.0~preview1
# + onigenc_always_false_is_allowed_reverse_match@Base 2.7.0~preview1
# + onigenc_always_true_is_allowed_reverse_match@Base 2.7.0~preview1
# + onigenc_apply_all_case_fold_with_map@Base 2.7.0~preview1
# + onigenc_ascii_apply_all_case_fold@Base 2.7.0~preview1
# + onigenc_ascii_get_case_fold_codes_by_str@Base 2.7.0~preview1
# + onigenc_ascii_is_code_ctype@Base 2.7.0~preview1
# + onigenc_ascii_mbc_case_fold@Base 2.7.0~preview1
# + onigenc_ascii_only_case_map@Base 2.7.0~preview1
# + onigenc_get_case_fold_codes_by_str_with_map@Base 2.7.0~preview1
# + onigenc_get_default_encoding@Base 2.7.0~preview1
# + onigenc_get_left_adjust_char_head@Base 2.7.0~preview1
# + onigenc_get_prev_char_head@Base 2.7.0~preview1
# + onigenc_get_right_adjust_char_head@Base 2.7.0~preview1
# + onigenc_get_right_adjust_char_head_with_prev@Base 2.7.0~preview1
# + onigenc_init@Base 2.7.0~preview1
# + onigenc_is_mbc_newline_0x0a@Base 2.7.0~preview1
# + onigenc_mb2_code_to_mbc@Base 2.7.0~preview1
# + onigenc_mb2_code_to_mbclen@Base 2.7.0~preview1
# + onigenc_mb2_is_code_ctype@Base 2.7.0~preview1
# + onigenc_mb4_code_to_mbc@Base 2.7.0~preview1
# + onigenc_mb4_code_to_mbclen@Base 2.7.0~preview1
# + onigenc_mb4_is_code_ctype@Base 2.7.0~preview1
# + onigenc_mbclen_approximate@Base 2.7.0~preview1
# + onigenc_mbn_mbc_case_fold@Base 2.7.0~preview1
# + onigenc_mbn_mbc_to_code@Base 2.7.0~preview1
# + onigenc_minimum_property_name_to_ctype@Base 2.7.0~preview1
# + onigenc_not_support_get_ctype_code_range@Base 2.7.0~preview1
# + onigenc_set_default_encoding@Base 2.7.0~preview1
# + onigenc_single_byte_ascii_only_case_map@Base 2.7.0~preview1
# + onigenc_single_byte_code_to_mbc@Base 2.7.0~preview1
# + onigenc_single_byte_code_to_mbclen@Base 2.7.0~preview1
# + onigenc_single_byte_left_adjust_char_head@Base 2.7.0~preview1
# + onigenc_single_byte_mbc_enc_len@Base 2.7.0~preview1
# + onigenc_single_byte_mbc_to_code@Base 2.7.0~preview1
# + onigenc_step@Base 2.7.0~preview1
# + onigenc_step_back@Base 2.7.0~preview1
# + onigenc_str_bytelen_null@Base 2.7.0~preview1
# + onigenc_strlen@Base 2.7.0~preview1
# + onigenc_strlen_null@Base 2.7.0~preview1
# + onigenc_unicode_apply_all_case_fold@Base 2.7.0~preview1
# + onigenc_unicode_case_map@Base 2.7.0~preview1
# + onigenc_unicode_ctype_code_range@Base 2.7.0~preview1
# + onigenc_unicode_get_case_fold_codes_by_str@Base 2.7.0~preview1
# + onigenc_unicode_is_code_ctype@Base 2.7.0~preview1
# + onigenc_unicode_mbc_case_fold@Base 2.7.0~preview1
# + onigenc_unicode_property_name_to_ctype@Base 2.7.0~preview1
# + onigenc_utf16_32_get_ctype_code_range@Base 2.7.0~preview1
# + onigenc_with_ascii_strncmp@Base 2.7.0~preview1
# + onigenc_with_ascii_strnicmp@Base 2.7.0~preview1
# + rb_Array@Base 2.7.0~preview1
# + rb_Complex@Base 2.7.0~preview1
# + rb_Float@Base 2.7.0~preview1
# + rb_Hash@Base 2.7.0~preview1
# + rb_Integer@Base 2.7.0~preview1
# + rb_Rational@Base 2.7.0~preview1
# + rb_String@Base 2.7.0~preview1
# + rb_absint_numwords@Base 2.7.0~preview1
# + rb_absint_singlebit_p@Base 2.7.0~preview1
# + rb_absint_size@Base 2.7.0~preview1
# + rb_add_event_hook2@Base 2.7.0~preview1
# + rb_add_event_hook@Base 2.7.0~preview1
# + rb_add_method_iseq@Base 2.7.0~preview2
# + rb_adjust_argv_kw_splat@Base 2.7.0~preview2
# + rb_alias@Base 2.7.0~preview1
# + rb_alias_variable@Base 2.7.0~preview1
# + rb_alloc_tmp_buffer@Base 2.7.0~preview1
# + rb_alloc_tmp_buffer_with_count@Base 2.7.0~preview1
# + rb_any_to_s@Base 2.7.0~preview1
# + rb_apply@Base 2.7.0~preview1
# + rb_argv0@Base 2.7.0~preview1
# + rb_arith_seq_new@Base 2.7.0~preview2
# + rb_arithmetic_sequence_extract@Base 2.7.0~preview2
# + rb_ary_aref1@Base 2.7.0~preview2
# + rb_ary_aref@Base 2.7.0~preview1
# + rb_ary_assoc@Base 2.7.0~preview1
# + rb_ary_behead@Base 2.7.0~preview2
# + rb_ary_cat@Base 2.7.0~preview1
# + rb_ary_clear@Base 2.7.0~preview1
# + rb_ary_cmp@Base 2.7.0~preview1
# + rb_ary_concat@Base 2.7.0~preview1
# + rb_ary_delete@Base 2.7.0~preview1
# + rb_ary_delete_at@Base 2.7.0~preview1
# + rb_ary_detransient@Base 2.7.0~preview2
# + rb_ary_dup@Base 2.7.0~preview1
# + rb_ary_each@Base 2.7.0~preview1
# + rb_ary_entry@Base 2.7.0~preview1
# + rb_ary_free@Base 2.7.0~preview1
# + rb_ary_freeze@Base 2.7.0~preview1
# + rb_ary_includes@Base 2.7.0~preview1
# + rb_ary_join@Base 2.7.0~preview1
# + rb_ary_memsize@Base 2.7.0~preview1
# + rb_ary_modify@Base 2.7.0~preview1
# + rb_ary_new@Base 2.7.0~preview1
# + rb_ary_new_capa@Base 2.7.0~preview1
# + rb_ary_new_from_args@Base 2.7.0~preview1
# + rb_ary_new_from_values@Base 2.7.0~preview1
# + rb_ary_plus@Base 2.7.0~preview1
# + rb_ary_pop@Base 2.7.0~preview1
# + rb_ary_ptr_use_end@Base 2.7.0~preview2
# + rb_ary_ptr_use_start@Base 2.7.0~preview2
# + rb_ary_push@Base 2.7.0~preview1
# + rb_ary_rassoc@Base 2.7.0~preview1
# + rb_ary_replace@Base 2.7.0~preview1
# + rb_ary_resize@Base 2.7.0~preview1
# + rb_ary_resurrect@Base 2.7.0~preview1
# + rb_ary_reverse@Base 2.7.0~preview1
# + rb_ary_rotate@Base 2.7.0~preview1
# + rb_ary_shared_with_p@Base 2.7.0~preview1
# + rb_ary_shift@Base 2.7.0~preview1
# + rb_ary_sort@Base 2.7.0~preview1
# + rb_ary_sort_bang@Base 2.7.0~preview1
# + rb_ary_store@Base 2.7.0~preview1
# + rb_ary_subseq@Base 2.7.0~preview1
# + rb_ary_tmp_new@Base 2.7.0~preview1
# + rb_ary_tmp_new_from_values@Base 2.7.0~preview2
# + rb_ary_to_ary@Base 2.7.0~preview1
# + rb_ary_to_s@Base 2.7.0~preview1
# + rb_ary_unshift@Base 2.7.0~preview1
# + rb_ascii8bit_encindex@Base 2.7.0~preview1
# + rb_ascii8bit_encoding@Base 2.7.0~preview1
# + rb_assert_failure@Base 2.7.0~preview2
# + rb_assoc_new@Base 2.7.0~preview1
# + rb_ast_add_local_table@Base 2.7.2
# + rb_ast_add_mark_object@Base 2.7.0~preview2
# + rb_ast_delete_node@Base 2.7.0~preview2
# + rb_ast_dispose@Base 2.7.0~preview2
# + rb_ast_free@Base 2.7.0~preview2
# + rb_ast_mark@Base 2.7.0~preview2
# + rb_ast_memsize@Base 2.7.0~preview2
# + rb_ast_new@Base 2.7.0~preview2
# + rb_ast_newnode@Base 2.7.0~preview2
# + rb_ast_update_references@Base 2.7.0~preview2
# + rb_attr@Base 2.7.0~preview1
# + rb_attr_get@Base 2.7.0~preview1
# + rb_autoload@Base 2.7.0~preview2
# + rb_autoload_load@Base 2.7.0~preview1
# + rb_autoload_p@Base 2.7.0~preview1
# + rb_autoloading_value@Base 2.7.0~preview2
# + rb_backref_get@Base 2.7.0~preview1
# + rb_backref_set@Base 2.7.0~preview1
# + rb_backtrace@Base 2.7.0~preview1
# + rb_backtrace_use_iseq_first_lineno_for_last_location@Base 2.7.0~preview2
# + rb_big2dbl@Base 2.7.0~preview1
# + rb_big2ll@Base 2.7.0~preview1
# + rb_big2long@Base 2.7.0~preview1
# + rb_big2str@Base 2.7.0~preview1
# + rb_big2str_generic@Base 2.7.0~preview1
# + rb_big2str_gmp@Base 2.7.0~preview1
# + rb_big2str_poweroftwo@Base 2.7.0~preview1
# + rb_big2ull@Base 2.7.0~preview1
# + rb_big2ulong@Base 2.7.0~preview1
# + rb_big_2comp@Base 2.7.0~preview1
# + rb_big_and@Base 2.7.0~preview1
# + rb_big_clone@Base 2.7.0~preview1
# + rb_big_cmp@Base 2.7.0~preview1
# + rb_big_div@Base 2.7.0~preview1
# + rb_big_divmod@Base 2.7.0~preview1
# + rb_big_divrem_gmp@Base 2.7.0~preview1
# + rb_big_divrem_normal@Base 2.7.0~preview1
# + rb_big_eq@Base 2.7.0~preview1
# + rb_big_eql@Base 2.7.0~preview1
# + rb_big_idiv@Base 2.7.0~preview1
# + rb_big_lshift@Base 2.7.0~preview1
# + rb_big_minus@Base 2.7.0~preview1
# + rb_big_modulo@Base 2.7.0~preview1
# + rb_big_mul@Base 2.7.0~preview1
# + rb_big_mul_balance@Base 2.7.0~preview1
# + rb_big_mul_gmp@Base 2.7.0~preview1
# + rb_big_mul_karatsuba@Base 2.7.0~preview1
# + rb_big_mul_normal@Base 2.7.0~preview1
# + rb_big_mul_toom3@Base 2.7.0~preview1
# + rb_big_new@Base 2.7.0~preview1
# + rb_big_norm@Base 2.7.0~preview1
# + rb_big_or@Base 2.7.0~preview1
# + rb_big_pack@Base 2.7.0~preview1
# + rb_big_plus@Base 2.7.0~preview1
# + rb_big_pow@Base 2.7.0~preview1
# + rb_big_resize@Base 2.7.0~preview1
# + rb_big_rshift@Base 2.7.0~preview1
# + rb_big_sign@Base 2.7.0~preview1
# + rb_big_sq_fast@Base 2.7.0~preview1
# + rb_big_unpack@Base 2.7.0~preview1
# + rb_big_xor@Base 2.7.0~preview1
# + rb_bigzero_p@Base 2.7.0~preview1
# + rb_binding_new@Base 2.7.0~preview1
# + rb_block_call@Base 2.7.0~preview1
# + rb_block_call_kw@Base 2.7.0~preview2
# + rb_block_given_p@Base 2.7.0~preview1
# + rb_block_lambda@Base 2.7.0~preview1
# + rb_block_param_proxy@Base 2.7.0~preview2
# + rb_block_proc@Base 2.7.0~preview1
# + rb_bug@Base 2.7.0~preview1
# + rb_bug_errno@Base 2.7.0~preview1
# + rb_bug_reporter_add@Base 2.7.0~preview1
# + rb_cArray@Base 2.7.0~preview1
# + rb_cBasicObject@Base 2.7.0~preview1
# + rb_cBinding@Base 2.7.0~preview1
# + rb_cClass@Base 2.7.0~preview1
# + rb_cComplex@Base 2.7.0~preview1
# + rb_cData@Base 2.7.0~preview1
# + rb_cDir@Base 2.7.0~preview1
# + rb_cEncoding@Base 2.7.0~preview1
# + rb_cEnumerator@Base 2.7.0~preview1
# + rb_cFalseClass@Base 2.7.0~preview1
# + rb_cFile@Base 2.7.0~preview1
# + rb_cFloat@Base 2.7.0~preview1
# + rb_cHash@Base 2.7.0~preview1
# + rb_cIO@Base 2.7.0~preview1
# + rb_cISeq@Base 2.7.0~preview1
# + rb_cInteger@Base 2.7.0~preview1
# + rb_cMatch@Base 2.7.0~preview1
# + rb_cMethod@Base 2.7.0~preview1
# + rb_cModule@Base 2.7.0~preview1
# + rb_cNameErrorMesg@Base 2.7.0~preview1
# + rb_cNilClass@Base 2.7.0~preview1
# + rb_cNumeric@Base 2.7.0~preview1
# + rb_cObject@Base 2.7.0~preview1
# + rb_cProc@Base 2.7.0~preview1
# + rb_cRandom@Base 2.7.0~preview1
# + rb_cRange@Base 2.7.0~preview1
# + rb_cRational@Base 2.7.0~preview1
# + rb_cRegexp@Base 2.7.0~preview1
# + rb_cRubyVM@Base 2.7.0~preview1
# + rb_cStat@Base 2.7.0~preview1
# + rb_cString@Base 2.7.0~preview1
# + rb_cStruct@Base 2.7.0~preview1
# + rb_cSymbol@Base 2.7.0~preview1
# + rb_cThread@Base 2.7.0~preview1
# + rb_cTime@Base 2.7.0~preview1
# + rb_cTrueClass@Base 2.7.0~preview1
# + rb_cUnboundMethod@Base 2.7.0~preview1
# + rb_call_super@Base 2.7.0~preview1
# + rb_call_super_kw@Base 2.7.0~preview2
# + rb_callable_method_entry@Base 2.7.0~preview2
# + rb_callable_method_entry_with_refinements@Base 2.7.0~preview2
# + rb_callable_method_entry_without_refinements@Base 2.7.0~preview2
# + rb_catch@Base 2.7.0~preview1
# + rb_catch_obj@Base 2.7.0~preview1
# + rb_char_to_option_kcode@Base 2.7.0~preview1
# + rb_check_array_type@Base 2.7.0~preview1
# + rb_check_convert_type@Base 2.7.0~preview1
# + rb_check_convert_type_with_id@Base 2.7.0~preview2
# + rb_check_copyable@Base 2.7.0~preview1
# + rb_check_frozen@Base 2.7.0~preview1
# + rb_check_funcall@Base 2.7.0~preview1
# + rb_check_funcall_kw@Base 2.7.0~preview2
# + rb_check_hash_type@Base 2.7.0~preview1
# + rb_check_id@Base 2.7.0~preview1
# + rb_check_id_cstr@Base 2.7.0~preview1
# + rb_check_inheritable@Base 2.7.0~preview1
# + rb_check_safe_obj@Base 2.7.0~preview1
# + rb_check_string_type@Base 2.7.0~preview1
# + rb_check_symbol@Base 2.7.0~preview1
# + rb_check_symbol_cstr@Base 2.7.0~preview1
# + rb_check_to_array@Base 2.7.0~preview2
# + rb_check_to_float@Base 2.7.0~preview1
# + rb_check_to_int@Base 2.7.0~preview1
# + rb_check_to_integer@Base 2.7.0~preview1
# + rb_check_trusted@Base 2.7.0~preview1
# + rb_check_type@Base 2.7.0~preview1
# + rb_check_typeddata@Base 2.7.0~preview1
# + rb_class2name@Base 2.7.0~preview1
# + rb_class_get_superclass@Base 2.7.0~preview1
# + rb_class_inherited@Base 2.7.0~preview2
# + rb_class_inherited_p@Base 2.7.0~preview1
# + rb_class_instance_methods@Base 2.7.0~preview1
# + rb_class_ivar_set@Base 2.7.0~preview1
# + rb_class_name@Base 2.7.0~preview1
# + rb_class_new@Base 2.7.0~preview1
# + rb_class_new_instance@Base 2.7.0~preview1
# + rb_class_new_instance_kw@Base 2.7.0~preview2
# + rb_class_path@Base 2.7.0~preview1
# + rb_class_path_cached@Base 2.7.0~preview1
# + rb_class_private_instance_methods@Base 2.7.0~preview1
# + rb_class_protected_instance_methods@Base 2.7.0~preview1
# + rb_class_public_instance_methods@Base 2.7.0~preview1
# + rb_class_real@Base 2.7.0~preview1
# + rb_class_superclass@Base 2.7.0~preview1
# + rb_clear_constant_cache@Base 2.7.0~preview1
# + rb_clear_coverages@Base 2.7.0~preview2
# + rb_clear_method_cache_by_class@Base 2.7.0~preview1
# + rb_cloexec_dup2@Base 2.7.0~preview1
# + rb_cloexec_dup@Base 2.7.0~preview1
# + rb_cloexec_fcntl_dupfd@Base 2.7.0~preview1
# + rb_cloexec_open@Base 2.7.0~preview1
# + rb_cloexec_pipe@Base 2.7.0~preview1
# + rb_close_before_exec@Base 2.7.0~preview1
# + rb_cmperr@Base 2.7.0~preview1
# + rb_cmpint@Base 2.7.0~preview1
# + rb_compile_warn@Base 2.7.0~preview1
# + rb_compile_warning@Base 2.7.0~preview1
# + rb_complex_abs@Base 2.7.0~preview2
# + rb_complex_arg@Base 2.7.0~preview2
# + rb_complex_conjugate@Base 2.7.0~preview2
# + rb_complex_div@Base 2.7.0~preview2
# + rb_complex_imag@Base 2.7.0~preview2
# + rb_complex_minus@Base 2.7.0~preview2
# + rb_complex_mul@Base 2.7.0~preview2
# + rb_complex_new@Base 2.7.0~preview1
# + rb_complex_new_polar@Base 2.7.0~preview2
# + rb_complex_plus@Base 2.7.0~preview2
# + rb_complex_polar@Base 2.7.0~preview1
# + rb_complex_pow@Base 2.7.0~preview2
# + rb_complex_raw@Base 2.7.0~preview1
# + rb_complex_real@Base 2.7.0~preview2
# + rb_complex_uminus@Base 2.7.0~preview2
# + rb_const_defined@Base 2.7.0~preview1
# + rb_const_defined_at@Base 2.7.0~preview1
# + rb_const_defined_from@Base 2.7.0~preview1
# + rb_const_get@Base 2.7.0~preview1
# + rb_const_get_at@Base 2.7.0~preview1
# + rb_const_get_from@Base 2.7.0~preview1
# + rb_const_list@Base 2.7.0~preview1
# + rb_const_lookup@Base 2.7.0~preview2
# + rb_const_missing@Base 2.7.0~preview1
# + rb_const_remove@Base 2.7.0~preview1
# + rb_const_set@Base 2.7.0~preview1
# + rb_const_source_location_at@Base 2.7.0~preview2
# + rb_const_warn_if_deprecated@Base 2.7.0~preview2
# + rb_convert_type@Base 2.7.0~preview1
# + rb_copy_generic_ivar@Base 2.7.0~preview1
# + rb_cstr2inum@Base 2.7.0~preview1
# + rb_cstr_to_dbl@Base 2.7.0~preview1
# + rb_cstr_to_inum@Base 2.7.0~preview1
# + rb_current_receiver@Base 2.7.0~preview1
# + rb_cv_get@Base 2.7.0~preview1
# + rb_cv_set@Base 2.7.0~preview1
# + rb_cvar_defined@Base 2.7.0~preview1
# + rb_cvar_get@Base 2.7.0~preview1
# + rb_cvar_set@Base 2.7.0~preview1
# + rb_data_object_wrap@Base 2.7.0~preview1
# + rb_data_object_zalloc@Base 2.7.0~preview1
# + rb_data_typed_object_wrap@Base 2.7.0~preview1
# + rb_data_typed_object_zalloc@Base 2.7.0~preview1
# + rb_dbl2big@Base 2.7.0~preview1
# + rb_dbl_cmp@Base 2.7.0~preview1
# + rb_dbl_complex_new@Base 2.7.0~preview2
# + rb_debug_inspector_backtrace_locations@Base 2.7.0~preview1
# + rb_debug_inspector_frame_binding_get@Base 2.7.0~preview1
# + rb_debug_inspector_frame_class_get@Base 2.7.0~preview1
# + rb_debug_inspector_frame_iseq_get@Base 2.7.0~preview1
# + rb_debug_inspector_frame_self_get@Base 2.7.0~preview1
# + rb_debug_inspector_open@Base 2.7.0~preview1
# + rb_declare_transcoder@Base 2.7.0~preview1
# + rb_default_external_encoding@Base 2.7.0~preview1
# + rb_default_internal_encoding@Base 2.7.0~preview1
# + rb_default_rs@Base 2.7.0~preview1
# + rb_define_alias@Base 2.7.0~preview1
# + rb_define_alloc_func@Base 2.7.0~preview1
# + rb_define_attr@Base 2.7.0~preview1
# + rb_define_class@Base 2.7.0~preview1
# + rb_define_class_id@Base 2.7.0~preview1
# + rb_define_class_id_under@Base 2.7.0~preview1
# + rb_define_class_under@Base 2.7.0~preview1
# + rb_define_class_variable@Base 2.7.0~preview1
# + rb_define_const@Base 2.7.0~preview1
# + rb_define_dummy_encoding@Base 2.7.0~preview1
# + rb_define_finalizer@Base 2.7.0~preview1
# + rb_define_global_const@Base 2.7.0~preview1
# + rb_define_global_function@Base 2.7.0~preview1
# + rb_define_hooked_variable@Base 2.7.0~preview1
# + rb_define_method@Base 2.7.0~preview1
# + rb_define_method_id@Base 2.7.0~preview1
# + rb_define_module@Base 2.7.0~preview1
# + rb_define_module_function@Base 2.7.0~preview1
# + rb_define_module_id@Base 2.7.0~preview1
# + rb_define_module_id_under@Base 2.7.0~preview1
# + rb_define_module_under@Base 2.7.0~preview1
# + rb_define_private_method@Base 2.7.0~preview1
# + rb_define_protected_method@Base 2.7.0~preview1
# + rb_define_readonly_variable@Base 2.7.0~preview1
# + rb_define_singleton_method@Base 2.7.0~preview1
# + rb_define_variable@Base 2.7.0~preview1
# + rb_define_virtual_variable@Base 2.7.0~preview1
# + rb_detach_process@Base 2.7.0~preview1
# + rb_dir_getwd@Base 2.7.0~preview1
# + rb_dtrace_setup@Base 2.7.0~preview2
# + rb_during_gc@Base 2.7.0~preview1
# + rb_eArgError@Base 2.7.0~preview1
# + rb_eEOFError@Base 2.7.0~preview1
# + rb_eEncCompatError@Base 2.7.0~preview1
# + rb_eEncodingError@Base 2.7.0~preview1
# + rb_eException@Base 2.7.0~preview1
# + rb_eFatal@Base 2.7.0~preview1
# + rb_eFloatDomainError@Base 2.7.0~preview1
# + rb_eFrozenError@Base 2.7.0~preview2
# + rb_eIOError@Base 2.7.0~preview1
# + rb_eIndexError@Base 2.7.0~preview1
# + rb_eInterrupt@Base 2.7.0~preview1
# + rb_eKeyError@Base 2.7.0~preview1
# + rb_eLoadError@Base 2.7.0~preview1
# + rb_eLocalJumpError@Base 2.7.0~preview1
# + rb_eMathDomainError@Base 2.7.0~preview1
# + rb_eNameError@Base 2.7.0~preview1
# + rb_eNoMatchingPatternError@Base 2.7.0~preview2
# + rb_eNoMemError@Base 2.7.0~preview1
# + rb_eNoMethodError@Base 2.7.0~preview1
# + rb_eNotImpError@Base 2.7.0~preview1
# + rb_eRangeError@Base 2.7.0~preview1
# + rb_eRegexpError@Base 2.7.0~preview1
# + rb_eRuntimeError@Base 2.7.0~preview1
# + rb_eScriptError@Base 2.7.0~preview1
# + rb_eSecurityError@Base 2.7.0~preview1
# + rb_eSignal@Base 2.7.0~preview1
# + rb_eStandardError@Base 2.7.0~preview1
# + rb_eStopIteration@Base 2.7.0~preview1
# + rb_eSyntaxError@Base 2.7.0~preview1
# + rb_eSysStackError@Base 2.7.0~preview1
# + rb_eSystemCallError@Base 2.7.0~preview1
# + rb_eSystemExit@Base 2.7.0~preview1
# + rb_eThreadError@Base 2.7.0~preview1
# + rb_eTypeError@Base 2.7.0~preview1
# + rb_eZeroDivError@Base 2.7.0~preview1
# + rb_each@Base 2.7.0~preview1
# + rb_ec_backtrace_object@Base 2.7.0~preview2
# + rb_ec_stack_check@Base 2.7.0~preview2
# + rb_econv_append@Base 2.7.0~preview1
# + rb_econv_asciicompat_encoding@Base 2.7.0~preview1
# + rb_econv_binmode@Base 2.7.0~preview1
# + rb_econv_check_error@Base 2.7.0~preview1
# + rb_econv_close@Base 2.7.0~preview1
# + rb_econv_convert@Base 2.7.0~preview1
# + rb_econv_decorate_at_first@Base 2.7.0~preview1
# + rb_econv_decorate_at_last@Base 2.7.0~preview1
# + rb_econv_encoding_to_insert_output@Base 2.7.0~preview1
# + rb_econv_has_convpath_p@Base 2.7.0~preview1
# + rb_econv_insert_output@Base 2.7.0~preview1
# + rb_econv_make_exception@Base 2.7.0~preview1
# + rb_econv_open@Base 2.7.0~preview1
# + rb_econv_open_exc@Base 2.7.0~preview1
# + rb_econv_open_opts@Base 2.7.0~preview1
# + rb_econv_prepare_options@Base 2.7.0~preview1
# + rb_econv_prepare_opts@Base 2.7.0~preview1
# + rb_econv_putback@Base 2.7.0~preview1
# + rb_econv_putbackable@Base 2.7.0~preview1
# + rb_econv_set_replacement@Base 2.7.0~preview1
# + rb_econv_str_append@Base 2.7.0~preview1
# + rb_econv_str_convert@Base 2.7.0~preview1
# + rb_econv_substr_append@Base 2.7.0~preview1
# + rb_econv_substr_convert@Base 2.7.0~preview1
# + rb_empty_keyword_given_p@Base 2.7.0~preview2
# + rb_enc_alias@Base 2.7.0~preview2
# + rb_enc_ascget@Base 2.7.0~preview1
# + rb_enc_associate@Base 2.7.0~preview1
# + rb_enc_associate_index@Base 2.7.0~preview1
# + rb_enc_capable@Base 2.7.0~preview2
# + rb_enc_check@Base 2.7.0~preview1
# + rb_enc_code_to_mbclen@Base 2.7.0~preview1
# + rb_enc_codelen@Base 2.7.0~preview1
# + rb_enc_codepoint@Base 2.7.0~preview1
# + rb_enc_codepoint_len@Base 2.7.0~preview1
# + rb_enc_compatible@Base 2.7.0~preview1
# + rb_enc_copy@Base 2.7.0~preview1
# + rb_enc_default_external@Base 2.7.0~preview1
# + rb_enc_default_internal@Base 2.7.0~preview1
# + rb_enc_dummy_p@Base 2.7.0~preview1
# + rb_enc_fast_mbclen@Base 2.7.0~preview1
# + rb_enc_find@Base 2.7.0~preview1
# + rb_enc_find_index@Base 2.7.0~preview1
# + rb_enc_from_encoding@Base 2.7.0~preview1
# + rb_enc_from_index@Base 2.7.0~preview1
# + rb_enc_get@Base 2.7.0~preview1
# + rb_enc_get_index@Base 2.7.0~preview1
# + rb_enc_mbclen@Base 2.7.0~preview1
# + rb_enc_nth@Base 2.7.0~preview1
# + rb_enc_path_end@Base 2.7.0~preview1
# + rb_enc_path_last_separator@Base 2.7.0~preview1
# + rb_enc_path_next@Base 2.7.0~preview1
# + rb_enc_path_skip_prefix@Base 2.7.0~preview1
# + rb_enc_precise_mbclen@Base 2.7.0~preview1
# + rb_enc_raise@Base 2.7.0~preview1
# + rb_enc_reg_new@Base 2.7.0~preview1
# + rb_enc_register@Base 2.7.0~preview1
# + rb_enc_replicate@Base 2.7.0~preview1
# + rb_enc_set_base@Base 2.7.0~preview1
# + rb_enc_set_default_external@Base 2.7.0~preview1
# + rb_enc_set_default_internal@Base 2.7.0~preview1
# + rb_enc_set_dummy@Base 2.7.0~preview1
# + rb_enc_set_index@Base 2.7.0~preview1
# + rb_enc_sprintf@Base 2.7.0~preview1
# + rb_enc_str_asciionly_p@Base 2.7.0~preview1
# + rb_enc_str_buf_cat@Base 2.7.0~preview1
# + rb_enc_str_coderange@Base 2.7.0~preview1
# + rb_enc_str_new@Base 2.7.0~preview1
# + rb_enc_str_new_cstr@Base 2.7.0~preview1
# + rb_enc_str_new_static@Base 2.7.0~preview1
# + rb_enc_strlen@Base 2.7.0~preview1
# + rb_enc_symname2_p@Base 2.7.0~preview1
# + rb_enc_symname_p@Base 2.7.0~preview1
# + rb_enc_to_index@Base 2.7.0~preview1
# + rb_enc_tolower@Base 2.7.0~preview1
# + rb_enc_toupper@Base 2.7.0~preview1
# + rb_enc_uint_chr@Base 2.7.0~preview1
# + rb_enc_unicode_p@Base 2.7.0~preview1
# + rb_enc_vsprintf@Base 2.7.0~preview1
# + rb_encdb_alias@Base 2.7.0~preview1
# + rb_encdb_declare@Base 2.7.0~preview1
# + rb_encdb_dummy@Base 2.7.0~preview1
# + rb_encdb_replicate@Base 2.7.0~preview1
# + rb_encdb_set_unicode@Base 2.7.0~preview1
# + rb_ensure@Base 2.7.0~preview1
# + rb_enum_values_pack@Base 2.7.0~preview1
# + rb_enumeratorize@Base 2.7.0~preview1
# + rb_enumeratorize_with_size@Base 2.7.0~preview1
# + rb_enumeratorize_with_size_kw@Base 2.7.0~preview2
# + rb_env_clear@Base 2.7.0~preview1
# + rb_env_path_tainted@Base 2.7.0~preview1
# + rb_eof_error@Base 2.7.0~preview1
# + rb_eql@Base 2.7.0~preview1
# + rb_equal@Base 2.7.0~preview1
# + rb_errinfo@Base 2.7.0~preview1
# + rb_error_arity@Base 2.7.0~preview1
# + rb_error_frozen@Base 2.7.0~preview1
# + rb_error_frozen_object@Base 2.7.0~preview1
# + rb_error_untrusted@Base 2.7.0~preview1
# + rb_eval_cmd@Base 2.7.0~preview1
# + rb_eval_cmd_kw@Base 2.7.0
# + rb_eval_string@Base 2.7.0~preview1
# + rb_eval_string_protect@Base 2.7.0~preview1
# + rb_eval_string_wrap@Base 2.7.0~preview1
# + rb_exc_fatal@Base 2.7.0~preview1
# + rb_exc_new@Base 2.7.0~preview1
# + rb_exc_new_cstr@Base 2.7.0~preview1
# + rb_exc_new_str@Base 2.7.0~preview1
# + rb_exc_raise@Base 2.7.0~preview1
# + rb_exc_set_backtrace@Base 2.7.0~preview2
# + rb_exec_async_signal_safe@Base 2.7.0~preview1
# + rb_exec_event_hooks@Base 2.7.0~preview2
# + rb_exec_recursive@Base 2.7.0~preview1
# + rb_exec_recursive_outer@Base 2.7.0~preview1
# + rb_exec_recursive_paired@Base 2.7.0~preview1
# + rb_exec_recursive_paired_outer@Base 2.7.0~preview1
# + rb_execarg_addopt@Base 2.7.0~preview1
# + rb_execarg_extract_options@Base 2.7.0~preview1
# + rb_execarg_get@Base 2.7.0~preview1
# + rb_execarg_new@Base 2.7.0~preview1
# + rb_execarg_parent_end@Base 2.7.0~preview1
# + rb_execarg_parent_start@Base 2.7.0~preview1
# + rb_execarg_run_options@Base 2.7.0~preview1
# + rb_execarg_setenv@Base 2.7.0~preview1
# + rb_exit@Base 2.7.0~preview1
# + rb_extend_object@Base 2.7.0~preview1
# + rb_external_str_new@Base 2.7.0~preview1
# + rb_external_str_new_cstr@Base 2.7.0~preview1
# + rb_external_str_new_with_enc@Base 2.7.0~preview1
# + rb_extract_keywords@Base 2.7.0~preview1
# + rb_f_abort@Base 2.7.0~preview1
# + rb_f_exec@Base 2.7.0~preview1
# + rb_f_exit@Base 2.7.0~preview1
# + rb_f_global_variables@Base 2.7.0~preview1
# + rb_f_kill@Base 2.7.0~preview1
# + rb_f_notimplement@Base 2.7.0~preview1
# + rb_f_require@Base 2.7.0~preview1
# + rb_f_sprintf@Base 2.7.0~preview1
# + rb_f_trace_var@Base 2.7.0~preview1
# + rb_f_untrace_var@Base 2.7.0~preview1
# + rb_false@Base 2.7.0~preview2
# + rb_fatal@Base 2.7.0~preview1
# + rb_fd_clr@Base 2.7.0~preview1
# + rb_fd_copy@Base 2.7.0~preview1
# + rb_fd_dup@Base 2.7.0~preview1
# + rb_fd_fix_cloexec@Base 2.7.0~preview1
# + rb_fd_init@Base 2.7.0~preview1
# + rb_fd_isset@Base 2.7.0~preview1
# + rb_fd_select@Base 2.7.0~preview1
# + rb_fd_set@Base 2.7.0~preview1
# + rb_fd_term@Base 2.7.0~preview1
# + rb_fd_zero@Base 2.7.0~preview1
# + rb_fdopen@Base 2.7.0~preview1
# + rb_feature_provided@Base 2.7.0~preview1
# + rb_fiber_alive_p@Base 2.7.0~preview1
# + rb_fiber_current@Base 2.7.0~preview1
# + rb_fiber_new@Base 2.7.0~preview1
# + rb_fiber_resume@Base 2.7.0~preview1
# + rb_fiber_resume_kw@Base 2.7.0~preview2
# + rb_fiber_yield@Base 2.7.0~preview1
# + rb_fiber_yield_kw@Base 2.7.0~preview2
# + rb_file_absolute_path@Base 2.7.0~preview1
# + rb_file_directory_p@Base 2.7.0~preview1
# + rb_file_dirname@Base 2.7.0~preview1
# + rb_file_expand_path@Base 2.7.0~preview1
# + rb_file_open@Base 2.7.0~preview1
# + rb_file_open_str@Base 2.7.0~preview1
# + rb_file_s_absolute_path@Base 2.7.0~preview1
# + rb_file_s_birthtime@Base 2.7.0~preview2
# + rb_file_s_expand_path@Base 2.7.0~preview1
# + rb_filesystem_encindex@Base 2.7.0~preview1
# + rb_filesystem_encoding@Base 2.7.0~preview1
# + rb_filesystem_str_new@Base 2.7.0~preview1
# + rb_filesystem_str_new_cstr@Base 2.7.0~preview1
# + rb_find_encoding@Base 2.7.0~preview1
# + rb_find_file@Base 2.7.0~preview1
# + rb_find_file_ext@Base 2.7.0~preview1
# + rb_find_file_ext_safe@Base 2.7.0~preview1
# + rb_find_file_safe@Base 2.7.0~preview1
# + (optional)rb_fix2int@Base 2.7.0
# + rb_fix2short@Base 2.7.0~preview1
# + rb_fix2str@Base 2.7.0~preview1
# + (optional)rb_fix2uint@Base 2.7.0
# + rb_fix2ushort@Base 2.7.0~preview1
# + rb_fix_aref@Base 2.7.0~preview2
# + rb_flo_div_flo@Base 2.7.0~preview2
# + rb_float_cmp@Base 2.7.0~preview2
# + rb_float_eql@Base 2.7.0~preview2
# + rb_float_equal@Base 2.7.0~preview2
# + rb_float_new@Base 2.7.0~preview1
# + rb_float_new_in_heap@Base 2.7.0~preview1
# + rb_float_value@Base 2.7.0~preview1
# + rb_flt_rationalize@Base 2.7.0~preview1
# + rb_flt_rationalize_with_prec@Base 2.7.0~preview1
# + rb_fork_async_signal_safe@Base 2.7.0~preview1
# + rb_frame_callee@Base 2.7.0~preview1
# + rb_frame_method_id_and_class@Base 2.7.0~preview2
# + rb_frame_this_func@Base 2.7.0~preview1
# + rb_free_generic_ivar@Base 2.7.0~preview1
# + rb_free_tmp_buffer@Base 2.7.0~preview1
# + rb_freeze_singleton_class@Base 2.7.0~preview1
# + rb_frozen_error_raise@Base 2.7.0~preview2
# + rb_fs@Base 2.7.0~preview1
# + rb_fstring@Base 2.7.0~preview1
# + rb_fstring_new@Base 2.7.0~preview2
# + rb_func_proc_new@Base 2.7.0~preview2
# + rb_funcall@Base 2.7.0~preview1
# + rb_funcall_passing_block@Base 2.7.0~preview1
# + rb_funcall_passing_block_kw@Base 2.7.0~preview2
# + rb_funcall_with_block@Base 2.7.0~preview1
# + rb_funcall_with_block_kw@Base 2.7.0~preview2
# + rb_funcallv@Base 2.7.0~preview1
# + rb_funcallv_kw@Base 2.7.0~preview2
# + rb_funcallv_public@Base 2.7.0~preview1
# + rb_funcallv_public_kw@Base 2.7.0~preview2
# + rb_funcallv_with_cc@Base 2.7.0~preview2
# + rb_gc@Base 2.7.0~preview1
# + rb_gc_adjust_memory_usage@Base 2.7.0~preview1
# + rb_gc_copy_finalizer@Base 2.7.0~preview1
# + rb_gc_count@Base 2.7.0~preview1
# + rb_gc_disable@Base 2.7.0~preview1
# + rb_gc_enable@Base 2.7.0~preview1
# + rb_gc_for_fd@Base 2.7.0~preview1
# + rb_gc_force_recycle@Base 2.7.0~preview1
# + rb_gc_latest_gc_info@Base 2.7.0~preview1
# + rb_gc_location@Base 2.7.0~preview2
# + rb_gc_mark@Base 2.7.0~preview1
# + rb_gc_mark_locations@Base 2.7.0~preview1
# + rb_gc_mark_maybe@Base 2.7.0~preview1
# + rb_gc_mark_movable@Base 2.7.0~preview2
# + rb_gc_mark_values@Base 2.7.0~preview1
# + rb_gc_mark_vm_stack_values@Base 2.7.0~preview2
# + rb_gc_register_address@Base 2.7.0~preview1
# + rb_gc_register_mark_object@Base 2.7.0~preview1
# + rb_gc_start@Base 2.7.0~preview1
# + rb_gc_stat@Base 2.7.0~preview1
# + rb_gc_unregister_address@Base 2.7.0~preview1
# + rb_gc_update_tbl_refs@Base 2.7.0~preview2
# + rb_gc_verify_internal_consistency@Base 2.7.0~preview1
# + rb_gc_writebarrier@Base 2.7.0~preview1
# + rb_gc_writebarrier_remember@Base 2.7.0~preview2
# + rb_gc_writebarrier_unprotect@Base 2.7.0~preview1
# + rb_gcd@Base 2.7.0~preview1
# + rb_gcd_gmp@Base 2.7.0~preview1
# + rb_gcd_normal@Base 2.7.0~preview1
# + rb_generic_ivar_memsize@Base 2.7.0~preview1
# + rb_genrand_int32@Base 2.7.0~preview1
# + rb_genrand_real@Base 2.7.0~preview1
# + rb_genrand_ulong_limited@Base 2.7.0~preview1
# + rb_get_alloc_func@Base 2.7.0~preview1
# + rb_get_argv@Base 2.7.0~preview1
# + rb_get_coverages@Base 2.7.0~preview1
# + rb_get_kwargs@Base 2.7.0~preview1
# + rb_get_path@Base 2.7.0~preview1
# + rb_get_path_no_checksafe@Base 2.7.0~preview1
# + rb_get_values_at@Base 2.7.0~preview1
# + rb_gets@Base 2.7.0~preview1
# + rb_glob@Base 2.7.0~preview1
# + rb_global_entry@Base 2.7.0~preview2
# + rb_global_variable@Base 2.7.0~preview1
# + rb_grantpt@Base 2.7.0~preview2
# + rb_gv_get@Base 2.7.0~preview1
# + rb_gv_set@Base 2.7.0~preview1
# + rb_gvar_defined@Base 2.7.0~preview2
# + rb_gvar_get@Base 2.7.0~preview2
# + rb_gvar_readonly_setter@Base 2.7.0~preview1
# + rb_gvar_set@Base 2.7.0~preview2
# + rb_gvar_undef_getter@Base 2.7.0~preview1
# + rb_gvar_undef_marker@Base 2.7.0~preview1
# + rb_gvar_undef_setter@Base 2.7.0~preview1
# + rb_gvar_val_getter@Base 2.7.0~preview1
# + rb_gvar_val_marker@Base 2.7.0~preview1
# + rb_gvar_val_setter@Base 2.7.0~preview1
# + rb_gvar_var_getter@Base 2.7.0~preview1
# + rb_gvar_var_marker@Base 2.7.0~preview1
# + rb_gvar_var_setter@Base 2.7.0~preview1
# + rb_hash@Base 2.7.0~preview1
# + rb_hash_aref@Base 2.7.0~preview1
# + rb_hash_aset@Base 2.7.0~preview1
# + rb_hash_bulk_insert@Base 2.7.0~preview2
# + rb_hash_bulk_insert_into_st_table@Base 2.7.0~preview2
# + rb_hash_clear@Base 2.7.0~preview1
# + rb_hash_compare_by_id_p@Base 2.7.0~preview2
# + rb_hash_delete@Base 2.7.0~preview1
# + rb_hash_delete_entry@Base 2.7.0~preview1
# + rb_hash_delete_if@Base 2.7.0~preview1
# + rb_hash_dup@Base 2.7.0~preview1
# + rb_hash_fetch@Base 2.7.0~preview1
# + rb_hash_foreach@Base 2.7.0~preview1
# + rb_hash_freeze@Base 2.7.0~preview1
# + rb_hash_has_key@Base 2.7.0~preview2
# + rb_hash_keys@Base 2.7.0~preview2
# + rb_hash_lookup2@Base 2.7.0~preview1
# + rb_hash_lookup@Base 2.7.0~preview1
# + rb_hash_new@Base 2.7.0~preview1
# + rb_hash_new_with_size@Base 2.7.0~preview2
# + rb_hash_resurrect@Base 2.7.0~preview2
# + rb_hash_set_ifnone@Base 2.7.0~preview1
# + rb_hash_size@Base 2.7.0~preview1
# + rb_hash_size_num@Base 2.7.0~preview2
# + rb_hash_start@Base 2.7.0~preview1
# + rb_hash_stlike_foreach@Base 2.7.0~preview2
# + rb_hash_stlike_lookup@Base 2.7.0~preview2
# + rb_hash_tbl@Base 2.7.0~preview1
# + rb_hash_tbl_raw@Base 2.7.0~preview2
# + rb_hash_update_by@Base 2.7.0~preview1
# + rb_id2name@Base 2.7.0~preview1
# + rb_id2str@Base 2.7.0~preview1
# + rb_id2sym@Base 2.7.0~preview1
# + rb_id_attrset@Base 2.7.0~preview1
# + rb_id_quote_unprintable@Base 2.7.0~preview2
# + rb_ident_hash_new@Base 2.7.0~preview1
# + rb_imemo_new@Base 2.7.0~preview1
# + rb_include_module@Base 2.7.0~preview1
# + rb_insecure_operation@Base 2.7.0~preview1
# + rb_inspect@Base 2.7.0~preview1
# + (optional)rb_int128t2big@Base 2.7.0
# + rb_int2big@Base 2.7.0~preview1
# + rb_int2inum@Base 2.7.0~preview1
# + rb_int_parse_cstr@Base 2.7.0~preview1
# + rb_int_positive_pow@Base 2.7.0~preview1
# + rb_integer_pack@Base 2.7.0~preview1
# + rb_integer_unpack@Base 2.7.0~preview1
# + rb_intern2@Base 2.7.0~preview1
# + rb_intern3@Base 2.7.0~preview1
# + rb_intern@Base 2.7.0~preview1
# + rb_intern_str@Base 2.7.0~preview1
# + rb_interrupt@Base 2.7.0~preview1
# + rb_invalid_str@Base 2.7.0~preview1
# + rb_io_addstr@Base 2.7.0~preview1
# + rb_io_ascii8bit_binmode@Base 2.7.0~preview1
# + rb_io_binmode@Base 2.7.0~preview1
# + rb_io_bufwrite@Base 2.7.0~preview1
# + rb_io_check_byte_readable@Base 2.7.0~preview1
# + rb_io_check_char_readable@Base 2.7.0~preview1
# + rb_io_check_closed@Base 2.7.0~preview1
# + rb_io_check_initialized@Base 2.7.0~preview1
# + rb_io_check_io@Base 2.7.0~preview1
# + rb_io_check_readable@Base 2.7.0~preview1
# + rb_io_check_writable@Base 2.7.0~preview1
# + rb_io_close@Base 2.7.0~preview1
# + rb_io_eof@Base 2.7.0~preview1
# + rb_io_extract_encoding_option@Base 2.7.0~preview1
# + rb_io_extract_modeenc@Base 2.7.0~preview2
# + rb_io_fdopen@Base 2.7.0~preview1
# + rb_io_flush@Base 2.7.0~preview1
# + rb_io_fptr_finalize@Base 2.7.0~preview1
# + rb_io_get_io@Base 2.7.0~preview1
# + rb_io_get_write_io@Base 2.7.0~preview1
# + rb_io_getbyte@Base 2.7.0~preview1
# + rb_io_gets@Base 2.7.0~preview1
# + rb_io_make_open_file@Base 2.7.0~preview1
# + rb_io_memsize@Base 2.7.0~preview1
# + rb_io_modestr_fmode@Base 2.7.0~preview1
# + rb_io_modestr_oflags@Base 2.7.0~preview1
# + rb_io_oflags_fmode@Base 2.7.0~preview1
# + rb_io_print@Base 2.7.0~preview1
# + rb_io_printf@Base 2.7.0~preview1
# + rb_io_puts@Base 2.7.0~preview1
# + rb_io_read_check@Base 2.7.0~preview1
# + rb_io_read_pending@Base 2.7.0~preview1
# + rb_io_set_nonblock@Base 2.7.0~preview1
# + rb_io_set_write_io@Base 2.7.0~preview1
# + rb_io_stdio_file@Base 2.7.0~preview1
# + rb_io_synchronized@Base 2.7.0~preview1
# + rb_io_taint_check@Base 2.7.0~preview1
# + rb_io_ungetbyte@Base 2.7.0~preview1
# + rb_io_ungetc@Base 2.7.0~preview1
# + rb_io_wait_readable@Base 2.7.0~preview1
# + rb_io_wait_writable@Base 2.7.0~preview1
# + rb_io_write@Base 2.7.0~preview1
# + rb_is_absolute_path@Base 2.7.0~preview1
# + rb_is_attrset_id@Base 2.7.0~preview1
# + rb_is_class_id@Base 2.7.0~preview1
# + rb_is_const_id@Base 2.7.0~preview1
# + rb_is_global_id@Base 2.7.0~preview1
# + rb_is_instance_id@Base 2.7.0~preview1
# + rb_is_junk_id@Base 2.7.0~preview1
# + rb_is_local_id@Base 2.7.0~preview1
# + rb_iseq_absolute_path@Base 2.7.0~preview1
# + rb_iseq_base_label@Base 2.7.0~preview1
# + rb_iseq_build_from_ary@Base 2.7.0~preview1
# + rb_iseq_code_location@Base 2.7.0~preview2
# + rb_iseq_compile_callback@Base 2.7.0~preview2
# + rb_iseq_compile_node@Base 2.7.0~preview1
# + rb_iseq_constant_body_alloc@Base 2.7.0
# + rb_iseq_coverage@Base 2.7.0~preview1
# + rb_iseq_defined_string@Base 2.7.0~preview1
# + rb_iseq_disasm@Base 2.7.0~preview1
# + rb_iseq_disasm_insn@Base 2.7.0~preview1
# + rb_iseq_eval@Base 2.7.0~preview1
# + rb_iseq_eval_main@Base 2.7.0~preview1
# + rb_iseq_event_flags@Base 2.7.0~preview2
# + rb_iseq_first_lineno@Base 2.7.0~preview1
# + rb_iseq_insns_info_encode_positions@Base 2.7.0~preview2
# + rb_iseq_label@Base 2.7.0~preview1
# + rb_iseq_line_no@Base 2.7.0~preview1
# + rb_iseq_load@Base 2.7.0~preview1
# + rb_iseq_local_variables@Base 2.7.0~preview1
# + rb_iseq_location@Base 2.7.0~preview2
# + rb_iseq_mark_insn_storage@Base 2.7.0~preview2
# + rb_iseq_method_name@Base 2.7.0~preview1
# + rb_iseq_new@Base 2.7.0~preview1
# + rb_iseq_new_main@Base 2.7.0~preview1
# + rb_iseq_new_top@Base 2.7.0~preview1
# + rb_iseq_new_with_callback@Base 2.7.0~preview2
# + rb_iseq_new_with_opt@Base 2.7.0~preview1
# + rb_iseq_original_iseq@Base 2.7.0~preview1
# + rb_iseq_parameters@Base 2.7.0~preview1
# + rb_iseq_path@Base 2.7.0~preview1
# + rb_iseq_realpath@Base 2.7.0~preview1
# + rb_iseq_remove_coverage_all@Base 2.7.0~preview2
# + rb_iseq_trace_set@Base 2.7.0~preview2
# + rb_iseq_trace_set_all@Base 2.7.0~preview2
# + rb_iseqw_new@Base 2.7.0~preview1
# + rb_iseqw_to_iseq@Base 2.7.0~preview1
# + rb_iter_break@Base 2.7.0~preview1
# + rb_iter_break_value@Base 2.7.0~preview1
# + rb_iterate@Base 2.7.0~preview1
# + rb_iv_get@Base 2.7.0~preview1
# + rb_iv_set@Base 2.7.0~preview1
# + rb_iv_tbl_copy@Base 2.7.0~preview2
# + rb_ivar_count@Base 2.7.0~preview1
# + rb_ivar_defined@Base 2.7.0~preview1
# + rb_ivar_foreach@Base 2.7.0~preview1
# + rb_ivar_generic_ivtbl@Base 2.7.0
# + rb_ivar_get@Base 2.7.0~preview1
# + rb_ivar_set@Base 2.7.0~preview1
# + rb_jump_tag@Base 2.7.0~preview1
# + rb_keyword_error_new@Base 2.7.0~preview2
# + rb_keyword_given_p@Base 2.7.0~preview2
# + rb_last_status_get@Base 2.7.0~preview1
# + rb_last_status_set@Base 2.7.0~preview1
# + rb_lastline_get@Base 2.7.0~preview1
# + rb_lastline_set@Base 2.7.0~preview1
# + rb_ll2inum@Base 2.7.0~preview1
# + rb_load@Base 2.7.0~preview1
# + rb_load_file@Base 2.7.0~preview1
# + rb_load_file_str@Base 2.7.0~preview1
# + rb_load_protect@Base 2.7.0~preview1
# + rb_loaderror@Base 2.7.0~preview1
# + rb_loaderror_with_path@Base 2.7.0~preview1
# + rb_locale_charmap@Base 2.7.0~preview1
# + rb_locale_encindex@Base 2.7.0~preview1
# + rb_locale_encoding@Base 2.7.0~preview1
# + rb_locale_str_new@Base 2.7.0~preview1
# + rb_locale_str_new_cstr@Base 2.7.0~preview1
# + rb_mComparable@Base 2.7.0~preview1
# + rb_mEnumerable@Base 2.7.0~preview1
# + rb_mErrno@Base 2.7.0~preview1
# + rb_mFileTest@Base 2.7.0~preview1
# + rb_mGC@Base 2.7.0~preview1
# + rb_mKernel@Base 2.7.0~preview1
# + rb_mMath@Base 2.7.0~preview1
# + rb_mProcess@Base 2.7.0~preview1
# + rb_mRubyVMFrozenCore@Base 2.7.0~preview1
# + rb_mWaitReadable@Base 2.7.0~preview1
# + rb_mWaitWritable@Base 2.7.0~preview1
# + rb_make_backtrace@Base 2.7.0~preview1
# + rb_make_exception@Base 2.7.0~preview1
# + rb_make_no_method_exception@Base 2.7.0~preview2
# + rb_mark_generic_ivar@Base 2.7.0~preview1
# + rb_mark_hash@Base 2.7.0~preview1
# + rb_mark_set@Base 2.7.0~preview1
# + rb_mark_tbl@Base 2.7.0~preview1
# + rb_mark_tbl_no_pin@Base 2.7.0~preview2
# + rb_marshal_define_compat@Base 2.7.0~preview1
# + rb_marshal_dump@Base 2.7.0~preview1
# + rb_marshal_load@Base 2.7.0~preview1
# + rb_match_busy@Base 2.7.0~preview1
# + rb_maygvl_fd_fix_cloexec@Base 2.7.0~preview1
# + rb_mem_clear@Base 2.7.0~preview1
# + rb_memcicmp@Base 2.7.0~preview1
# + rb_memerror@Base 2.7.0~preview1
# + rb_memhash@Base 2.7.0~preview1
# + rb_memory_id@Base 2.7.0~preview2
# + rb_memsearch@Base 2.7.0~preview1
# + rb_method_basic_definition_p@Base 2.7.0~preview1
# + rb_method_basic_definition_p_with_cc@Base 2.7.0
# + rb_method_boundp@Base 2.7.0~preview1
# + rb_method_call@Base 2.7.0~preview1
# + rb_method_call_kw@Base 2.7.0~preview2
# + rb_method_call_with_block@Base 2.7.0~preview1
# + rb_method_call_with_block_kw@Base 2.7.0~preview2
# + rb_method_definition_create@Base 2.7.0~preview2
# + rb_method_definition_eq@Base 2.7.0~preview2
# + rb_method_definition_set@Base 2.7.0~preview2
# + rb_method_entry@Base 2.7.0~preview2
# + rb_method_entry_complement_defined_class@Base 2.7.0~preview2
# + rb_method_iseq@Base 2.7.0~preview1
# + rb_mjit_add_iseq_to_process@Base 2.7.0~preview2
# + rb_mjit_iseq_compile_info@Base 2.7.0~preview2
# + rb_mjit_recompile_iseq@Base 2.7.0~preview2
# + rb_mjit_wait_call@Base 2.7.0~preview2
# + rb_mod_ancestors@Base 2.7.0~preview1
# + rb_mod_class_variables@Base 2.7.0~preview1
# + rb_mod_const_at@Base 2.7.0~preview1
# + rb_mod_const_of@Base 2.7.0~preview1
# + rb_mod_constants@Base 2.7.0~preview1
# + rb_mod_include_p@Base 2.7.0~preview1
# + rb_mod_included_modules@Base 2.7.0~preview1
# + rb_mod_init_copy@Base 2.7.0~preview1
# + rb_mod_method_arity@Base 2.7.0~preview1
# + rb_mod_module_eval@Base 2.7.0~preview1
# + rb_mod_module_exec@Base 2.7.0~preview1
# + rb_mod_name@Base 2.7.0~preview1
# + rb_mod_remove_const@Base 2.7.0~preview1
# + rb_mod_remove_cvar@Base 2.7.0~preview1
# + rb_mod_sys_fail@Base 2.7.0~preview1
# + rb_mod_sys_fail_str@Base 2.7.0~preview1
# + rb_mod_syserr_fail@Base 2.7.0~preview1
# + rb_mod_syserr_fail_str@Base 2.7.0~preview1
# + rb_module_new@Base 2.7.0~preview1
# + rb_must_asciicompat@Base 2.7.0~preview1
# + rb_mutex_lock@Base 2.7.0~preview1
# + rb_mutex_locked_p@Base 2.7.0~preview1
# + rb_mutex_new@Base 2.7.0~preview1
# + rb_mutex_sleep@Base 2.7.0~preview1
# + rb_mutex_synchronize@Base 2.7.0~preview1
# + rb_mutex_trylock@Base 2.7.0~preview1
# + rb_mutex_unlock@Base 2.7.0~preview1
# + rb_mv_generic_ivar@Base 2.7.0~preview2
# + rb_name_error@Base 2.7.0~preview1
# + rb_name_error_str@Base 2.7.0~preview1
# + rb_nativethread_lock_destroy@Base 2.7.0~preview1
# + rb_nativethread_lock_initialize@Base 2.7.0~preview1
# + rb_nativethread_lock_lock@Base 2.7.0~preview1
# + rb_nativethread_lock_unlock@Base 2.7.0~preview1
# + rb_nativethread_self@Base 2.7.0~preview1
# + rb_need_block@Base 2.7.0~preview1
# + rb_newobj@Base 2.7.0~preview1
# + rb_newobj_of@Base 2.7.0~preview1
# + rb_node_init@Base 2.7.0~preview2
# + rb_nogvl@Base 2.7.0~preview2
# + rb_notimplement@Base 2.7.0~preview1
# + rb_num2dbl@Base 2.7.0~preview1
# + rb_num2fix@Base 2.7.0~preview1
# + (optional)rb_num2int@Base 2.7.0
# + rb_num2ll@Base 2.7.0~preview1
# + rb_num2long@Base 2.7.0~preview1
# + rb_num2short@Base 2.7.0~preview1
# + (optional)rb_num2uint@Base 2.7.0
# + rb_num2ull@Base 2.7.0~preview1
# + rb_num2ulong@Base 2.7.0~preview1
# + rb_num2ushort@Base 2.7.0~preview1
# + rb_num_coerce_bin@Base 2.7.0~preview1
# + rb_num_coerce_bit@Base 2.7.0~preview1
# + rb_num_coerce_cmp@Base 2.7.0~preview1
# + rb_num_coerce_relop@Base 2.7.0~preview1
# + rb_num_zerodiv@Base 2.7.0~preview1
# + rb_obj_alloc@Base 2.7.0~preview1
# + rb_obj_as_string@Base 2.7.0~preview1
# + rb_obj_as_string_result@Base 2.7.0~preview2
# + rb_obj_call_init@Base 2.7.0~preview1
# + rb_obj_call_init_kw@Base 2.7.0~preview2
# + rb_obj_class@Base 2.7.0~preview1
# + rb_obj_classname@Base 2.7.0~preview1
# + rb_obj_clone@Base 2.7.0~preview1
# + rb_obj_copy_ivar@Base 2.7.0~preview2
# + rb_obj_dup@Base 2.7.0~preview1
# + rb_obj_encoding@Base 2.7.0~preview1
# + rb_obj_equal@Base 2.7.0~preview2
# + rb_obj_freeze@Base 2.7.0~preview1
# + rb_obj_frozen_p@Base 2.7.0~preview1
# + rb_obj_gc_flags@Base 2.7.0~preview1
# + rb_obj_hide@Base 2.7.0~preview1
# + rb_obj_id@Base 2.7.0~preview1
# + rb_obj_infect@Base 2.7.0~preview1
# + rb_obj_info@Base 2.7.0~preview2
# + rb_obj_init_copy@Base 2.7.0~preview1
# + rb_obj_instance_eval@Base 2.7.0~preview1
# + rb_obj_instance_exec@Base 2.7.0~preview1
# + rb_obj_instance_variables@Base 2.7.0~preview1
# + rb_obj_is_instance_of@Base 2.7.0~preview1
# + rb_obj_is_kind_of@Base 2.7.0~preview1
# + rb_obj_is_method@Base 2.7.0~preview1
# + rb_obj_is_proc@Base 2.7.0~preview1
# + rb_obj_memsize_of@Base 2.7.0~preview1
# + rb_obj_method@Base 2.7.0~preview1
# + rb_obj_method_arity@Base 2.7.0~preview1
# + rb_obj_not@Base 2.7.0~preview2
# + rb_obj_not_equal@Base 2.7.0~preview2
# + rb_obj_remove_instance_variable@Base 2.7.0~preview1
# + rb_obj_respond_to@Base 2.7.0~preview1
# + rb_obj_reveal@Base 2.7.0~preview1
# + rb_obj_setup@Base 2.7.0~preview1
# + rb_obj_singleton_methods@Base 2.7.0~preview1
# + rb_obj_taint@Base 2.7.0~preview1
# + rb_obj_tainted@Base 2.7.0~preview1
# + rb_obj_trust@Base 2.7.0~preview1
# + rb_obj_untaint@Base 2.7.0~preview1
# + rb_obj_untrust@Base 2.7.0~preview1
# + rb_obj_untrusted@Base 2.7.0~preview1
# + rb_objspace_data_type_memsize@Base 2.7.0~preview1
# + rb_objspace_data_type_name@Base 2.7.0~preview1
# + rb_objspace_each_objects@Base 2.7.0~preview1
# + rb_objspace_each_objects_without_setup@Base 2.7.0~preview1
# + rb_objspace_garbage_object_p@Base 2.7.0~preview1
# + rb_objspace_internal_object_p@Base 2.7.0~preview1
# + rb_objspace_markable_object_p@Base 2.7.0~preview1
# + rb_objspace_marked_object_p@Base 2.7.0~preview1
# + rb_objspace_reachable_objects_from@Base 2.7.0~preview1
# + rb_objspace_reachable_objects_from_root@Base 2.7.0~preview1
# + rb_opts_exception_p@Base 2.7.0~preview2
# + (optional)rb_out_of_int@Base 2.7.0
# + rb_output_fs@Base 2.7.0~preview1
# + rb_output_rs@Base 2.7.0~preview1
# + rb_p@Base 2.7.0~preview1
# + rb_parser_calloc@Base 2.7.0~preview1
# + rb_parser_compile_file_path@Base 2.7.0~preview1
# + rb_parser_compile_generic@Base 2.7.0~preview2
# + rb_parser_compile_string@Base 2.7.0~preview1
# + rb_parser_compile_string_path@Base 2.7.0~preview1
# + rb_parser_dump_tree@Base 2.7.0~preview1
# + rb_parser_encoding@Base 2.7.0~preview1
# + rb_parser_end_seen_p@Base 2.7.0~preview1
# + rb_parser_fatal@Base 2.7.0~preview1
# + rb_parser_free@Base 2.7.0~preview1
# + rb_parser_lex_state_name@Base 2.7.0~preview1
# + rb_parser_malloc@Base 2.7.0~preview1
# + rb_parser_new@Base 2.7.0~preview1
# + rb_parser_printf@Base 2.7.0~preview1
# + rb_parser_realloc@Base 2.7.0~preview1
# + rb_parser_reg_compile@Base 2.7.0~preview1
# + rb_parser_set_context@Base 2.7.0~preview2
# + rb_parser_set_location@Base 2.7.0~preview2
# + rb_parser_set_location_from_strterm_heredoc@Base 2.7.0~preview2
# + rb_parser_set_location_of_none@Base 2.7.0~preview2
# + rb_parser_set_options@Base 2.7.0~preview2
# + rb_parser_set_yydebug@Base 2.7.0~preview1
# + rb_parser_show_bitstack@Base 2.7.0~preview1
# + rb_parser_trace_lex_state@Base 2.7.0~preview1
# + rb_path2class@Base 2.7.0~preview1
# + rb_path_check@Base 2.7.0~preview1
# + rb_path_to_class@Base 2.7.0~preview1
# + rb_pipe@Base 2.7.0~preview1
# + rb_postponed_job_flush@Base 2.7.0~preview1
# + rb_postponed_job_register@Base 2.7.0~preview1
# + rb_postponed_job_register_one@Base 2.7.0~preview1
# + rb_prepend_module@Base 2.7.0~preview1
# + rb_proc_arity@Base 2.7.0~preview1
# + rb_proc_call@Base 2.7.0~preview1
# + rb_proc_call_kw@Base 2.7.0~preview2
# + rb_proc_call_with_block@Base 2.7.0~preview1
# + rb_proc_call_with_block_kw@Base 2.7.0~preview2
# + rb_proc_exec@Base 2.7.0~preview1
# + rb_proc_get_iseq@Base 2.7.0~preview1
# + rb_proc_lambda_p@Base 2.7.0~preview1
# + rb_proc_new@Base 2.7.0~preview1
# + rb_proc_times@Base 2.7.0~preview1
# + rb_profile_frame_absolute_path@Base 2.7.0~preview1
# + rb_profile_frame_base_label@Base 2.7.0~preview1
# + rb_profile_frame_classpath@Base 2.7.0~preview1
# + rb_profile_frame_first_lineno@Base 2.7.0~preview1
# + rb_profile_frame_full_label@Base 2.7.0~preview1
# + rb_profile_frame_label@Base 2.7.0~preview1
# + rb_profile_frame_method_name@Base 2.7.0~preview1
# + rb_profile_frame_path@Base 2.7.0~preview1
# + rb_profile_frame_qualified_method_name@Base 2.7.0~preview1
# + rb_profile_frame_singleton_method_p@Base 2.7.0~preview1
# + rb_profile_frames@Base 2.7.0~preview1
# + rb_protect@Base 2.7.0~preview1
# + rb_provide@Base 2.7.0~preview1
# + rb_provided@Base 2.7.0~preview1
# + rb_public_const_defined_from@Base 2.7.0~preview2
# + rb_public_const_get_at@Base 2.7.0~preview2
# + rb_public_const_get_from@Base 2.7.0~preview2
# + rb_raise@Base 2.7.0~preview1
# + rb_random_bytes@Base 2.7.0~preview1
# + rb_random_int32@Base 2.7.0~preview1
# + rb_random_real@Base 2.7.0~preview1
# + rb_random_ulong_limited@Base 2.7.0~preview1
# + rb_range_beg_len@Base 2.7.0~preview1
# + rb_range_new@Base 2.7.0~preview1
# + rb_range_values@Base 2.7.0~preview1
# + rb_rational_den@Base 2.7.0~preview1
# + rb_rational_new@Base 2.7.0~preview1
# + rb_rational_num@Base 2.7.0~preview1
# + rb_rational_raw@Base 2.7.0~preview1
# + rb_readlink@Base 2.7.0~preview1
# + rb_readwrite_sys_fail@Base 2.7.0~preview1
# + rb_readwrite_syserr_fail@Base 2.7.0~preview1
# + rb_reg_adjust_startpos@Base 2.7.0~preview1
# + rb_reg_alloc@Base 2.7.0~preview1
# + rb_reg_backref_number@Base 2.7.0~preview1
# + rb_reg_fragment_setenc@Base 2.7.0~preview1
# + rb_reg_init_str@Base 2.7.0~preview1
# + rb_reg_last_match@Base 2.7.0~preview1
# + rb_reg_match2@Base 2.7.0~preview1
# + rb_reg_match@Base 2.7.0~preview1
# + rb_reg_match_last@Base 2.7.0~preview1
# + rb_reg_match_post@Base 2.7.0~preview1
# + rb_reg_match_pre@Base 2.7.0~preview1
# + rb_reg_new@Base 2.7.0~preview1
# + rb_reg_new_ary@Base 2.7.0~preview2
# + rb_reg_new_str@Base 2.7.0~preview1
# + rb_reg_nth_defined@Base 2.7.0~preview1
# + rb_reg_nth_match@Base 2.7.0~preview1
# + rb_reg_options@Base 2.7.0~preview1
# + rb_reg_prepare_re@Base 2.7.0~preview1
# + rb_reg_quote@Base 2.7.0~preview1
# + rb_reg_regcomp@Base 2.7.0~preview1
# + rb_reg_region_copy@Base 2.7.0~preview1
# + rb_reg_regsub@Base 2.7.0~preview1
# + rb_reg_search@Base 2.7.0~preview1
# + rb_register_transcoder@Base 2.7.0~preview1
# + rb_remove_event_hook@Base 2.7.0~preview1
# + rb_remove_event_hook_with_data@Base 2.7.0~preview1
# + rb_remove_method@Base 2.7.0~preview1
# + rb_remove_method_id@Base 2.7.0~preview1
# + rb_require@Base 2.7.0~preview1
# + rb_require_safe@Base 2.7.0~preview1
# + rb_require_string@Base 2.7.0
# + rb_rescue2@Base 2.7.0~preview1
# + rb_rescue@Base 2.7.0~preview1
# + rb_reserved_fd_p@Base 2.7.0~preview1
# + rb_reserved_word@Base 2.7.0~preview1
# + rb_reset_coverages@Base 2.7.0~preview1
# + rb_reset_random_seed@Base 2.7.0~preview1
# + rb_resolve_me_location@Base 2.7.0~preview2
# + rb_resolve_refined_method_callable@Base 2.7.0~preview2
# + rb_respond_to@Base 2.7.0~preview1
# + rb_rs@Base 2.7.0~preview1
# + rb_ruby_debug_ptr@Base 2.7.0~preview1
# + rb_ruby_verbose_ptr@Base 2.7.0~preview1
# + rb_safe_level@Base 2.7.0~preview1
# + rb_scan_args@Base 2.7.0~preview1
# + rb_scan_args_kw@Base 2.7.0~preview2
# + rb_secure@Base 2.7.0~preview1
# + rb_secure_update@Base 2.7.0~preview1
# + rb_set_class_path@Base 2.7.0~preview1
# + rb_set_class_path_string@Base 2.7.0~preview1
# + rb_set_coverages@Base 2.7.0~preview1
# + rb_set_end_proc@Base 2.7.0~preview1
# + rb_set_errinfo@Base 2.7.0~preview1
# + rb_set_safe_level@Base 2.7.0~preview1
# + rb_set_safe_level_force@Base 2.7.0~preview1
# + rb_setup_fake_str@Base 2.7.0~preview1
# + rb_singleton_class@Base 2.7.0~preview1
# + rb_singleton_class_attached@Base 2.7.0~preview1
# + rb_singleton_class_clone@Base 2.7.0~preview1
# + rb_source_location_cstr@Base 2.7.0~preview2
# + rb_sourcefile@Base 2.7.0~preview1
# + rb_sourceline@Base 2.7.0~preview1
# + rb_spawn@Base 2.7.0~preview1
# + rb_spawn_err@Base 2.7.0~preview1
# + rb_sprintf@Base 2.7.0~preview1
# + rb_st_add_direct@Base 2.7.0~preview2
# + rb_st_cleanup_safe@Base 2.7.0~preview2
# + rb_st_clear@Base 2.7.0~preview2
# + rb_st_copy@Base 2.7.0~preview1
# + rb_st_delete@Base 2.7.0~preview2
# + rb_st_delete_safe@Base 2.7.0~preview2
# + rb_st_foreach@Base 2.7.0~preview2
# + rb_st_foreach_check@Base 2.7.0~preview2
# + rb_st_foreach_safe@Base 2.7.0~preview2
# + rb_st_foreach_with_replace@Base 2.7.0~preview2
# + rb_st_free_table@Base 2.7.0~preview2
# + rb_st_get_key@Base 2.7.0~preview2
# + rb_st_hash@Base 2.7.0~preview2
# + rb_st_hash_end@Base 2.7.0~preview2
# + rb_st_hash_start@Base 2.7.0~preview2
# + rb_st_hash_uint32@Base 2.7.0~preview2
# + rb_st_hash_uint@Base 2.7.0~preview2
# + rb_st_init_numtable@Base 2.7.0~preview2
# + rb_st_init_numtable_with_size@Base 2.7.0~preview2
# + rb_st_init_strcasetable@Base 2.7.0~preview2
# + rb_st_init_strcasetable_with_size@Base 2.7.0~preview2
# + rb_st_init_strtable@Base 2.7.0~preview2
# + rb_st_init_strtable_with_size@Base 2.7.0~preview2
# + rb_st_init_table@Base 2.7.0~preview2
# + rb_st_init_table_with_size@Base 2.7.0~preview2
# + rb_st_insert2@Base 2.7.0~preview2
# + rb_st_insert@Base 2.7.0~preview2
# + rb_st_keys@Base 2.7.0~preview2
# + rb_st_keys_check@Base 2.7.0~preview2
# + rb_st_locale_insensitive_strcasecmp@Base 2.7.0~preview2
# + rb_st_locale_insensitive_strncasecmp@Base 2.7.0~preview2
# + rb_st_lookup@Base 2.7.0~preview2
# + rb_st_memsize@Base 2.7.0~preview2
# + rb_st_numcmp@Base 2.7.0~preview2
# + rb_st_numhash@Base 2.7.0~preview2
# + rb_st_shift@Base 2.7.0~preview2
# + rb_st_update@Base 2.7.0~preview2
# + rb_st_values@Base 2.7.0~preview2
# + rb_st_values_check@Base 2.7.0~preview2
# + rb_stat_new@Base 2.7.0~preview1
# + rb_stderr@Base 2.7.0~preview1
# + rb_stdin@Base 2.7.0~preview1
# + rb_stdout@Base 2.7.0~preview1
# + rb_str2big_gmp@Base 2.7.0~preview1
# + rb_str2big_karatsuba@Base 2.7.0~preview1
# + rb_str2big_normal@Base 2.7.0~preview1
# + rb_str2big_poweroftwo@Base 2.7.0~preview1
# + rb_str2inum@Base 2.7.0~preview1
# + rb_str_append@Base 2.7.0~preview1
# + rb_str_buf_append@Base 2.7.0~preview1
# + rb_str_buf_cat2@Base 2.7.0~preview1
# + rb_str_buf_cat@Base 2.7.0~preview1
# + rb_str_buf_cat_ascii@Base 2.7.0~preview1
# + rb_str_buf_new@Base 2.7.0~preview1
# + rb_str_buf_new_cstr@Base 2.7.0~preview1
# + rb_str_capacity@Base 2.7.0~preview1
# + rb_str_cat2@Base 2.7.0~preview1
# + rb_str_cat@Base 2.7.0~preview1
# + rb_str_cat_cstr@Base 2.7.0~preview1
# + rb_str_catf@Base 2.7.0~preview1
# + rb_str_cmp@Base 2.7.0~preview1
# + rb_str_coderange_scan_restartable@Base 2.7.0~preview1
# + rb_str_comparable@Base 2.7.0~preview1
# + rb_str_concat@Base 2.7.0~preview1
# + rb_str_concat_literals@Base 2.7.0~preview2
# + rb_str_conv_enc@Base 2.7.0~preview1
# + rb_str_conv_enc_opts@Base 2.7.0~preview1
# + rb_str_drop_bytes@Base 2.7.0~preview1
# + rb_str_dump@Base 2.7.0~preview1
# + rb_str_dup@Base 2.7.0~preview1
# + rb_str_dup_frozen@Base 2.7.0~preview1
# + rb_str_ellipsize@Base 2.7.0~preview1
# + rb_str_encode@Base 2.7.0~preview1
# + rb_str_encode_ospath@Base 2.7.0~preview1
# + rb_str_eql@Base 2.7.0~preview2
# + rb_str_equal@Base 2.7.0~preview1
# + rb_str_export@Base 2.7.0~preview1
# + rb_str_export_locale@Base 2.7.0~preview1
# + rb_str_export_to_enc@Base 2.7.0~preview1
# + rb_str_format@Base 2.7.0~preview1
# + rb_str_free@Base 2.7.0~preview1
# + rb_str_freeze@Base 2.7.0~preview1
# + rb_str_hash@Base 2.7.0~preview1
# + rb_str_hash_cmp@Base 2.7.0~preview1
# + rb_str_inspect@Base 2.7.0~preview1
# + rb_str_intern@Base 2.7.0~preview1
# + rb_str_length@Base 2.7.0~preview1
# + rb_str_locktmp@Base 2.7.0~preview1
# + rb_str_locktmp_ensure@Base 2.7.0~preview1
# + rb_str_memsize@Base 2.7.0~preview1
# + rb_str_modify@Base 2.7.0~preview1
# + rb_str_modify_expand@Base 2.7.0~preview1
# + rb_str_new@Base 2.7.0~preview1
# + rb_str_new_cstr@Base 2.7.0~preview1
# + rb_str_new_frozen@Base 2.7.0~preview1
# + rb_str_new_shared@Base 2.7.0~preview1
# + rb_str_new_static@Base 2.7.0~preview1
# + rb_str_new_with_class@Base 2.7.0~preview1
# + rb_str_offset@Base 2.7.0~preview1
# + rb_str_opt_plus@Base 2.7.0~preview2
# + rb_str_plus@Base 2.7.0~preview1
# + rb_str_replace@Base 2.7.0~preview1
# + rb_str_resize@Base 2.7.0~preview1
# + rb_str_resurrect@Base 2.7.0~preview1
# + rb_str_scrub@Base 2.7.0~preview1
# + rb_str_set_len@Base 2.7.0~preview1
# + rb_str_setter@Base 2.7.0~preview1
# + rb_str_shared_replace@Base 2.7.0~preview1
# + rb_str_split@Base 2.7.0~preview1
# + rb_str_strlen@Base 2.7.0~preview1
# + rb_str_sublen@Base 2.7.0~preview1
# + rb_str_subpos@Base 2.7.0~preview1
# + rb_str_subseq@Base 2.7.0~preview1
# + rb_str_substr@Base 2.7.0~preview1
# + rb_str_succ@Base 2.7.0~preview1
# + rb_str_times@Base 2.7.0~preview1
# + rb_str_tmp_frozen_acquire@Base 2.7.0~preview2
# + rb_str_tmp_frozen_release@Base 2.7.0~preview2
# + rb_str_tmp_new@Base 2.7.0~preview1
# + rb_str_to_dbl@Base 2.7.0~preview1
# + rb_str_to_inum@Base 2.7.0~preview1
# + rb_str_to_str@Base 2.7.0~preview1
# + rb_str_unlocktmp@Base 2.7.0~preview1
# + rb_str_update@Base 2.7.0~preview1
# + rb_str_upto_each@Base 2.7.0~preview2
# + rb_str_upto_endless_each@Base 2.7.0~preview2
# + rb_str_vcatf@Base 2.7.0~preview1
# + rb_string_value@Base 2.7.0~preview1
# + rb_string_value_cstr@Base 2.7.0~preview1
# + rb_string_value_ptr@Base 2.7.0~preview1
# + rb_struct_alloc@Base 2.7.0~preview1
# + rb_struct_alloc_noinit@Base 2.7.0~preview1
# + rb_struct_aref@Base 2.7.0~preview1
# + rb_struct_aset@Base 2.7.0~preview1
# + rb_struct_define@Base 2.7.0~preview1
# + rb_struct_define_under@Base 2.7.0~preview1
# + rb_struct_define_without_accessor@Base 2.7.0~preview1
# + rb_struct_define_without_accessor_under@Base 2.7.0~preview1
# + rb_struct_getmember@Base 2.7.0~preview1
# + rb_struct_initialize@Base 2.7.0~preview1
# + rb_struct_members@Base 2.7.0~preview1
# + rb_struct_new@Base 2.7.0~preview1
# + rb_struct_s_members@Base 2.7.0~preview1
# + rb_struct_size@Base 2.7.0~preview1
# + rb_sym2id@Base 2.7.0~preview1
# + rb_sym2str@Base 2.7.0~preview1
# + rb_sym_all_symbols@Base 2.7.0~preview1
# + rb_sym_immortal_count@Base 2.7.0~preview1
# + rb_sym_proc_call@Base 2.7.0~preview2
# + rb_sym_to_proc@Base 2.7.0~preview2
# + rb_sym_to_s@Base 2.7.0~preview1
# + rb_symname_p@Base 2.7.0~preview1
# + rb_sys_fail@Base 2.7.0~preview1
# + rb_sys_fail_path_in@Base 2.7.0~preview1
# + rb_sys_fail_str@Base 2.7.0~preview1
# + rb_sys_warning@Base 2.7.0~preview1
# + rb_syserr_fail@Base 2.7.0~preview1
# + rb_syserr_fail_path_in@Base 2.7.0~preview1
# + rb_syserr_fail_str@Base 2.7.0~preview1
# + rb_syserr_new@Base 2.7.0~preview1
# + rb_syserr_new_str@Base 2.7.0~preview1
# + rb_syswait@Base 2.7.0~preview1
# + rb_tainted_str_new@Base 2.7.0~preview1
# + rb_tainted_str_new_cstr@Base 2.7.0~preview1
# + rb_thread_add_event_hook2@Base 2.7.0~preview1
# + rb_thread_add_event_hook@Base 2.7.0~preview1
# + rb_thread_alone@Base 2.7.0~preview1
# + rb_thread_atfork@Base 2.7.0~preview1
# + rb_thread_atfork_before_exec@Base 2.7.0~preview1
# + rb_thread_call_with_gvl@Base 2.7.0~preview1
# + rb_thread_call_without_gvl2@Base 2.7.0~preview1
# + rb_thread_call_without_gvl@Base 2.7.0~preview1
# + rb_thread_check_ints@Base 2.7.0~preview1
# + rb_thread_check_trap_pending@Base 2.7.0~preview1
# + rb_thread_create@Base 2.7.0~preview1
# + rb_thread_current@Base 2.7.0~preview1
# + rb_thread_fd_close@Base 2.7.0~preview1
# + rb_thread_fd_select@Base 2.7.0~preview1
# + rb_thread_fd_writable@Base 2.7.0~preview1
# + rb_thread_interrupted@Base 2.7.0~preview1
# + rb_thread_io_blocking_region@Base 2.7.0~preview1
# + rb_thread_kill@Base 2.7.0~preview1
# + rb_thread_local_aref@Base 2.7.0~preview1
# + rb_thread_local_aset@Base 2.7.0~preview1
# + rb_thread_main@Base 2.7.0~preview1
# + rb_thread_remove_event_hook@Base 2.7.0~preview1
# + rb_thread_remove_event_hook_with_data@Base 2.7.0~preview1
# + rb_thread_run@Base 2.7.0~preview1
# + rb_thread_schedule@Base 2.7.0~preview1
# + rb_thread_sleep@Base 2.7.0~preview1
# + rb_thread_sleep_deadly@Base 2.7.0~preview1
# + rb_thread_sleep_forever@Base 2.7.0~preview1
# + rb_thread_stop@Base 2.7.0~preview1
# + rb_thread_wait_fd@Base 2.7.0~preview1
# + rb_thread_wait_for@Base 2.7.0~preview1
# + rb_thread_wakeup@Base 2.7.0~preview1
# + rb_thread_wakeup_alive@Base 2.7.0~preview1
# + rb_threadptr_execute_interrupts@Base 2.7.0~preview2
# + rb_throw@Base 2.7.0~preview1
# + rb_throw_obj@Base 2.7.0~preview1
# + rb_time_interval@Base 2.7.0~preview1
# + rb_time_nano_new@Base 2.7.0~preview1
# + rb_time_new@Base 2.7.0~preview1
# + rb_time_num_new@Base 2.7.0~preview1
# + rb_time_succ@Base 2.7.0~preview1
# + rb_time_timespec@Base 2.7.0~preview1
# + rb_time_timespec_interval@Base 2.7.0~preview2
# + rb_time_timespec_new@Base 2.7.0~preview1
# + rb_time_timeval@Base 2.7.0~preview1
# + rb_time_utc_offset@Base 2.7.0~preview2
# + rb_timespec_now@Base 2.7.0~preview1
# + rb_to_encoding@Base 2.7.0~preview1
# + rb_to_encoding_index@Base 2.7.0~preview1
# + rb_to_float@Base 2.7.0~preview1
# + rb_to_id@Base 2.7.0~preview1
# + rb_to_int@Base 2.7.0~preview1
# + rb_to_symbol@Base 2.7.0~preview1
# + rb_tracearg_binding@Base 2.7.0~preview1
# + rb_tracearg_callee_id@Base 2.7.0~preview2
# + rb_tracearg_defined_class@Base 2.7.0~preview1
# + rb_tracearg_event@Base 2.7.0~preview1
# + rb_tracearg_event_flag@Base 2.7.0~preview1
# + rb_tracearg_from_tracepoint@Base 2.7.0~preview1
# + rb_tracearg_lineno@Base 2.7.0~preview1
# + rb_tracearg_method_id@Base 2.7.0~preview1
# + rb_tracearg_object@Base 2.7.0~preview1
# + rb_tracearg_path@Base 2.7.0~preview1
# + rb_tracearg_raised_exception@Base 2.7.0~preview1
# + rb_tracearg_return_value@Base 2.7.0~preview1
# + rb_tracearg_self@Base 2.7.0~preview1
# + rb_tracepoint_disable@Base 2.7.0~preview1
# + rb_tracepoint_enable@Base 2.7.0~preview1
# + rb_tracepoint_enabled_p@Base 2.7.0~preview1
# + rb_tracepoint_new@Base 2.7.0~preview1
# + rb_typeddata_inherited_p@Base 2.7.0~preview1
# + rb_typeddata_is_kind_of@Base 2.7.0~preview1
# + rb_uint2big@Base 2.7.0~preview1
# + rb_uint2inum@Base 2.7.0~preview1
# + rb_ull2inum@Base 2.7.0~preview1
# + rb_undef@Base 2.7.0~preview1
# + rb_undef_alloc_func@Base 2.7.0~preview1
# + rb_undef_method@Base 2.7.0~preview1
# + rb_undefine_finalizer@Base 2.7.0~preview1
# + rb_unexpected_type@Base 2.7.0~preview1
# + rb_update_max_fd@Base 2.7.0~preview1
# + rb_usascii_encindex@Base 2.7.0~preview1
# + rb_usascii_encoding@Base 2.7.0~preview1
# + rb_usascii_str_new@Base 2.7.0~preview1
# + rb_usascii_str_new_cstr@Base 2.7.0~preview1
# + rb_usascii_str_new_static@Base 2.7.0~preview1
# + rb_utf8_encindex@Base 2.7.0~preview1
# + rb_utf8_encoding@Base 2.7.0~preview1
# + rb_utf8_str_new@Base 2.7.0~preview1
# + rb_utf8_str_new_cstr@Base 2.7.0~preview1
# + rb_utf8_str_new_static@Base 2.7.0~preview1
# + rb_uv_to_utf8@Base 2.7.0~preview1
# + rb_vm_call0@Base 2.7.0~preview2
# + rb_vm_call_kw@Base 2.7.0~preview2
# + rb_vm_exec@Base 2.7.0~preview2
# + rb_vm_get_ruby_level_next_cfp@Base 2.7.0~preview2
# + rb_vm_invoke_bmethod@Base 2.7.0~preview2
# + rb_vm_invoke_proc@Base 2.7.0~preview2
# + rb_vm_localjump_error@Base 2.7.0~preview2
# + rb_vm_make_proc_lambda@Base 2.7.0~preview2
# + rb_vm_search_method_slowpath@Base 2.7.0~preview2
# + rb_vrescue2@Base 2.7.0~preview2
# + rb_vsprintf@Base 2.7.0~preview1
# + rb_wait_for_single_fd@Base 2.7.0~preview1
# + rb_waitpid@Base 2.7.0~preview1
# + rb_warn@Base 2.7.0~preview1
# + rb_warning@Base 2.7.0~preview1
# + rb_warning_category_enabled_p@Base 2.7.0
# + rb_wb_protected_newobj_of@Base 2.7.0~preview1
# + rb_wb_unprotected_newobj_of@Base 2.7.0~preview1
# + rb_write_error2@Base 2.7.0~preview1
# + rb_write_error@Base 2.7.0~preview1
# + rb_write_error_str@Base 2.7.0~preview1
# + rb_yield@Base 2.7.0~preview1
# + rb_yield_block@Base 2.7.0~preview1
# + rb_yield_splat@Base 2.7.0~preview1
# + rb_yield_splat_kw@Base 2.7.0~preview2
# + rb_yield_values2@Base 2.7.0~preview1
# + rb_yield_values@Base 2.7.0~preview1
# + rb_yield_values_kw@Base 2.7.0~preview2
# + rb_yytnamerr@Base 2.7.0~preview2
# + ruby_Init_Continuation_body@Base 2.7.0~preview1
# + ruby_Init_Fiber_as_Coroutine@Base 2.7.0~preview1
# + ruby_api_version@Base 2.7.0~preview1
# + ruby_brace_glob@Base 2.7.0~preview1
# + ruby_cleanup@Base 2.7.0~preview1
# + ruby_copyright@Base 2.7.0~preview1
# + ruby_current_execution_context_ptr@Base 2.7.0~preview2
# + ruby_current_vm_ptr@Base 2.7.0~preview2
# + ruby_debug_counter_get@Base 2.7.0
# + ruby_debug_counter_reset@Base 2.7.0
# + ruby_debug_counter_show_at_exit@Base 2.7.0
# + ruby_debug_print_id@Base 2.7.0~preview1
# + ruby_debug_print_indent@Base 2.7.0~preview1
# + ruby_debug_print_node@Base 2.7.0~preview1
# + ruby_debug_print_value@Base 2.7.0~preview1
# + ruby_default_signal@Base 2.7.0~preview1
# + ruby_description@Base 2.7.0~preview1
# + ruby_digit36_to_number_table@Base 2.7.0~preview1
# + ruby_each_words@Base 2.7.0~preview1
# + ruby_enc_find_basename@Base 2.7.0~preview1
# + ruby_enc_find_extname@Base 2.7.0~preview1
# + ruby_engine@Base 2.7.0~preview1
# + ruby_exec_node@Base 2.7.0~preview1
# + ruby_executable_node@Base 2.7.0~preview1
# + ruby_fill_random_bytes@Base 2.7.0~preview2
# + ruby_finalize@Base 2.7.0~preview1
# + ruby_float_mod@Base 2.7.0~preview2
# + ruby_getcwd@Base 2.7.0~preview1
# + ruby_glob@Base 2.7.0~preview1
# + ruby_global_name_punct_bits@Base 2.7.0~preview1
# + ruby_hexdigits@Base 2.7.0~preview1
# + ruby_incpush@Base 2.7.0~preview1
# + ruby_init@Base 2.7.0~preview1
# + ruby_init_ext@Base 2.7.0~preview1
# + ruby_init_loadpath@Base 2.7.0~preview1
# + ruby_init_setproctitle@Base 2.7.0~preview1
# + ruby_init_stack@Base 2.7.0~preview1
# + ruby_malloc_size_overflow@Base 2.7.0~preview1
# + ruby_native_thread_p@Base 2.7.0~preview1
# + ruby_node_name@Base 2.7.0~preview1
# + ruby_options@Base 2.7.0~preview1
# + ruby_patchlevel@Base 2.7.0~preview1
# + ruby_platform@Base 2.7.0~preview1
# + ruby_posix_signal@Base 2.7.0~preview1
# + ruby_process_options@Base 2.7.0~preview1
# + ruby_prog_init@Base 2.7.0~preview1
# + ruby_release_date@Base 2.7.0~preview1
# + ruby_reset_leap_second_info@Base 2.7.0~preview2
# + ruby_run_node@Base 2.7.0~preview1
# + ruby_safe_level_2_warning@Base 2.7.0~preview1
# + ruby_scan_digits@Base 2.7.0~preview1
# + ruby_scan_hex@Base 2.7.0~preview1
# + ruby_scan_oct@Base 2.7.0~preview1
# + ruby_script@Base 2.7.0~preview1
# + ruby_set_argv@Base 2.7.0~preview1
# + ruby_set_debug_option@Base 2.7.0~preview1
# + ruby_set_script_name@Base 2.7.0~preview1
# + ruby_setenv@Base 2.7.0~preview1
# + ruby_setup@Base 2.7.0~preview1
# + ruby_show_copyright@Base 2.7.0~preview1
# + ruby_show_version@Base 2.7.0~preview1
# + ruby_sig_finalize@Base 2.7.0~preview1
# + ruby_signal_name@Base 2.7.0~preview1
# + ruby_snprintf@Base 2.7.0~preview1
# + ruby_stack_check@Base 2.7.0~preview1
# + ruby_stack_length@Base 2.7.0~preview1
# + ruby_stop@Base 2.7.0~preview1
# + ruby_strdup@Base 2.7.0~preview1
# + ruby_strtod@Base 2.7.0~preview1
# + ruby_strtoul@Base 2.7.0~preview1
# + ruby_sysinit@Base 2.7.0~preview1
# + ruby_thread_has_gvl_p@Base 2.7.0~preview1
# + ruby_unsetenv@Base 2.7.0~preview1
# + ruby_version@Base 2.7.0~preview1
# + ruby_vm_at_exit@Base 2.7.0~preview1
# + ruby_vm_class_serial@Base 2.7.0~preview2
# + ruby_vm_const_missing_count@Base 2.7.0~preview2
# + ruby_vm_destruct@Base 2.7.0~preview1
# + ruby_vm_event_enabled_global_flags@Base 2.7.0~preview2
# + ruby_vm_event_flags@Base 2.7.0~preview2
# + ruby_vm_event_local_num@Base 2.7.0~preview2
# + ruby_vm_global_constant_state@Base 2.7.0~preview2
# + ruby_vm_global_method_state@Base 2.7.0~preview2
# + ruby_vsnprintf@Base 2.7.0~preview1
# + ruby_xcalloc@Base 2.7.0~preview1
# + ruby_xfree@Base 2.7.0~preview1
# + ruby_xmalloc2@Base 2.7.0~preview1
# + ruby_xmalloc@Base 2.7.0~preview1
# + ruby_xrealloc2@Base 2.7.0~preview1
# + ruby_xrealloc@Base 2.7.0~preview1
# + setproctitle@Base 2.7.0~preview1
# + strlcat@Base 2.7.0
# + strlcpy@Base 2.7.0
# diff -Nru debian~/libruby.stp debian/libruby.stp
# --- debian~/libruby.stp	1969-12-31 19:00:00.000000000 -0500
# +++ debian/libruby.stp	2021-01-25 23:37:04.798005594 -0500
# @@ -0,0 +1,303 @@
# +/* SystemTap tapset to make it easier to trace Ruby 2.0
# + *
# + * All probes provided by Ruby can be listed using following command
# + * (the path to the library must be adjuste appropriately):
# + *
# + * stap -L 'process("@LIBRARY_PATH@").mark("*")'
# + */
# +
# +/**
# + * probe ruby.array.create - Allocation of new array.
# + *
# + * @size: Number of elements (an int)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.array.create =
# +      process("@LIBRARY_PATH@").mark("array__create")
# +{
# +	size = $arg1
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.cmethod.entry - Fired just before a method implemented in C is entered.
# + *
# + * @classname: Name of the class (string)
# + * @methodname: The method about bo be executed (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.cmethod.entry =
# +      process("@LIBRARY_PATH@").mark("cmethod__entry")
# +{
# +	classname  = user_string($arg1)
# +	methodname = user_string($arg2)
# +	file = user_string($arg3)
# +	line = $arg4
# +}
# +
# +/**
# + * probe ruby.cmethod.return - Fired just after a method implemented in C has returned.
# + *
# + * @classname: Name of the class (string)
# + * @methodname: The executed method (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.cmethod.return =
# +      process("@LIBRARY_PATH@").mark("cmethod__return")
# +{
# +	classname  = user_string($arg1)
# +	methodname = user_string($arg2)
# +	file = user_string($arg3)
# +	line = $arg4
# +}
# +
# +/**
# + * probe ruby.find.require.entry - Fired when require starts to search load
# + * path for suitable file to require.
# + *
# + * @requiredfile: The name of the file to be required (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.find.require.entry =
# +      process("@LIBRARY_PATH@").mark("find__require__entry")
# +{
# +	requiredfile = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.find.require.return - Fired just after require has finished
# + * search of load path for suitable file to require.
# + *
# + * @requiredfile: The name of the file to be required (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.find.require.return =
# +      process("@LIBRARY_PATH@").mark("find__require__return")
# +{
# +	requiredfile = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.gc.mark.begin - Fired when a GC mark phase is about to start.
# + *
# + * It takes no arguments.
# + */
# +probe ruby.gc.mark.begin =
# +      process("@LIBRARY_PATH@").mark("gc__mark__begin")
# +{
# +}
# +
# +/**
# + * probe ruby.gc.mark.end - Fired when a GC mark phase has ended.
# + *
# + * It takes no arguments.
# + */
# +probe ruby.gc.mark.end =
# +      process("@LIBRARY_PATH@").mark("gc__mark__end")
# +{
# +}
# +
# +/**
# + * probe ruby.gc.sweep.begin - Fired when a GC sweep phase is about to start.
# + *
# + * It takes no arguments.
# + */
# +probe ruby.gc.sweep.begin =
# +      process("@LIBRARY_PATH@").mark("gc__sweep__begin")
# +{
# +}
# +
# +/**
# + * probe ruby.gc.sweep.end - Fired when a GC sweep phase has ended.
# + *
# + * It takes no arguments.
# + */
# +probe ruby.gc.sweep.end =
# +      process("@LIBRARY_PATH@").mark("gc__sweep__end")
# +{
# +}
# +
# +/**
# + * probe ruby.hash.create - Allocation of new hash.
# + *
# + * @size: Number of elements (int)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.hash.create =
# +      process("@LIBRARY_PATH@").mark("hash__create")
# +{
# +	size = $arg1
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.load.entry - Fired when calls to "load" are made.
# + *
# + * @loadedfile: The name of the file to be loaded (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.load.entry =
# +      process("@LIBRARY_PATH@").mark("load__entry")
# +{
# +	loadedfile = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.load.return - Fired just after require has finished
# + * search of load path for suitable file to require.
# + *
# + * @loadedfile: The name of the file that was loaded (string)
# + */
# +probe ruby.load.return =
# +      process("@LIBRARY_PATH@").mark("load__return")
# +{
# +	loadedfile = user_string($arg1)
# +}
# +
# +/**
# + * probe ruby.method.entry - Fired just before a method implemented in Ruby is entered.
# + *
# + * @classname: Name of the class (string)
# + * @methodname: The method about bo be executed (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.method.entry =
# +      process("@LIBRARY_PATH@").mark("method__entry")
# +{
# +	classname  = user_string($arg1)
# +	methodname = user_string($arg2)
# +	file = user_string($arg3)
# +	line = $arg4
# +}
# +
# +/**
# + * probe ruby.method.return - Fired just after a method implemented in Ruby has returned.
# + *
# + * @classname: Name of the class (string)
# + * @methodname: The executed method (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.method.return =
# +      process("@LIBRARY_PATH@").mark("method__return")
# +{
# +	classname  = user_string($arg1)
# +	methodname = user_string($arg2)
# +	file = user_string($arg3)
# +	line = $arg4
# +}
# +
# +/**
# + * probe ruby.object.create - Allocation of new object.
# + *
# + * @classname: Name of the class (string)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.object.create =
# +      process("@LIBRARY_PATH@").mark("object__create")
# +{
# +	classname = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.parse.begin - Fired just before a Ruby source file is parsed.
# + *
# + * @parsedfile: The name of the file to be parsed (string)
# + * @parsedline: The line number of beginning of parsing (int)
# + */
# +probe ruby.parse.begin =
# +      process("@LIBRARY_PATH@").mark("parse__begin")
# +{
# +	parsedfile = user_string($arg1)
# +	parsedline = $arg2
# +}
# +
# +/**
# + * probe ruby.parse.end - Fired just after a Ruby source file was parsed.
# + *
# + * @parsedfile: The name of parsed the file (string)
# + * @parsedline: The line number of beginning of parsing (int)
# + */
# +probe ruby.parse.end =
# +      process("@LIBRARY_PATH@").mark("parse__end")
# +{
# +	parsedfile = user_string($arg1)
# +	parsedline = $arg2
# +}
# +
# +/**
# + * probe ruby.raise - Fired when an exception is raised.
# + *
# + * @classname: The class name of the raised exception (string)
# + * @file: The name of the file where the exception was raised (string)
# + * @line: The line number in the file where the exception was raised (int)
# + */
# +probe ruby.raise =
# +      process("@LIBRARY_PATH@").mark("raise")
# +{
# +	classname  = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.require.entry - Fired on calls to rb_require_safe (when a file
# + * is required).
# + *
# + * @requiredfile: The name of the file to be required (string)
# + * @file: The file that called "require" (string)
# + * @line: The line number where the call to require was made(int)
# + */
# +probe ruby.require.entry =
# +      process("@LIBRARY_PATH@").mark("require__entry")
# +{
# +	requiredfile = user_string($arg1)
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# +
# +/**
# + * probe ruby.require.return - Fired just after require has finished
# + * search of load path for suitable file to require.
# + *
# + * @requiredfile: The file that was required (string)
# + */
# +probe ruby.require.return =
# +      process("@LIBRARY_PATH@").mark("require__return")
# +{
# +	requiredfile = user_string($arg1)
# +}
# +
# +/**
# + * probe ruby.string.create - Allocation of new string.
# + *
# + * @size: Number of elements (an int)
# + * @file: The file name where the method is being called (string)
# + * @line: The line number where the method is being called (int)
# + */
# +probe ruby.string.create =
# +      process("@LIBRARY_PATH@").mark("string__create")
# +{
# +	size = $arg1
# +	file = user_string($arg2)
# +	line = $arg3
# +}
# diff -Nru debian~/manpages/gem2.7.1 debian/manpages/gem2.7.1
# --- debian~/manpages/gem2.7.1	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/gem2.7.1	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,42 @@
# +.\" DO NOT MODIFY THIS FILE! it was generated by rd2
# +.TH GEM2.7 1 "July 2014"
# +.SH NAME
# +.PP
# +gem2.7 \- frontend to RubyGems, the Ruby package manager
# +.SH SYNOPSIS
# +.PP
# +gem2.7 command [arguments...] [options...]
# +.SH DESCRIPTION
# +.PP
# +gem2.7 is the frontend to RubyGems, the standard package manager for Ruby.
# +This is a basic help message containing pointers to more information.
# +.PP
# +Further help:
# +.TP
# +.fi
# +.B
# +gem2.7 help commands
# +list all gem2.7 commands
# +.TP
# +.fi
# +.B
# +gem2.7 help examples
# +shows some examples of usage
# +.TP
# +.fi
# +.B
# +gem2.7 help  COMMAND
# +show help on COMMAND, (e.g. 'gem2.7 help install')
# +.SH LINKS
# +.PP
# +http://rubygems.org/
# +.SH EXAMPLES
# +.PP
# +gem2.7 install rake
# +gem2.7 list \-\-local
# +gem2.7 build package.gemspec
# +gem2.7 help install
# +.SH SEE ALSO
# +.PP
# +bundle(1)
# +
# diff -Nru debian~/manpages/gem2.7.rd debian/manpages/gem2.7.rd
# --- debian~/manpages/gem2.7.rd	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/gem2.7.rd	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,41 @@
# +=begin
# += NAME
# +
# +gem2.7 - frontend to RubyGems, the Ruby package manager
# +
# += SYNOPSIS
# +
# +gem2.7 command [arguments...] [options...]
# +
# += DESCRIPTION
# +
# +gem2.7 is the frontend to RubyGems, the standard package manager for Ruby.
# +This is a basic help message containing pointers to more information.
# +
# +Further help:
# +
# +: gem2.7 help commands
# +  list all gem2.7 commands
# +
# +: gem2.7 help examples
# +  shows some examples of usage
# +
# +: gem2.7 help ((|COMMAND|))
# +  show help on COMMAND, (e.g. 'gem2.7 help install')
# +
# += LINKS
# +
# +http://rubygems.org/
# +
# += EXAMPLES
# +
# +gem2.7 install rake
# +gem2.7 list --local
# +gem2.7 build package.gemspec
# +gem2.7 help install
# +
# += SEE ALSO
# +
# +bundle(1)
# +
# +=end
# diff -Nru debian~/manpages/rdoc2.7.1 debian/manpages/rdoc2.7.1
# --- debian~/manpages/rdoc2.7.1	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/rdoc2.7.1	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,209 @@
# +.\" DO NOT MODIFY THIS FILE! it was generated by rd2
# +.TH RDOC2.7 1 "July 2014"
# +.SH NAME
# +.PP
# +rdoc2.7 \- Generate documentation from Ruby script files
# +.SH SYNOPSIS
# +.PP
# +rdoc2.7 [options]  [names...]
# +.SH DESCRIPTION
# +.PP
# +Files are parsed, and the information they contain collected, before any
# +output is produced. This allows cross references between all files to be
# +resolved. If a name is a directory, it is traversed. If no names are
# +specified, all Ruby files in the current directory (and subdirectories) are
# +processed.
# +.PP
# +Available output formatters: chm, html, ri, xml
# +.PP
# +For information on where the output goes, use:
# +.nf
# +\&    rdoc \-\-help\-output
# +.fi
# +.SH OPTIONS
# +.TP
# +.fi
# +.B
# +\-\-accessor, \-A  accessorname[,..]
# +comma separated list of additional class methods that should be treated
# +like 'attr_reader' and friends. Option may be repeated. Each accessorname
# +may have '=text' appended, in which case that text appears where the
# +r/w/rw appears for normal accessors.
# +.TP
# +.fi
# +.B
# +\-\-all, \-a
# +include all methods (not just public) in the output.
# +.TP
# +.fi
# +.B
# +\-\-charset, \-c  charset
# +specifies HTML character\-set
# +.TP
# +.fi
# +.B
# +\-\-debug, \-D
# +displays lots on internal stuff
# +.TP
# +.fi
# +.B
# +\-\-diagram, \-d
# +generate diagrams showing modules and classes.  You need dot V1.8.6 or
# +later to use the \-\-diagram option correctly. Dot is available from
# +<URL:http://www.research.att.com/sw/tools/graphviz/>.
# +.TP
# +.fi
# +.B
# +\-\-exclude, \-x  pattern
# +do not process files or directories matching pattern. Files given
# +explicitly on the command line will never be excluded.
# +.TP
# +.fi
# +.B
# +\-\-extension, \-E  new = old
# +treat files ending with .new as if they ended with .old. Using '\-E cgi=rb'
# +will cause xxx.cgi to be parsed as a Ruby file
# +.TP
# +.fi
# +.B
# +\-\-fileboxes, \-F
# +classes are put in boxes which represents files, where these classes
# +reside. Classes shared between more than one file are shown with list of
# +files that sharing them.  Silently discarded if \-\-diagram is not given
# +Experimental.
# +.TP
# +.fi
# +.B
# +\-\-fmt, \-f  formatname
# +set the output formatter (see below).
# +.TP
# +.fi
# +.B
# +\-\-help, \-h
# +print usage.
# +.TP
# +.fi
# +.B
# +\-\-help\-output, \-O
# +explain the various output options.
# +.TP
# +.fi
# +.B
# +\-\-image\-format, \-I  gif|png|jpg|jpeg
# +sets output image format for diagrams. Can be png, gif, jpeg, jpg. If this
# +option is omitted, png is used. Requires \-\-diagram.
# +.TP
# +.fi
# +.B
# +\-\-include, \-i  dir[,dir...]
# +set (or add to) the list of directories to be searched when satisfying
# +:include: requests. Can be used more than once.
# +.TP
# +.fi
# +.B
# +\-\-inline\-source, \-S
# +show method source code inline, rather than via a popup link.
# +.TP
# +.fi
# +.B
# +\-\-line\-numbers, \-N
# +include line numbers in the source code
# +.TP
# +.fi
# +.B
# +\-\-main, \-m  name
# +name will be the initial page displayed.
# +.TP
# +.fi
# +.B
# +\-\-merge, \-M
# +when creating ri output, merge processed classes into previously
# +documented classes of the name name.
# +.TP
# +.fi
# +.B
# +\-\-one\-file, \-1
# +put all the output into a single file.
# +.TP
# +.fi
# +.B
# +\-\-op, \-o  dir
# +set the output directory.
# +.TP
# +.fi
# +.B
# +\-\-opname, \-n  name
# +set the name of the output. Has no effect for HTML.
# +.TP
# +.fi
# +.B
# +\-\-promiscuous, \-p
# +When documenting a file that contains a module or class also defined in
# +other files, show all stuff for that module/class in each files page. By
# +default, only show stuff defined in that particular file.
# +.TP
# +.fi
# +.B
# +\-\-quiet, \-q
# +don't show progress as we parse.
# +.TP
# +.fi
# +.B
# +\-\-ri, \-r
# +generate output for use by 'ri.' The files are stored in the '.rdoc'
# +directory under your home directory unless overridden by a subsequent \-\-op
# +parameter, so no special privileges are needed.
# +.TP
# +.fi
# +.B
# +\-\-ri\-site, \-R
# +generate output for use by 'ri.' The files are stored in a site\-wide
# +directory, making them accessible to others, so special privileges are
# +needed.
# +.TP
# +.fi
# +.B
# +\-\-ri\-system, \-Y
# +generate output for use by 'ri.' The files are stored in a system\-level
# +directory, making them accessible to others, so special privileges are
# +needed. This option is intended to be used during Ruby installations.
# +.TP
# +.fi
# +.B
# +\-\-show\-hash, \-H
# +a name of the form #name in a comment is a possible hyperlink to an
# +instance method name. When displayed, the '#' is removed unless this
# +option is specified.
# +.TP
# +.fi
# +.B
# +\-\-style, \-s  stylesheet\-url
# +specifies the URL of a separate stylesheet.
# +.TP
# +.fi
# +.B
# +\-\-tab\-width, \-w  n
# +set the width of tab characters (default 8).
# +.TP
# +.fi
# +.B
# +\-\-template, \-T  template\-name
# +set the template used when generating output.
# +.TP
# +.fi
# +.B
# +\-\-title, \-t  text
# +set text as the title for the output.
# +.TP
# +.fi
# +.B
# +\-\-version, \-v
# +display  RDoc's version.
# +.TP
# +.fi
# +.B
# +\-\-webcvs, \-W  url
# +specify a URL for linking to a web frontend to CVS. If the URL contains a
# +'%s', the name of the current file will be substituted; if the URL doesn't
# +contain a '%s', the filename will be appended to it.
# +
# diff -Nru debian~/manpages/rdoc2.7.rd debian/manpages/rdoc2.7.rd
# --- debian~/manpages/rdoc2.7.rd	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/rdoc2.7.rd	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,147 @@
# +=begin
# += NAME
# +
# +rdoc2.7 - Generate documentation from Ruby script files
# +
# += SYNOPSIS
# +
# +rdoc2.7 [options]  [names...]
# +
# += DESCRIPTION
# +
# +Files are parsed, and the information they contain collected, before any
# +output is produced. This allows cross references between all files to be
# +resolved. If a name is a directory, it is traversed. If no names are
# +specified, all Ruby files in the current directory (and subdirectories) are
# +processed.
# +
# +Available output formatters: chm, html, ri, xml
# +
# +For information on where the output goes, use:
# +
# +   rdoc --help-output
# +
# += OPTIONS
# +
# +: --accessor, -A ((|accessorname[,..]|))
# +  comma separated list of additional class methods that should be treated
# +  like 'attr_reader' and friends. Option may be repeated. Each accessorname
# +  may have '=text' appended, in which case that text appears where the
# +  r/w/rw appears for normal accessors.
# +
# +: --all, -a
# +  include all methods (not just public) in the output.
# +
# +: --charset, -c ((|charset|))
# +  specifies HTML character-set
# +
# +: --debug, -D
# +  displays lots on internal stuff
# +
# +: --diagram, -d
# +  generate diagrams showing modules and classes.  You need dot V1.8.6 or
# +  later to use the --diagram option correctly. Dot is available from
# +  ((<URL:http://www.research.att.com/sw/tools/graphviz/>)).
# +
# +: --exclude, -x ((|pattern|))
# +  do not process files or directories matching pattern. Files given
# +  explicitly on the command line will never be excluded.
# +
# +: --extension, -E ((|new|))=((|old|))
# +  treat files ending with .new as if they ended with .old. Using '-E cgi=rb'
# +  will cause xxx.cgi to be parsed as a Ruby file
# +
# +: --fileboxes, -F
# +  classes are put in boxes which represents files, where these classes
# +  reside. Classes shared between more than one file are shown with list of
# +  files that sharing them.  Silently discarded if --diagram is not given
# +  Experimental.
# +
# +: --fmt, -f ((|formatname|))
# +  set the output formatter (see below).
# +
# +: --help, -h
# +  print usage.
# +
# +: --help-output, -O
# +  explain the various output options.
# +
# +: --image-format, -I ((|(('gif|png|jpg|jpeg'))|))
# +  sets output image format for diagrams. Can be png, gif, jpeg, jpg. If this
# +  option is omitted, png is used. Requires --diagram.
# +
# +: --include, -i ((|dir[,dir...]|))
# +  set (or add to) the list of directories to be searched when satisfying
# +  ((':include:')) requests. Can be used more than once.
# +
# +: --inline-source, -S
# +  show method source code inline, rather than via a popup link.
# +
# +: --line-numbers, -N
# +  include line numbers in the source code
# +
# +: --main, -m ((|name|))
# +  ((|name|)) will be the initial page displayed.
# +
# +: --merge, -M
# +  when creating ri output, merge processed classes into previously
# +  documented classes of the name name.
# +
# +: --one-file, -1
# +  put all the output into a single file.
# +
# +: --op, -o ((|dir|))
# +  set the output directory.
# +
# +: --opname, -n ((|name|))
# +  set the ((|name|)) of the output. Has no effect for HTML.
# +
# +: --promiscuous, -p
# +  When documenting a file that contains a module or class also defined in
# +  other files, show all stuff for that module/class in each files page. By
# +  default, only show stuff defined in that particular file.
# +
# +: --quiet, -q
# +  don't show progress as we parse.
# +
# +: --ri, -r
# +  generate output for use by 'ri.' The files are stored in the '.rdoc'
# +  directory under your home directory unless overridden by a subsequent --op
# +  parameter, so no special privileges are needed.
# +
# +: --ri-site, -R
# +  generate output for use by 'ri.' The files are stored in a site-wide
# +  directory, making them accessible to others, so special privileges are
# +  needed.
# +
# +: --ri-system, -Y
# +  generate output for use by 'ri.' The files are stored in a system-level
# +  directory, making them accessible to others, so special privileges are
# +  needed. This option is intended to be used during Ruby installations.
# +
# +: --show-hash, -H
# +  a name of the form #name in a comment is a possible hyperlink to an
# +  instance method name. When displayed, the '#' is removed unless this
# +  option is specified.
# +
# +: --style, -s ((|stylesheet-url|))
# +  specifies the URL of a separate stylesheet.
# +
# +: --tab-width, -w ((|n|))
# +  set the width of tab characters (default 8).
# +
# +: --template, -T ((|template-name|))
# +  set the template used when generating output.
# +
# +: --title, -t ((|text|))
# +  set ((|text|)) as the title for the output.
# +
# +: --version, -v
# +  display  RDoc's version.
# +
# +: --webcvs, -W ((|url|))
# +  specify a URL for linking to a web frontend to CVS. If the URL contains a
# +  '%s', the name of the current file will be substituted; if the URL doesn't
# +  contain a '%s', the filename will be appended to it.
# +
# +=end
# diff -Nru debian~/manpages/testrb2.7.1 debian/manpages/testrb2.7.1
# --- debian~/manpages/testrb2.7.1	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/testrb2.7.1	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,60 @@
# +.\" DO NOT MODIFY THIS FILE! it was generated by rd2
# +.TH TESTRB2.4 1 "July 2014"
# +.SH NAME
# +.PP
# +testrb2.4 \- Automatic runnter for Test::Unit of Ruby
# +.SH SYNOPSIS
# +.PP
# +testrb2.4 [options] [\-\- untouched arguments] test ...
# +.SH DESCRIPTION
# +.PP
# +testrb2.4 loads and runs unit\-tests.  If test is directory name, testrb2.4
# +testrb2.4 traverses the directory.
# +.SH OPTIONS
# +.TP
# +.fi
# +.B
# +\-r, \-\-runner=RUNNER
# +Use the given RUNNER.  (t[k], c[onsole], g[tk], f[ox])
# +.TP
# +.fi
# +.B
# +\-a, \-\-add=TORUN
# +Add TORUN to the list of things to run;  can be a file or a directory.
# +.TP
# +.fi
# +.B
# +\-p, \-\-pattern=PATTERN
# +Match files to collect against PATTERN.  (default pattern is
# +/\\Atest_.*\\.rb\\Z/.)
# +.TP
# +.fi
# +.B
# +\-n, \-\-name=NAME
# +Runs tests matching NAME.  (patterns may be used.)
# +.TP
# +.fi
# +.B
# +\-t, \-\-testcase=TESTCASE
# +Runs tests in TestCases matching TESTCASE.  (patterns may be used.)
# +.TP
# +.fi
# +.B
# +\-v, \-\-verbose=[LEVEL]
# +Set the output level (default is verbose).  (p[rogress], n[ormal],
# +v[erbose], s[ilent])
# +.TP
# +.fi
# +.B
# +\-\-
# +Stop processing options so that the remaining options will be passed to
# +the test.
# +.TP
# +.fi
# +.B
# +\-h, \-\-help
# +Display help.
# +.SH AUTHOR
# +.PP
# +This manpage was contributed by akira yamada <akira@debian.org>
# +
# diff -Nru debian~/manpages/testrb2.7.rd debian/manpages/testrb2.7.rd
# --- debian~/manpages/testrb2.7.rd	1969-12-31 19:00:00.000000000 -0500
# +++ debian/manpages/testrb2.7.rd	2021-01-25 23:37:04.802005514 -0500
# @@ -0,0 +1,57 @@
# +=begin
# +
# += NAME
# +
# +testrb2.4 - Automatic runnter for Test::Unit of Ruby
# +
# += SYNOPSIS
# +
# +testrb2.4 [options] [-- untouched arguments] test ...
# +
# += DESCRIPTION
# +
# +testrb2.4 loads and runs unit-tests.  If test is directory name, testrb2.4
# +testrb2.4 traverses the directory.
# +
# += OPTIONS
# +
# +: -r, --runner=RUNNER
# +
# +  Use the given RUNNER.  (t[k], c[onsole], g[tk], f[ox])
# +
# +: -a, --add=TORUN
# +
# +  Add TORUN to the list of things to run;  can be a file or a directory.
# +
# +: -p, --pattern=PATTERN
# +
# +   Match files to collect against PATTERN.  (default pattern is
# +   /\Atest_.*\.rb\Z/.)
# +
# +: -n, --name=NAME
# +
# +  Runs tests matching NAME.  (patterns may be used.)
# +
# +: -t, --testcase=TESTCASE
# +
# +  Runs tests in TestCases matching TESTCASE.  (patterns may be used.)
# +
# +: -v, --verbose=[LEVEL]
# +
# +  Set the output level (default is verbose).  (p[rogress], n[ormal],
# +  v[erbose], s[ilent])
# +
# +: --
# +
# +  Stop processing options so that the remaining options will be passed to
# +  the test.
# +
# +: -h, --help
# +
# +  Display help.
# +
# += AUTHOR
# +
# +This manpage was contributed by akira yamada <akira@debian.org>
# +
# +=end
# diff -Nru debian~/missing-sources/jquery.js debian/missing-sources/jquery.js
# --- debian~/missing-sources/jquery.js	1969-12-31 19:00:00.000000000 -0500
# +++ debian/missing-sources/jquery.js	2021-01-25 23:37:04.806005435 -0500
# @@ -0,0 +1,9046 @@
# +/*!
# + * jQuery JavaScript Library v1.6.4
# + * http://jquery.com/
# + *
# + * Copyright 2011, John Resig
# + * Dual licensed under the MIT or GPL Version 2 licenses.
# + * http://jquery.org/license
# + *
# + * Includes Sizzle.js
# + * http://sizzlejs.com/
# + * Copyright 2011, The Dojo Foundation
# + * Released under the MIT, BSD, and GPL Licenses.
# + *
# + * Date: Mon Sep 12 18:54:48 2011 -0400
# + */
# +(function( window, undefined ) {
# +
# +// Use the correct document accordingly with window argument (sandbox)
# +var document = window.document,
# +	navigator = window.navigator,
# +	location = window.location;
# +var jQuery = (function() {
# +
# +// Define a local copy of jQuery
# +var jQuery = function( selector, context ) {
# +		// The jQuery object is actually just the init constructor 'enhanced'
# +		return new jQuery.fn.init( selector, context, rootjQuery );
# +	},
# +
# +	// Map over jQuery in case of overwrite
# +	_jQuery = window.jQuery,
# +
# +	// Map over the $ in case of overwrite
# +	_$ = window.$,
# +
# +	// A central reference to the root jQuery(document)
# +	rootjQuery,
# +
# +	// A simple way to check for HTML strings or ID strings
# +	// Prioritize #id over <tag> to avoid XSS via location.hash (#9521)
# +	quickExpr = /^(?:[^#<]*(<[\w\W]+>)[^>]*$|#([\w\-]*)$)/,
# +
# +	// Check if a string has a non-whitespace character in it
# +	rnotwhite = /\S/,
# +
# +	// Used for trimming whitespace
# +	trimLeft = /^\s+/,
# +	trimRight = /\s+$/,
# +
# +	// Check for digits
# +	rdigit = /\d/,
# +
# +	// Match a standalone tag
# +	rsingleTag = /^<(\w+)\s*\/?>(?:<\/\1>)?$/,
# +
# +	// JSON RegExp
# +	rvalidchars = /^[\],:{}\s]*$/,
# +	rvalidescape = /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,
# +	rvalidtokens = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,
# +	rvalidbraces = /(?:^|:|,)(?:\s*\[)+/g,
# +
# +	// Useragent RegExp
# +	rwebkit = /(webkit)[ \/]([\w.]+)/,
# +	ropera = /(opera)(?:.*version)?[ \/]([\w.]+)/,
# +	rmsie = /(msie) ([\w.]+)/,
# +	rmozilla = /(mozilla)(?:.*? rv:([\w.]+))?/,
# +
# +	// Matches dashed string for camelizing
# +	rdashAlpha = /-([a-z]|[0-9])/ig,
# +	rmsPrefix = /^-ms-/,
# +
# +	// Used by jQuery.camelCase as callback to replace()
# +	fcamelCase = function( all, letter ) {
# +		return ( letter + "" ).toUpperCase();
# +	},
# +
# +	// Keep a UserAgent string for use with jQuery.browser
# +	userAgent = navigator.userAgent,
# +
# +	// For matching the engine and version of the browser
# +	browserMatch,
# +
# +	// The deferred used on DOM ready
# +	readyList,
# +
# +	// The ready event handler
# +	DOMContentLoaded,
# +
# +	// Save a reference to some core methods
# +	toString = Object.prototype.toString,
# +	hasOwn = Object.prototype.hasOwnProperty,
# +	push = Array.prototype.push,
# +	slice = Array.prototype.slice,
# +	trim = String.prototype.trim,
# +	indexOf = Array.prototype.indexOf,
# +
# +	// [[Class]] -> type pairs
# +	class2type = {};
# +
# +jQuery.fn = jQuery.prototype = {
# +	constructor: jQuery,
# +	init: function( selector, context, rootjQuery ) {
# +		var match, elem, ret, doc;
# +
# +		// Handle $(""), $(null), or $(undefined)
# +		if ( !selector ) {
# +			return this;
# +		}
# +
# +		// Handle $(DOMElement)
# +		if ( selector.nodeType ) {
# +			this.context = this[0] = selector;
# +			this.length = 1;
# +			return this;
# +		}
# +
# +		// The body element only exists once, optimize finding it
# +		if ( selector === "body" && !context && document.body ) {
# +			this.context = document;
# +			this[0] = document.body;
# +			this.selector = selector;
# +			this.length = 1;
# +			return this;
# +		}
# +
# +		// Handle HTML strings
# +		if ( typeof selector === "string" ) {
# +			// Are we dealing with HTML string or an ID?
# +			if ( selector.charAt(0) === "<" && selector.charAt( selector.length - 1 ) === ">" && selector.length >= 3 ) {
# +				// Assume that strings that start and end with <> are HTML and skip the regex check
# +				match = [ null, selector, null ];
# +
# +			} else {
# +				match = quickExpr.exec( selector );
# +			}
# +
# +			// Verify a match, and that no context was specified for #id
# +			if ( match && (match[1] || !context) ) {
# +
# +				// HANDLE: $(html) -> $(array)
# +				if ( match[1] ) {
# +					context = context instanceof jQuery ? context[0] : context;
# +					doc = (context ? context.ownerDocument || context : document);
# +
# +					// If a single string is passed in and it's a single tag
# +					// just do a createElement and skip the rest
# +					ret = rsingleTag.exec( selector );
# +
# +					if ( ret ) {
# +						if ( jQuery.isPlainObject( context ) ) {
# +							selector = [ document.createElement( ret[1] ) ];
# +							jQuery.fn.attr.call( selector, context, true );
# +
# +						} else {
# +							selector = [ doc.createElement( ret[1] ) ];
# +						}
# +
# +					} else {
# +						ret = jQuery.buildFragment( [ match[1] ], [ doc ] );
# +						selector = (ret.cacheable ? jQuery.clone(ret.fragment) : ret.fragment).childNodes;
# +					}
# +
# +					return jQuery.merge( this, selector );
# +
# +				// HANDLE: $("#id")
# +				} else {
# +					elem = document.getElementById( match[2] );
# +
# +					// Check parentNode to catch when Blackberry 4.6 returns
# +					// nodes that are no longer in the document #6963
# +					if ( elem && elem.parentNode ) {
# +						// Handle the case where IE and Opera return items
# +						// by name instead of ID
# +						if ( elem.id !== match[2] ) {
# +							return rootjQuery.find( selector );
# +						}
# +
# +						// Otherwise, we inject the element directly into the jQuery object
# +						this.length = 1;
# +						this[0] = elem;
# +					}
# +
# +					this.context = document;
# +					this.selector = selector;
# +					return this;
# +				}
# +
# +			// HANDLE: $(expr, $(...))
# +			} else if ( !context || context.jquery ) {
# +				return (context || rootjQuery).find( selector );
# +
# +			// HANDLE: $(expr, context)
# +			// (which is just equivalent to: $(context).find(expr)
# +			} else {
# +				return this.constructor( context ).find( selector );
# +			}
# +
# +		// HANDLE: $(function)
# +		// Shortcut for document ready
# +		} else if ( jQuery.isFunction( selector ) ) {
# +			return rootjQuery.ready( selector );
# +		}
# +
# +		if (selector.selector !== undefined) {
# +			this.selector = selector.selector;
# +			this.context = selector.context;
# +		}
# +
# +		return jQuery.makeArray( selector, this );
# +	},
# +
# +	// Start with an empty selector
# +	selector: "",
# +
# +	// The current version of jQuery being used
# +	jquery: "1.6.4",
# +
# +	// The default length of a jQuery object is 0
# +	length: 0,
# +
# +	// The number of elements contained in the matched element set
# +	size: function() {
# +		return this.length;
# +	},
# +
# +	toArray: function() {
# +		return slice.call( this, 0 );
# +	},
# +
# +	// Get the Nth element in the matched element set OR
# +	// Get the whole matched element set as a clean array
# +	get: function( num ) {
# +		return num == null ?
# +
# +			// Return a 'clean' array
# +			this.toArray() :
# +
# +			// Return just the object
# +			( num < 0 ? this[ this.length + num ] : this[ num ] );
# +	},
# +
# +	// Take an array of elements and push it onto the stack
# +	// (returning the new matched element set)
# +	pushStack: function( elems, name, selector ) {
# +		// Build a new jQuery matched element set
# +		var ret = this.constructor();
# +
# +		if ( jQuery.isArray( elems ) ) {
# +			push.apply( ret, elems );
# +
# +		} else {
# +			jQuery.merge( ret, elems );
# +		}
# +
# +		// Add the old object onto the stack (as a reference)
# +		ret.prevObject = this;
# +
# +		ret.context = this.context;
# +
# +		if ( name === "find" ) {
# +			ret.selector = this.selector + (this.selector ? " " : "") + selector;
# +		} else if ( name ) {
# +			ret.selector = this.selector + "." + name + "(" + selector + ")";
# +		}
# +
# +		// Return the newly-formed element set
# +		return ret;
# +	},
# +
# +	// Execute a callback for every element in the matched set.
# +	// (You can seed the arguments with an array of args, but this is
# +	// only used internally.)
# +	each: function( callback, args ) {
# +		return jQuery.each( this, callback, args );
# +	},
# +
# +	ready: function( fn ) {
# +		// Attach the listeners
# +		jQuery.bindReady();
# +
# +		// Add the callback
# +		readyList.done( fn );
# +
# +		return this;
# +	},
# +
# +	eq: function( i ) {
# +		return i === -1 ?
# +			this.slice( i ) :
# +			this.slice( i, +i + 1 );
# +	},
# +
# +	first: function() {
# +		return this.eq( 0 );
# +	},
# +
# +	last: function() {
# +		return this.eq( -1 );
# +	},
# +
# +	slice: function() {
# +		return this.pushStack( slice.apply( this, arguments ),
# +			"slice", slice.call(arguments).join(",") );
# +	},
# +
# +	map: function( callback ) {
# +		return this.pushStack( jQuery.map(this, function( elem, i ) {
# +			return callback.call( elem, i, elem );
# +		}));
# +	},
# +
# +	end: function() {
# +		return this.prevObject || this.constructor(null);
# +	},
# +
# +	// For internal use only.
# +	// Behaves like an Array's method, not like a jQuery method.
# +	push: push,
# +	sort: [].sort,
# +	splice: [].splice
# +};
# +
# +// Give the init function the jQuery prototype for later instantiation
# +jQuery.fn.init.prototype = jQuery.fn;
# +
# +jQuery.extend = jQuery.fn.extend = function() {
# +	var options, name, src, copy, copyIsArray, clone,
# +		target = arguments[0] || {},
# +		i = 1,
# +		length = arguments.length,
# +		deep = false;
# +
# +	// Handle a deep copy situation
# +	if ( typeof target === "boolean" ) {
# +		deep = target;
# +		target = arguments[1] || {};
# +		// skip the boolean and the target
# +		i = 2;
# +	}
# +
# +	// Handle case when target is a string or something (possible in deep copy)
# +	if ( typeof target !== "object" && !jQuery.isFunction(target) ) {
# +		target = {};
# +	}
# +
# +	// extend jQuery itself if only one argument is passed
# +	if ( length === i ) {
# +		target = this;
# +		--i;
# +	}
# +
# +	for ( ; i < length; i++ ) {
# +		// Only deal with non-null/undefined values
# +		if ( (options = arguments[ i ]) != null ) {
# +			// Extend the base object
# +			for ( name in options ) {
# +				src = target[ name ];
# +				copy = options[ name ];
# +
# +				// Prevent never-ending loop
# +				if ( target === copy ) {
# +					continue;
# +				}
# +
# +				// Recurse if we're merging plain objects or arrays
# +				if ( deep && copy && ( jQuery.isPlainObject(copy) || (copyIsArray = jQuery.isArray(copy)) ) ) {
# +					if ( copyIsArray ) {
# +						copyIsArray = false;
# +						clone = src && jQuery.isArray(src) ? src : [];
# +
# +					} else {
# +						clone = src && jQuery.isPlainObject(src) ? src : {};
# +					}
# +
# +					// Never move original objects, clone them
# +					target[ name ] = jQuery.extend( deep, clone, copy );
# +
# +				// Don't bring in undefined values
# +				} else if ( copy !== undefined ) {
# +					target[ name ] = copy;
# +				}
# +			}
# +		}
# +	}
# +
# +	// Return the modified object
# +	return target;
# +};
# +
# +jQuery.extend({
# +	noConflict: function( deep ) {
# +		if ( window.$ === jQuery ) {
# +			window.$ = _$;
# +		}
# +
# +		if ( deep && window.jQuery === jQuery ) {
# +			window.jQuery = _jQuery;
# +		}
# +
# +		return jQuery;
# +	},
# +
# +	// Is the DOM ready to be used? Set to true once it occurs.
# +	isReady: false,
# +
# +	// A counter to track how many items to wait for before
# +	// the ready event fires. See #6781
# +	readyWait: 1,
# +
# +	// Hold (or release) the ready event
# +	holdReady: function( hold ) {
# +		if ( hold ) {
# +			jQuery.readyWait++;
# +		} else {
# +			jQuery.ready( true );
# +		}
# +	},
# +
# +	// Handle when the DOM is ready
# +	ready: function( wait ) {
# +		// Either a released hold or an DOMready/load event and not yet ready
# +		if ( (wait === true && !--jQuery.readyWait) || (wait !== true && !jQuery.isReady) ) {
# +			// Make sure body exists, at least, in case IE gets a little overzealous (ticket #5443).
# +			if ( !document.body ) {
# +				return setTimeout( jQuery.ready, 1 );
# +			}
# +
# +			// Remember that the DOM is ready
# +			jQuery.isReady = true;
# +
# +			// If a normal DOM Ready event fired, decrement, and wait if need be
# +			if ( wait !== true && --jQuery.readyWait > 0 ) {
# +				return;
# +			}
# +
# +			// If there are functions bound, to execute
# +			readyList.resolveWith( document, [ jQuery ] );
# +
# +			// Trigger any bound ready events
# +			if ( jQuery.fn.trigger ) {
# +				jQuery( document ).trigger( "ready" ).unbind( "ready" );
# +			}
# +		}
# +	},
# +
# +	bindReady: function() {
# +		if ( readyList ) {
# +			return;
# +		}
# +
# +		readyList = jQuery._Deferred();
# +
# +		// Catch cases where $(document).ready() is called after the
# +		// browser event has already occurred.
# +		if ( document.readyState === "complete" ) {
# +			// Handle it asynchronously to allow scripts the opportunity to delay ready
# +			return setTimeout( jQuery.ready, 1 );
# +		}
# +
# +		// Mozilla, Opera and webkit nightlies currently support this event
# +		if ( document.addEventListener ) {
# +			// Use the handy event callback
# +			document.addEventListener( "DOMContentLoaded", DOMContentLoaded, false );
# +
# +			// A fallback to window.onload, that will always work
# +			window.addEventListener( "load", jQuery.ready, false );
# +
# +		// If IE event model is used
# +		} else if ( document.attachEvent ) {
# +			// ensure firing before onload,
# +			// maybe late but safe also for iframes
# +			document.attachEvent( "onreadystatechange", DOMContentLoaded );
# +
# +			// A fallback to window.onload, that will always work
# +			window.attachEvent( "onload", jQuery.ready );
# +
# +			// If IE and not a frame
# +			// continually check to see if the document is ready
# +			var toplevel = false;
# +
# +			try {
# +				toplevel = window.frameElement == null;
# +			} catch(e) {}
# +
# +			if ( document.documentElement.doScroll && toplevel ) {
# +				doScrollCheck();
# +			}
# +		}
# +	},
# +
# +	// See test/unit/core.js for details concerning isFunction.
# +	// Since version 1.3, DOM methods and functions like alert
# +	// aren't supported. They return false on IE (#2968).
# +	isFunction: function( obj ) {
# +		return jQuery.type(obj) === "function";
# +	},
# +
# +	isArray: Array.isArray || function( obj ) {
# +		return jQuery.type(obj) === "array";
# +	},
# +
# +	// A crude way of determining if an object is a window
# +	isWindow: function( obj ) {
# +		return obj && typeof obj === "object" && "setInterval" in obj;
# +	},
# +
# +	isNaN: function( obj ) {
# +		return obj == null || !rdigit.test( obj ) || isNaN( obj );
# +	},
# +
# +	type: function( obj ) {
# +		return obj == null ?
# +			String( obj ) :
# +			class2type[ toString.call(obj) ] || "object";
# +	},
# +
# +	isPlainObject: function( obj ) {
# +		// Must be an Object.
# +		// Because of IE, we also have to check the presence of the constructor property.
# +		// Make sure that DOM nodes and window objects don't pass through, as well
# +		if ( !obj || jQuery.type(obj) !== "object" || obj.nodeType || jQuery.isWindow( obj ) ) {
# +			return false;
# +		}
# +
# +		try {
# +			// Not own constructor property must be Object
# +			if ( obj.constructor &&
# +				!hasOwn.call(obj, "constructor") &&
# +				!hasOwn.call(obj.constructor.prototype, "isPrototypeOf") ) {
# +				return false;
# +			}
# +		} catch ( e ) {
# +			// IE8,9 Will throw exceptions on certain host objects #9897
# +			return false;
# +		}
# +
# +		// Own properties are enumerated firstly, so to speed up,
# +		// if last one is own, then all properties are own.
# +
# +		var key;
# +		for ( key in obj ) {}
# +
# +		return key === undefined || hasOwn.call( obj, key );
# +	},
# +
# +	isEmptyObject: function( obj ) {
# +		for ( var name in obj ) {
# +			return false;
# +		}
# +		return true;
# +	},
# +
# +	error: function( msg ) {
# +		throw msg;
# +	},
# +
# +	parseJSON: function( data ) {
# +		if ( typeof data !== "string" || !data ) {
# +			return null;
# +		}
# +
# +		// Make sure leading/trailing whitespace is removed (IE can't handle it)
# +		data = jQuery.trim( data );
# +
# +		// Attempt to parse using the native JSON parser first
# +		if ( window.JSON && window.JSON.parse ) {
# +			return window.JSON.parse( data );
# +		}
# +
# +		// Make sure the incoming data is actual JSON
# +		// Logic borrowed from http://json.org/json2.js
# +		if ( rvalidchars.test( data.replace( rvalidescape, "@" )
# +			.replace( rvalidtokens, "]" )
# +			.replace( rvalidbraces, "")) ) {
# +
# +			return (new Function( "return " + data ))();
# +
# +		}
# +		jQuery.error( "Invalid JSON: " + data );
# +	},
# +
# +	// Cross-browser xml parsing
# +	parseXML: function( data ) {
# +		var xml, tmp;
# +		try {
# +			if ( window.DOMParser ) { // Standard
# +				tmp = new DOMParser();
# +				xml = tmp.parseFromString( data , "text/xml" );
# +			} else { // IE
# +				xml = new ActiveXObject( "Microsoft.XMLDOM" );
# +				xml.async = "false";
# +				xml.loadXML( data );
# +			}
# +		} catch( e ) {
# +			xml = undefined;
# +		}
# +		if ( !xml || !xml.documentElement || xml.getElementsByTagName( "parsererror" ).length ) {
# +			jQuery.error( "Invalid XML: " + data );
# +		}
# +		return xml;
# +	},
# +
# +	noop: function() {},
# +
# +	// Evaluates a script in a global context
# +	// Workarounds based on findings by Jim Driscoll
# +	// http://weblogs.java.net/blog/driscoll/archive/2009/09/08/eval-javascript-global-context
# +	globalEval: function( data ) {
# +		if ( data && rnotwhite.test( data ) ) {
# +			// We use execScript on Internet Explorer
# +			// We use an anonymous function so that context is window
# +			// rather than jQuery in Firefox
# +			( window.execScript || function( data ) {
# +				window[ "eval" ].call( window, data );
# +			} )( data );
# +		}
# +	},
# +
# +	// Convert dashed to camelCase; used by the css and data modules
# +	// Microsoft forgot to hump their vendor prefix (#9572)
# +	camelCase: function( string ) {
# +		return string.replace( rmsPrefix, "ms-" ).replace( rdashAlpha, fcamelCase );
# +	},
# +
# +	nodeName: function( elem, name ) {
# +		return elem.nodeName && elem.nodeName.toUpperCase() === name.toUpperCase();
# +	},
# +
# +	// args is for internal usage only
# +	each: function( object, callback, args ) {
# +		var name, i = 0,
# +			length = object.length,
# +			isObj = length === undefined || jQuery.isFunction( object );
# +
# +		if ( args ) {
# +			if ( isObj ) {
# +				for ( name in object ) {
# +					if ( callback.apply( object[ name ], args ) === false ) {
# +						break;
# +					}
# +				}
# +			} else {
# +				for ( ; i < length; ) {
# +					if ( callback.apply( object[ i++ ], args ) === false ) {
# +						break;
# +					}
# +				}
# +			}
# +
# +		// A special, fast, case for the most common use of each
# +		} else {
# +			if ( isObj ) {
# +				for ( name in object ) {
# +					if ( callback.call( object[ name ], name, object[ name ] ) === false ) {
# +						break;
# +					}
# +				}
# +			} else {
# +				for ( ; i < length; ) {
# +					if ( callback.call( object[ i ], i, object[ i++ ] ) === false ) {
# +						break;
# +					}
# +				}
# +			}
# +		}
# +
# +		return object;
# +	},
# +
# +	// Use native String.trim function wherever possible
# +	trim: trim ?
# +		function( text ) {
# +			return text == null ?
# +				"" :
# +				trim.call( text );
# +		} :
# +
# +		// Otherwise use our own trimming functionality
# +		function( text ) {
# +			return text == null ?
# +				"" :
# +				text.toString().replace( trimLeft, "" ).replace( trimRight, "" );
# +		},
# +
# +	// results is for internal usage only
# +	makeArray: function( array, results ) {
# +		var ret = results || [];
# +
# +		if ( array != null ) {
# +			// The window, strings (and functions) also have 'length'
# +			// The extra typeof function check is to prevent crashes
# +			// in Safari 2 (See: #3039)
# +			// Tweaked logic slightly to handle Blackberry 4.7 RegExp issues #6930
# +			var type = jQuery.type( array );
# +
# +			if ( array.length == null || type === "string" || type === "function" || type === "regexp" || jQuery.isWindow( array ) ) {
# +				push.call( ret, array );
# +			} else {
# +				jQuery.merge( ret, array );
# +			}
# +		}
# +
# +		return ret;
# +	},
# +
# +	inArray: function( elem, array ) {
# +		if ( !array ) {
# +			return -1;
# +		}
# +
# +		if ( indexOf ) {
# +			return indexOf.call( array, elem );
# +		}
# +
# +		for ( var i = 0, length = array.length; i < length; i++ ) {
# +			if ( array[ i ] === elem ) {
# +				return i;
# +			}
# +		}
# +
# +		return -1;
# +	},
# +
# +	merge: function( first, second ) {
# +		var i = first.length,
# +			j = 0;
# +
# +		if ( typeof second.length === "number" ) {
# +			for ( var l = second.length; j < l; j++ ) {
# +				first[ i++ ] = second[ j ];
# +			}
# +
# +		} else {
# +			while ( second[j] !== undefined ) {
# +				first[ i++ ] = second[ j++ ];
# +			}
# +		}
# +
# +		first.length = i;
# +
# +		return first;
# +	},
# +
# +	grep: function( elems, callback, inv ) {
# +		var ret = [], retVal;
# +		inv = !!inv;
# +
# +		// Go through the array, only saving the items
# +		// that pass the validator function
# +		for ( var i = 0, length = elems.length; i < length; i++ ) {
# +			retVal = !!callback( elems[ i ], i );
# +			if ( inv !== retVal ) {
# +				ret.push( elems[ i ] );
# +			}
# +		}
# +
# +		return ret;
# +	},
# +
# +	// arg is for internal usage only
# +	map: function( elems, callback, arg ) {
# +		var value, key, ret = [],
# +			i = 0,
# +			length = elems.length,
# +			// jquery objects are treated as arrays
# +			isArray = elems instanceof jQuery || length !== undefined && typeof length === "number" && ( ( length > 0 && elems[ 0 ] && elems[ length -1 ] ) || length === 0 || jQuery.isArray( elems ) ) ;
# +
# +		// Go through the array, translating each of the items to their
# +		if ( isArray ) {
# +			for ( ; i < length; i++ ) {
# +				value = callback( elems[ i ], i, arg );
# +
# +				if ( value != null ) {
# +					ret[ ret.length ] = value;
# +				}
# +			}
# +
# +		// Go through every key on the object,
# +		} else {
# +			for ( key in elems ) {
# +				value = callback( elems[ key ], key, arg );
# +
# +				if ( value != null ) {
# +					ret[ ret.length ] = value;
# +				}
# +			}
# +		}
# +
# +		// Flatten any nested arrays
# +		return ret.concat.apply( [], ret );
# +	},
# +
# +	// A global GUID counter for objects
# +	guid: 1,
# +
# +	// Bind a function to a context, optionally partially applying any
# +	// arguments.
# +	proxy: function( fn, context ) {
# +		if ( typeof context === "string" ) {
# +			var tmp = fn[ context ];
# +			context = fn;
# +			fn = tmp;
# +		}
# +
# +		// Quick check to determine if target is callable, in the spec
# +		// this throws a TypeError, but we will just return undefined.
# +		if ( !jQuery.isFunction( fn ) ) {
# +			return undefined;
# +		}
# +
# +		// Simulated bind
# +		var args = slice.call( arguments, 2 ),
# +			proxy = function() {
# +				return fn.apply( context, args.concat( slice.call( arguments ) ) );
# +			};
# +
# +		// Set the guid of unique handler to the same of original handler, so it can be removed
# +		proxy.guid = fn.guid = fn.guid || proxy.guid || jQuery.guid++;
# +
# +		return proxy;
# +	},
# +
# +	// Mutifunctional method to get and set values to a collection
# +	// The value/s can optionally be executed if it's a function
# +	access: function( elems, key, value, exec, fn, pass ) {
# +		var length = elems.length;
# +
# +		// Setting many attributes
# +		if ( typeof key === "object" ) {
# +			for ( var k in key ) {
# +				jQuery.access( elems, k, key[k], exec, fn, value );
# +			}
# +			return elems;
# +		}
# +
# +		// Setting one attribute
# +		if ( value !== undefined ) {
# +			// Optionally, function values get executed if exec is true
# +			exec = !pass && exec && jQuery.isFunction(value);
# +
# +			for ( var i = 0; i < length; i++ ) {
# +				fn( elems[i], key, exec ? value.call( elems[i], i, fn( elems[i], key ) ) : value, pass );
# +			}
# +
# +			return elems;
# +		}
# +
# +		// Getting an attribute
# +		return length ? fn( elems[0], key ) : undefined;
# +	},
# +
# +	now: function() {
# +		return (new Date()).getTime();
# +	},
# +
# +	// Use of jQuery.browser is frowned upon.
# +	// More details: http://docs.jquery.com/Utilities/jQuery.browser
# +	uaMatch: function( ua ) {
# +		ua = ua.toLowerCase();
# +
# +		var match = rwebkit.exec( ua ) ||
# +			ropera.exec( ua ) ||
# +			rmsie.exec( ua ) ||
# +			ua.indexOf("compatible") < 0 && rmozilla.exec( ua ) ||
# +			[];
# +
# +		return { browser: match[1] || "", version: match[2] || "0" };
# +	},
# +
# +	sub: function() {
# +		function jQuerySub( selector, context ) {
# +			return new jQuerySub.fn.init( selector, context );
# +		}
# +		jQuery.extend( true, jQuerySub, this );
# +		jQuerySub.superclass = this;
# +		jQuerySub.fn = jQuerySub.prototype = this();
# +		jQuerySub.fn.constructor = jQuerySub;
# +		jQuerySub.sub = this.sub;
# +		jQuerySub.fn.init = function init( selector, context ) {
# +			if ( context && context instanceof jQuery && !(context instanceof jQuerySub) ) {
# +				context = jQuerySub( context );
# +			}
# +
# +			return jQuery.fn.init.call( this, selector, context, rootjQuerySub );
# +		};
# +		jQuerySub.fn.init.prototype = jQuerySub.fn;
# +		var rootjQuerySub = jQuerySub(document);
# +		return jQuerySub;
# +	},
# +
# +	browser: {}
# +});
# +
# +// Populate the class2type map
# +jQuery.each("Boolean Number String Function Array Date RegExp Object".split(" "), function(i, name) {
# +	class2type[ "[object " + name + "]" ] = name.toLowerCase();
# +});
# +
# +browserMatch = jQuery.uaMatch( userAgent );
# +if ( browserMatch.browser ) {
# +	jQuery.browser[ browserMatch.browser ] = true;
# +	jQuery.browser.version = browserMatch.version;
# +}
# +
# +// Deprecated, use jQuery.browser.webkit instead
# +if ( jQuery.browser.webkit ) {
# +	jQuery.browser.safari = true;
# +}
# +
# +// IE doesn't match non-breaking spaces with \s
# +if ( rnotwhite.test( "\xA0" ) ) {
# +	trimLeft = /^[\s\xA0]+/;
# +	trimRight = /[\s\xA0]+$/;
# +}
# +
# +// All jQuery objects should point back to these
# +rootjQuery = jQuery(document);
# +
# +// Cleanup functions for the document ready method
# +if ( document.addEventListener ) {
# +	DOMContentLoaded = function() {
# +		document.removeEventListener( "DOMContentLoaded", DOMContentLoaded, false );
# +		jQuery.ready();
# +	};
# +
# +} else if ( document.attachEvent ) {
# +	DOMContentLoaded = function() {
# +		// Make sure body exists, at least, in case IE gets a little overzealous (ticket #5443).
# +		if ( document.readyState === "complete" ) {
# +			document.detachEvent( "onreadystatechange", DOMContentLoaded );
# +			jQuery.ready();
# +		}
# +	};
# +}
# +
# +// The DOM ready check for Internet Explorer
# +function doScrollCheck() {
# +	if ( jQuery.isReady ) {
# +		return;
# +	}
# +
# +	try {
# +		// If IE is used, use the trick by Diego Perini
# +		// http://javascript.nwbox.com/IEContentLoaded/
# +		document.documentElement.doScroll("left");
# +	} catch(e) {
# +		setTimeout( doScrollCheck, 1 );
# +		return;
# +	}
# +
# +	// and execute any waiting functions
# +	jQuery.ready();
# +}
# +
# +return jQuery;
# +
# +})();
# +
# +
# +var // Promise methods
# +	promiseMethods = "done fail isResolved isRejected promise then always pipe".split( " " ),
# +	// Static reference to slice
# +	sliceDeferred = [].slice;
# +
# +jQuery.extend({
# +	// Create a simple deferred (one callbacks list)
# +	_Deferred: function() {
# +		var // callbacks list
# +			callbacks = [],
# +			// stored [ context , args ]
# +			fired,
# +			// to avoid firing when already doing so
# +			firing,
# +			// flag to know if the deferred has been cancelled
# +			cancelled,
# +			// the deferred itself
# +			deferred  = {
# +
# +				// done( f1, f2, ...)
# +				done: function() {
# +					if ( !cancelled ) {
# +						var args = arguments,
# +							i,
# +							length,
# +							elem,
# +							type,
# +							_fired;
# +						if ( fired ) {
# +							_fired = fired;
# +							fired = 0;
# +						}
# +						for ( i = 0, length = args.length; i < length; i++ ) {
# +							elem = args[ i ];
# +							type = jQuery.type( elem );
# +							if ( type === "array" ) {
# +								deferred.done.apply( deferred, elem );
# +							} else if ( type === "function" ) {
# +								callbacks.push( elem );
# +							}
# +						}
# +						if ( _fired ) {
# +							deferred.resolveWith( _fired[ 0 ], _fired[ 1 ] );
# +						}
# +					}
# +					return this;
# +				},
# +
# +				// resolve with given context and args
# +				resolveWith: function( context, args ) {
# +					if ( !cancelled && !fired && !firing ) {
# +						// make sure args are available (#8421)
# +						args = args || [];
# +						firing = 1;
# +						try {
# +							while( callbacks[ 0 ] ) {
# +								callbacks.shift().apply( context, args );
# +							}
# +						}
# +						finally {
# +							fired = [ context, args ];
# +							firing = 0;
# +						}
# +					}
# +					return this;
# +				},
# +
# +				// resolve with this as context and given arguments
# +				resolve: function() {
# +					deferred.resolveWith( this, arguments );
# +					return this;
# +				},
# +
# +				// Has this deferred been resolved?
# +				isResolved: function() {
# +					return !!( firing || fired );
# +				},
# +
# +				// Cancel
# +				cancel: function() {
# +					cancelled = 1;
# +					callbacks = [];
# +					return this;
# +				}
# +			};
# +
# +		return deferred;
# +	},
# +
# +	// Full fledged deferred (two callbacks list)
# +	Deferred: function( func ) {
# +		var deferred = jQuery._Deferred(),
# +			failDeferred = jQuery._Deferred(),
# +			promise;
# +		// Add errorDeferred methods, then and promise
# +		jQuery.extend( deferred, {
# +			then: function( doneCallbacks, failCallbacks ) {
# +				deferred.done( doneCallbacks ).fail( failCallbacks );
# +				return this;
# +			},
# +			always: function() {
# +				return deferred.done.apply( deferred, arguments ).fail.apply( this, arguments );
# +			},
# +			fail: failDeferred.done,
# +			rejectWith: failDeferred.resolveWith,
# +			reject: failDeferred.resolve,
# +			isRejected: failDeferred.isResolved,
# +			pipe: function( fnDone, fnFail ) {
# +				return jQuery.Deferred(function( newDefer ) {
# +					jQuery.each( {
# +						done: [ fnDone, "resolve" ],
# +						fail: [ fnFail, "reject" ]
# +					}, function( handler, data ) {
# +						var fn = data[ 0 ],
# +							action = data[ 1 ],
# +							returned;
# +						if ( jQuery.isFunction( fn ) ) {
# +							deferred[ handler ](function() {
# +								returned = fn.apply( this, arguments );
# +								if ( returned && jQuery.isFunction( returned.promise ) ) {
# +									returned.promise().then( newDefer.resolve, newDefer.reject );
# +								} else {
# +									newDefer[ action + "With" ]( this === deferred ? newDefer : this, [ returned ] );
# +								}
# +							});
# +						} else {
# +							deferred[ handler ]( newDefer[ action ] );
# +						}
# +					});
# +				}).promise();
# +			},
# +			// Get a promise for this deferred
# +			// If obj is provided, the promise aspect is added to the object
# +			promise: function( obj ) {
# +				if ( obj == null ) {
# +					if ( promise ) {
# +						return promise;
# +					}
# +					promise = obj = {};
# +				}
# +				var i = promiseMethods.length;
# +				while( i-- ) {
# +					obj[ promiseMethods[i] ] = deferred[ promiseMethods[i] ];
# +				}
# +				return obj;
# +			}
# +		});
# +		// Make sure only one callback list will be used
# +		deferred.done( failDeferred.cancel ).fail( deferred.cancel );
# +		// Unexpose cancel
# +		delete deferred.cancel;
# +		// Call given func if any
# +		if ( func ) {
# +			func.call( deferred, deferred );
# +		}
# +		return deferred;
# +	},
# +
# +	// Deferred helper
# +	when: function( firstParam ) {
# +		var args = arguments,
# +			i = 0,
# +			length = args.length,
# +			count = length,
# +			deferred = length <= 1 && firstParam && jQuery.isFunction( firstParam.promise ) ?
# +				firstParam :
# +				jQuery.Deferred();
# +		function resolveFunc( i ) {
# +			return function( value ) {
# +				args[ i ] = arguments.length > 1 ? sliceDeferred.call( arguments, 0 ) : value;
# +				if ( !( --count ) ) {
# +					// Strange bug in FF4:
# +					// Values changed onto the arguments object sometimes end up as undefined values
# +					// outside the $.when method. Cloning the object into a fresh array solves the issue
# +					deferred.resolveWith( deferred, sliceDeferred.call( args, 0 ) );
# +				}
# +			};
# +		}
# +		if ( length > 1 ) {
# +			for( ; i < length; i++ ) {
# +				if ( args[ i ] && jQuery.isFunction( args[ i ].promise ) ) {
# +					args[ i ].promise().then( resolveFunc(i), deferred.reject );
# +				} else {
# +					--count;
# +				}
# +			}
# +			if ( !count ) {
# +				deferred.resolveWith( deferred, args );
# +			}
# +		} else if ( deferred !== firstParam ) {
# +			deferred.resolveWith( deferred, length ? [ firstParam ] : [] );
# +		}
# +		return deferred.promise();
# +	}
# +});
# +
# +
# +
# +jQuery.support = (function() {
# +
# +	var div = document.createElement( "div" ),
# +		documentElement = document.documentElement,
# +		all,
# +		a,
# +		select,
# +		opt,
# +		input,
# +		marginDiv,
# +		support,
# +		fragment,
# +		body,
# +		testElementParent,
# +		testElement,
# +		testElementStyle,
# +		tds,
# +		events,
# +		eventName,
# +		i,
# +		isSupported;
# +
# +	// Preliminary tests
# +	div.setAttribute("className", "t");
# +	div.innerHTML = "   <link/><table></table><a href='/a' style='top:1px;float:left;opacity:.55;'>a</a><input type='checkbox'/>";
# +
# +
# +	all = div.getElementsByTagName( "*" );
# +	a = div.getElementsByTagName( "a" )[ 0 ];
# +
# +	// Can't get basic test support
# +	if ( !all || !all.length || !a ) {
# +		return {};
# +	}
# +
# +	// First batch of supports tests
# +	select = document.createElement( "select" );
# +	opt = select.appendChild( document.createElement("option") );
# +	input = div.getElementsByTagName( "input" )[ 0 ];
# +
# +	support = {
# +		// IE strips leading whitespace when .innerHTML is used
# +		leadingWhitespace: ( div.firstChild.nodeType === 3 ),
# +
# +		// Make sure that tbody elements aren't automatically inserted
# +		// IE will insert them into empty tables
# +		tbody: !div.getElementsByTagName( "tbody" ).length,
# +
# +		// Make sure that link elements get serialized correctly by innerHTML
# +		// This requires a wrapper element in IE
# +		htmlSerialize: !!div.getElementsByTagName( "link" ).length,
# +
# +		// Get the style information from getAttribute
# +		// (IE uses .cssText instead)
# +		style: /top/.test( a.getAttribute("style") ),
# +
# +		// Make sure that URLs aren't manipulated
# +		// (IE normalizes it by default)
# +		hrefNormalized: ( a.getAttribute( "href" ) === "/a" ),
# +
# +		// Make sure that element opacity exists
# +		// (IE uses filter instead)
# +		// Use a regex to work around a WebKit issue. See #5145
# +		opacity: /^0.55$/.test( a.style.opacity ),
# +
# +		// Verify style float existence
# +		// (IE uses styleFloat instead of cssFloat)
# +		cssFloat: !!a.style.cssFloat,
# +
# +		// Make sure that if no value is specified for a checkbox
# +		// that it defaults to "on".
# +		// (WebKit defaults to "" instead)
# +		checkOn: ( input.value === "on" ),
# +
# +		// Make sure that a selected-by-default option has a working selected property.
# +		// (WebKit defaults to false instead of true, IE too, if it's in an optgroup)
# +		optSelected: opt.selected,
# +
# +		// Test setAttribute on camelCase class. If it works, we need attrFixes when doing get/setAttribute (ie6/7)
# +		getSetAttribute: div.className !== "t",
# +
# +		// Will be defined later
# +		submitBubbles: true,
# +		changeBubbles: true,
# +		focusinBubbles: false,
# +		deleteExpando: true,
# +		noCloneEvent: true,
# +		inlineBlockNeedsLayout: false,
# +		shrinkWrapBlocks: false,
# +		reliableMarginRight: true
# +	};
# +
# +	// Make sure checked status is properly cloned
# +	input.checked = true;
# +	support.noCloneChecked = input.cloneNode( true ).checked;
# +
# +	// Make sure that the options inside disabled selects aren't marked as disabled
# +	// (WebKit marks them as disabled)
# +	select.disabled = true;
# +	support.optDisabled = !opt.disabled;
# +
# +	// Test to see if it's possible to delete an expando from an element
# +	// Fails in Internet Explorer
# +	try {
# +		delete div.test;
# +	} catch( e ) {
# +		support.deleteExpando = false;
# +	}
# +
# +	if ( !div.addEventListener && div.attachEvent && div.fireEvent ) {
# +		div.attachEvent( "onclick", function() {
# +			// Cloning a node shouldn't copy over any
# +			// bound event handlers (IE does this)
# +			support.noCloneEvent = false;
# +		});
# +		div.cloneNode( true ).fireEvent( "onclick" );
# +	}
# +
# +	// Check if a radio maintains it's value
# +	// after being appended to the DOM
# +	input = document.createElement("input");
# +	input.value = "t";
# +	input.setAttribute("type", "radio");
# +	support.radioValue = input.value === "t";
# +
# +	input.setAttribute("checked", "checked");
# +	div.appendChild( input );
# +	fragment = document.createDocumentFragment();
# +	fragment.appendChild( div.firstChild );
# +
# +	// WebKit doesn't clone checked state correctly in fragments
# +	support.checkClone = fragment.cloneNode( true ).cloneNode( true ).lastChild.checked;
# +
# +	div.innerHTML = "";
# +
# +	// Figure out if the W3C box model works as expected
# +	div.style.width = div.style.paddingLeft = "1px";
# +
# +	body = document.getElementsByTagName( "body" )[ 0 ];
# +	// We use our own, invisible, body unless the body is already present
# +	// in which case we use a div (#9239)
# +	testElement = document.createElement( body ? "div" : "body" );
# +	testElementStyle = {
# +		visibility: "hidden",
# +		width: 0,
# +		height: 0,
# +		border: 0,
# +		margin: 0,
# +		background: "none"
# +	};
# +	if ( body ) {
# +		jQuery.extend( testElementStyle, {
# +			position: "absolute",
# +			left: "-1000px",
# +			top: "-1000px"
# +		});
# +	}
# +	for ( i in testElementStyle ) {
# +		testElement.style[ i ] = testElementStyle[ i ];
# +	}
# +	testElement.appendChild( div );
# +	testElementParent = body || documentElement;
# +	testElementParent.insertBefore( testElement, testElementParent.firstChild );
# +
# +	// Check if a disconnected checkbox will retain its checked
# +	// value of true after appended to the DOM (IE6/7)
# +	support.appendChecked = input.checked;
# +
# +	support.boxModel = div.offsetWidth === 2;
# +
# +	if ( "zoom" in div.style ) {
# +		// Check if natively block-level elements act like inline-block
# +		// elements when setting their display to 'inline' and giving
# +		// them layout
# +		// (IE < 8 does this)
# +		div.style.display = "inline";
# +		div.style.zoom = 1;
# +		support.inlineBlockNeedsLayout = ( div.offsetWidth === 2 );
# +
# +		// Check if elements with layout shrink-wrap their children
# +		// (IE 6 does this)
# +		div.style.display = "";
# +		div.innerHTML = "<div style='width:4px;'></div>";
# +		support.shrinkWrapBlocks = ( div.offsetWidth !== 2 );
# +	}
# +
# +	div.innerHTML = "<table><tr><td style='padding:0;border:0;display:none'></td><td>t</td></tr></table>";
# +	tds = div.getElementsByTagName( "td" );
# +
# +	// Check if table cells still have offsetWidth/Height when they are set
# +	// to display:none and there are still other visible table cells in a
# +	// table row; if so, offsetWidth/Height are not reliable for use when
# +	// determining if an element has been hidden directly using
# +	// display:none (it is still safe to use offsets if a parent element is
# +	// hidden; don safety goggles and see bug #4512 for more information).
# +	// (only IE 8 fails this test)
# +	isSupported = ( tds[ 0 ].offsetHeight === 0 );
# +
# +	tds[ 0 ].style.display = "";
# +	tds[ 1 ].style.display = "none";
# +
# +	// Check if empty table cells still have offsetWidth/Height
# +	// (IE < 8 fail this test)
# +	support.reliableHiddenOffsets = isSupported && ( tds[ 0 ].offsetHeight === 0 );
# +	div.innerHTML = "";
# +
# +	// Check if div with explicit width and no margin-right incorrectly
# +	// gets computed margin-right based on width of container. For more
# +	// info see bug #3333
# +	// Fails in WebKit before Feb 2011 nightlies
# +	// WebKit Bug 13343 - getComputedStyle returns wrong value for margin-right
# +	if ( document.defaultView && document.defaultView.getComputedStyle ) {
# +		marginDiv = document.createElement( "div" );
# +		marginDiv.style.width = "0";
# +		marginDiv.style.marginRight = "0";
# +		div.appendChild( marginDiv );
# +		support.reliableMarginRight =
# +			( parseInt( ( document.defaultView.getComputedStyle( marginDiv, null ) || { marginRight: 0 } ).marginRight, 10 ) || 0 ) === 0;
# +	}
# +
# +	// Remove the body element we added
# +	testElement.innerHTML = "";
# +	testElementParent.removeChild( testElement );
# +
# +	// Technique from Juriy Zaytsev
# +	// http://thinkweb2.com/projects/prototype/detecting-event-support-without-browser-sniffing/
# +	// We only care about the case where non-standard event systems
# +	// are used, namely in IE. Short-circuiting here helps us to
# +	// avoid an eval call (in setAttribute) which can cause CSP
# +	// to go haywire. See: https://developer.mozilla.org/en/Security/CSP
# +	if ( div.attachEvent ) {
# +		for( i in {
# +			submit: 1,
# +			change: 1,
# +			focusin: 1
# +		} ) {
# +			eventName = "on" + i;
# +			isSupported = ( eventName in div );
# +			if ( !isSupported ) {
# +				div.setAttribute( eventName, "return;" );
# +				isSupported = ( typeof div[ eventName ] === "function" );
# +			}
# +			support[ i + "Bubbles" ] = isSupported;
# +		}
# +	}
# +
# +	// Null connected elements to avoid leaks in IE
# +	testElement = fragment = select = opt = body = marginDiv = div = input = null;
# +
# +	return support;
# +})();
# +
# +// Keep track of boxModel
# +jQuery.boxModel = jQuery.support.boxModel;
# +
# +
# +
# +
# +var rbrace = /^(?:\{.*\}|\[.*\])$/,
# +	rmultiDash = /([A-Z])/g;
# +
# +jQuery.extend({
# +	cache: {},
# +
# +	// Please use with caution
# +	uuid: 0,
# +
# +	// Unique for each copy of jQuery on the page
# +	// Non-digits removed to match rinlinejQuery
# +	expando: "jQuery" + ( jQuery.fn.jquery + Math.random() ).replace( /\D/g, "" ),
# +
# +	// The following elements throw uncatchable exceptions if you
# +	// attempt to add expando properties to them.
# +	noData: {
# +		"embed": true,
# +		// Ban all objects except for Flash (which handle expandos)
# +		"object": "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000",
# +		"applet": true
# +	},
# +
# +	hasData: function( elem ) {
# +		elem = elem.nodeType ? jQuery.cache[ elem[jQuery.expando] ] : elem[ jQuery.expando ];
# +
# +		return !!elem && !isEmptyDataObject( elem );
# +	},
# +
# +	data: function( elem, name, data, pvt /* Internal Use Only */ ) {
# +		if ( !jQuery.acceptData( elem ) ) {
# +			return;
# +		}
# +
# +		var thisCache, ret,
# +			internalKey = jQuery.expando,
# +			getByName = typeof name === "string",
# +
# +			// We have to handle DOM nodes and JS objects differently because IE6-7
# +			// can't GC object references properly across the DOM-JS boundary
# +			isNode = elem.nodeType,
# +
# +			// Only DOM nodes need the global jQuery cache; JS object data is
# +			// attached directly to the object so GC can occur automatically
# +			cache = isNode ? jQuery.cache : elem,
# +
# +			// Only defining an ID for JS objects if its cache already exists allows
# +			// the code to shortcut on the same path as a DOM node with no cache
# +			id = isNode ? elem[ jQuery.expando ] : elem[ jQuery.expando ] && jQuery.expando;
# +
# +		// Avoid doing any more work than we need to when trying to get data on an
# +		// object that has no data at all
# +		if ( (!id || (pvt && id && (cache[ id ] && !cache[ id ][ internalKey ]))) && getByName && data === undefined ) {
# +			return;
# +		}
# +
# +		if ( !id ) {
# +			// Only DOM nodes need a new unique ID for each element since their data
# +			// ends up in the global cache
# +			if ( isNode ) {
# +				elem[ jQuery.expando ] = id = ++jQuery.uuid;
# +			} else {
# +				id = jQuery.expando;
# +			}
# +		}
# +
# +		if ( !cache[ id ] ) {
# +			cache[ id ] = {};
# +
# +			// TODO: This is a hack for 1.5 ONLY. Avoids exposing jQuery
# +			// metadata on plain JS objects when the object is serialized using
# +			// JSON.stringify
# +			if ( !isNode ) {
# +				cache[ id ].toJSON = jQuery.noop;
# +			}
# +		}
# +
# +		// An object can be passed to jQuery.data instead of a key/value pair; this gets
# +		// shallow copied over onto the existing cache
# +		if ( typeof name === "object" || typeof name === "function" ) {
# +			if ( pvt ) {
# +				cache[ id ][ internalKey ] = jQuery.extend(cache[ id ][ internalKey ], name);
# +			} else {
# +				cache[ id ] = jQuery.extend(cache[ id ], name);
# +			}
# +		}
# +
# +		thisCache = cache[ id ];
# +
# +		// Internal jQuery data is stored in a separate object inside the object's data
# +		// cache in order to avoid key collisions between internal data and user-defined
# +		// data
# +		if ( pvt ) {
# +			if ( !thisCache[ internalKey ] ) {
# +				thisCache[ internalKey ] = {};
# +			}
# +
# +			thisCache = thisCache[ internalKey ];
# +		}
# +
# +		if ( data !== undefined ) {
# +			thisCache[ jQuery.camelCase( name ) ] = data;
# +		}
# +
# +		// TODO: This is a hack for 1.5 ONLY. It will be removed in 1.6. Users should
# +		// not attempt to inspect the internal events object using jQuery.data, as this
# +		// internal data object is undocumented and subject to change.
# +		if ( name === "events" && !thisCache[name] ) {
# +			return thisCache[ internalKey ] && thisCache[ internalKey ].events;
# +		}
# +
# +		// Check for both converted-to-camel and non-converted data property names
# +		// If a data property was specified
# +		if ( getByName ) {
# +
# +			// First Try to find as-is property data
# +			ret = thisCache[ name ];
# +
# +			// Test for null|undefined property data
# +			if ( ret == null ) {
# +
# +				// Try to find the camelCased property
# +				ret = thisCache[ jQuery.camelCase( name ) ];
# +			}
# +		} else {
# +			ret = thisCache;
# +		}
# +
# +		return ret;
# +	},
# +
# +	removeData: function( elem, name, pvt /* Internal Use Only */ ) {
# +		if ( !jQuery.acceptData( elem ) ) {
# +			return;
# +		}
# +
# +		var thisCache,
# +
# +			// Reference to internal data cache key
# +			internalKey = jQuery.expando,
# +
# +			isNode = elem.nodeType,
# +
# +			// See jQuery.data for more information
# +			cache = isNode ? jQuery.cache : elem,
# +
# +			// See jQuery.data for more information
# +			id = isNode ? elem[ jQuery.expando ] : jQuery.expando;
# +
# +		// If there is already no cache entry for this object, there is no
# +		// purpose in continuing
# +		if ( !cache[ id ] ) {
# +			return;
# +		}
# +
# +		if ( name ) {
# +
# +			thisCache = pvt ? cache[ id ][ internalKey ] : cache[ id ];
# +
# +			if ( thisCache ) {
# +
# +				// Support interoperable removal of hyphenated or camelcased keys
# +				if ( !thisCache[ name ] ) {
# +					name = jQuery.camelCase( name );
# +				}
# +
# +				delete thisCache[ name ];
# +
# +				// If there is no data left in the cache, we want to continue
# +				// and let the cache object itself get destroyed
# +				if ( !isEmptyDataObject(thisCache) ) {
# +					return;
# +				}
# +			}
# +		}
# +
# +		// See jQuery.data for more information
# +		if ( pvt ) {
# +			delete cache[ id ][ internalKey ];
# +
# +			// Don't destroy the parent cache unless the internal data object
# +			// had been the only thing left in it
# +			if ( !isEmptyDataObject(cache[ id ]) ) {
# +				return;
# +			}
# +		}
# +
# +		var internalCache = cache[ id ][ internalKey ];
# +
# +		// Browsers that fail expando deletion also refuse to delete expandos on
# +		// the window, but it will allow it on all other JS objects; other browsers
# +		// don't care
# +		// Ensure that `cache` is not a window object #10080
# +		if ( jQuery.support.deleteExpando || !cache.setInterval ) {
# +			delete cache[ id ];
# +		} else {
# +			cache[ id ] = null;
# +		}
# +
# +		// We destroyed the entire user cache at once because it's faster than
# +		// iterating through each key, but we need to continue to persist internal
# +		// data if it existed
# +		if ( internalCache ) {
# +			cache[ id ] = {};
# +			// TODO: This is a hack for 1.5 ONLY. Avoids exposing jQuery
# +			// metadata on plain JS objects when the object is serialized using
# +			// JSON.stringify
# +			if ( !isNode ) {
# +				cache[ id ].toJSON = jQuery.noop;
# +			}
# +
# +			cache[ id ][ internalKey ] = internalCache;
# +
# +		// Otherwise, we need to eliminate the expando on the node to avoid
# +		// false lookups in the cache for entries that no longer exist
# +		} else if ( isNode ) {
# +			// IE does not allow us to delete expando properties from nodes,
# +			// nor does it have a removeAttribute function on Document nodes;
# +			// we must handle all of these cases
# +			if ( jQuery.support.deleteExpando ) {
# +				delete elem[ jQuery.expando ];
# +			} else if ( elem.removeAttribute ) {
# +				elem.removeAttribute( jQuery.expando );
# +			} else {
# +				elem[ jQuery.expando ] = null;
# +			}
# +		}
# +	},
# +
# +	// For internal use only.
# +	_data: function( elem, name, data ) {
# +		return jQuery.data( elem, name, data, true );
# +	},
# +
# +	// A method for determining if a DOM node can handle the data expando
# +	acceptData: function( elem ) {
# +		if ( elem.nodeName ) {
# +			var match = jQuery.noData[ elem.nodeName.toLowerCase() ];
# +
# +			if ( match ) {
# +				return !(match === true || elem.getAttribute("classid") !== match);
# +			}
# +		}
# +
# +		return true;
# +	}
# +});
# +
# +jQuery.fn.extend({
# +	data: function( key, value ) {
# +		var data = null;
# +
# +		if ( typeof key === "undefined" ) {
# +			if ( this.length ) {
# +				data = jQuery.data( this[0] );
# +
# +				if ( this[0].nodeType === 1 ) {
# +			    var attr = this[0].attributes, name;
# +					for ( var i = 0, l = attr.length; i < l; i++ ) {
# +						name = attr[i].name;
# +
# +						if ( name.indexOf( "data-" ) === 0 ) {
# +							name = jQuery.camelCase( name.substring(5) );
# +
# +							dataAttr( this[0], name, data[ name ] );
# +						}
# +					}
# +				}
# +			}
# +
# +			return data;
# +
# +		} else if ( typeof key === "object" ) {
# +			return this.each(function() {
# +				jQuery.data( this, key );
# +			});
# +		}
# +
# +		var parts = key.split(".");
# +		parts[1] = parts[1] ? "." + parts[1] : "";
# +
# +		if ( value === undefined ) {
# +			data = this.triggerHandler("getData" + parts[1] + "!", [parts[0]]);
# +
# +			// Try to fetch any internally stored data first
# +			if ( data === undefined && this.length ) {
# +				data = jQuery.data( this[0], key );
# +				data = dataAttr( this[0], key, data );
# +			}
# +
# +			return data === undefined && parts[1] ?
# +				this.data( parts[0] ) :
# +				data;
# +
# +		} else {
# +			return this.each(function() {
# +				var $this = jQuery( this ),
# +					args = [ parts[0], value ];
# +
# +				$this.triggerHandler( "setData" + parts[1] + "!", args );
# +				jQuery.data( this, key, value );
# +				$this.triggerHandler( "changeData" + parts[1] + "!", args );
# +			});
# +		}
# +	},
# +
# +	removeData: function( key ) {
# +		return this.each(function() {
# +			jQuery.removeData( this, key );
# +		});
# +	}
# +});
# +
# +function dataAttr( elem, key, data ) {
# +	// If nothing was found internally, try to fetch any
# +	// data from the HTML5 data-* attribute
# +	if ( data === undefined && elem.nodeType === 1 ) {
# +
# +		var name = "data-" + key.replace( rmultiDash, "-$1" ).toLowerCase();
# +
# +		data = elem.getAttribute( name );
# +
# +		if ( typeof data === "string" ) {
# +			try {
# +				data = data === "true" ? true :
# +				data === "false" ? false :
# +				data === "null" ? null :
# +				!jQuery.isNaN( data ) ? parseFloat( data ) :
# +					rbrace.test( data ) ? jQuery.parseJSON( data ) :
# +					data;
# +			} catch( e ) {}
# +
# +			// Make sure we set the data so it isn't changed later
# +			jQuery.data( elem, key, data );
# +
# +		} else {
# +			data = undefined;
# +		}
# +	}
# +
# +	return data;
# +}
# +
# +// TODO: This is a hack for 1.5 ONLY to allow objects with a single toJSON
# +// property to be considered empty objects; this property always exists in
# +// order to make sure JSON.stringify does not expose internal metadata
# +function isEmptyDataObject( obj ) {
# +	for ( var name in obj ) {
# +		if ( name !== "toJSON" ) {
# +			return false;
# +		}
# +	}
# +
# +	return true;
# +}
# +
# +
# +
# +
# +function handleQueueMarkDefer( elem, type, src ) {
# +	var deferDataKey = type + "defer",
# +		queueDataKey = type + "queue",
# +		markDataKey = type + "mark",
# +		defer = jQuery.data( elem, deferDataKey, undefined, true );
# +	if ( defer &&
# +		( src === "queue" || !jQuery.data( elem, queueDataKey, undefined, true ) ) &&
# +		( src === "mark" || !jQuery.data( elem, markDataKey, undefined, true ) ) ) {
# +		// Give room for hard-coded callbacks to fire first
# +		// and eventually mark/queue something else on the element
# +		setTimeout( function() {
# +			if ( !jQuery.data( elem, queueDataKey, undefined, true ) &&
# +				!jQuery.data( elem, markDataKey, undefined, true ) ) {
# +				jQuery.removeData( elem, deferDataKey, true );
# +				defer.resolve();
# +			}
# +		}, 0 );
# +	}
# +}
# +
# +jQuery.extend({
# +
# +	_mark: function( elem, type ) {
# +		if ( elem ) {
# +			type = (type || "fx") + "mark";
# +			jQuery.data( elem, type, (jQuery.data(elem,type,undefined,true) || 0) + 1, true );
# +		}
# +	},
# +
# +	_unmark: function( force, elem, type ) {
# +		if ( force !== true ) {
# +			type = elem;
# +			elem = force;
# +			force = false;
# +		}
# +		if ( elem ) {
# +			type = type || "fx";
# +			var key = type + "mark",
# +				count = force ? 0 : ( (jQuery.data( elem, key, undefined, true) || 1 ) - 1 );
# +			if ( count ) {
# +				jQuery.data( elem, key, count, true );
# +			} else {
# +				jQuery.removeData( elem, key, true );
# +				handleQueueMarkDefer( elem, type, "mark" );
# +			}
# +		}
# +	},
# +
# +	queue: function( elem, type, data ) {
# +		if ( elem ) {
# +			type = (type || "fx") + "queue";
# +			var q = jQuery.data( elem, type, undefined, true );
# +			// Speed up dequeue by getting out quickly if this is just a lookup
# +			if ( data ) {
# +				if ( !q || jQuery.isArray(data) ) {
# +					q = jQuery.data( elem, type, jQuery.makeArray(data), true );
# +				} else {
# +					q.push( data );
# +				}
# +			}
# +			return q || [];
# +		}
# +	},
# +
# +	dequeue: function( elem, type ) {
# +		type = type || "fx";
# +
# +		var queue = jQuery.queue( elem, type ),
# +			fn = queue.shift(),
# +			defer;
# +
# +		// If the fx queue is dequeued, always remove the progress sentinel
# +		if ( fn === "inprogress" ) {
# +			fn = queue.shift();
# +		}
# +
# +		if ( fn ) {
# +			// Add a progress sentinel to prevent the fx queue from being
# +			// automatically dequeued
# +			if ( type === "fx" ) {
# +				queue.unshift("inprogress");
# +			}
# +
# +			fn.call(elem, function() {
# +				jQuery.dequeue(elem, type);
# +			});
# +		}
# +
# +		if ( !queue.length ) {
# +			jQuery.removeData( elem, type + "queue", true );
# +			handleQueueMarkDefer( elem, type, "queue" );
# +		}
# +	}
# +});
# +
# +jQuery.fn.extend({
# +	queue: function( type, data ) {
# +		if ( typeof type !== "string" ) {
# +			data = type;
# +			type = "fx";
# +		}
# +
# +		if ( data === undefined ) {
# +			return jQuery.queue( this[0], type );
# +		}
# +		return this.each(function() {
# +			var queue = jQuery.queue( this, type, data );
# +
# +			if ( type === "fx" && queue[0] !== "inprogress" ) {
# +				jQuery.dequeue( this, type );
# +			}
# +		});
# +	},
# +	dequeue: function( type ) {
# +		return this.each(function() {
# +			jQuery.dequeue( this, type );
# +		});
# +	},
# +	// Based off of the plugin by Clint Helfers, with permission.
# +	// http://blindsignals.com/index.php/2009/07/jquery-delay/
# +	delay: function( time, type ) {
# +		time = jQuery.fx ? jQuery.fx.speeds[time] || time : time;
# +		type = type || "fx";
# +
# +		return this.queue( type, function() {
# +			var elem = this;
# +			setTimeout(function() {
# +				jQuery.dequeue( elem, type );
# +			}, time );
# +		});
# +	},
# +	clearQueue: function( type ) {
# +		return this.queue( type || "fx", [] );
# +	},
# +	// Get a promise resolved when queues of a certain type
# +	// are emptied (fx is the type by default)
# +	promise: function( type, object ) {
# +		if ( typeof type !== "string" ) {
# +			object = type;
# +			type = undefined;
# +		}
# +		type = type || "fx";
# +		var defer = jQuery.Deferred(),
# +			elements = this,
# +			i = elements.length,
# +			count = 1,
# +			deferDataKey = type + "defer",
# +			queueDataKey = type + "queue",
# +			markDataKey = type + "mark",
# +			tmp;
# +		function resolve() {
# +			if ( !( --count ) ) {
# +				defer.resolveWith( elements, [ elements ] );
# +			}
# +		}
# +		while( i-- ) {
# +			if (( tmp = jQuery.data( elements[ i ], deferDataKey, undefined, true ) ||
# +					( jQuery.data( elements[ i ], queueDataKey, undefined, true ) ||
# +						jQuery.data( elements[ i ], markDataKey, undefined, true ) ) &&
# +					jQuery.data( elements[ i ], deferDataKey, jQuery._Deferred(), true ) )) {
# +				count++;
# +				tmp.done( resolve );
# +			}
# +		}
# +		resolve();
# +		return defer.promise();
# +	}
# +});
# +
# +
# +
# +
# +var rclass = /[\n\t\r]/g,
# +	rspace = /\s+/,
# +	rreturn = /\r/g,
# +	rtype = /^(?:button|input)$/i,
# +	rfocusable = /^(?:button|input|object|select|textarea)$/i,
# +	rclickable = /^a(?:rea)?$/i,
# +	rboolean = /^(?:autofocus|autoplay|async|checked|controls|defer|disabled|hidden|loop|multiple|open|readonly|required|scoped|selected)$/i,
# +	nodeHook, boolHook;
# +
# +jQuery.fn.extend({
# +	attr: function( name, value ) {
# +		return jQuery.access( this, name, value, true, jQuery.attr );
# +	},
# +
# +	removeAttr: function( name ) {
# +		return this.each(function() {
# +			jQuery.removeAttr( this, name );
# +		});
# +	},
# +
# +	prop: function( name, value ) {
# +		return jQuery.access( this, name, value, true, jQuery.prop );
# +	},
# +
# +	removeProp: function( name ) {
# +		name = jQuery.propFix[ name ] || name;
# +		return this.each(function() {
# +			// try/catch handles cases where IE balks (such as removing a property on window)
# +			try {
# +				this[ name ] = undefined;
# +				delete this[ name ];
# +			} catch( e ) {}
# +		});
# +	},
# +
# +	addClass: function( value ) {
# +		var classNames, i, l, elem,
# +			setClass, c, cl;
# +
# +		if ( jQuery.isFunction( value ) ) {
# +			return this.each(function( j ) {
# +				jQuery( this ).addClass( value.call(this, j, this.className) );
# +			});
# +		}
# +
# +		if ( value && typeof value === "string" ) {
# +			classNames = value.split( rspace );
# +
# +			for ( i = 0, l = this.length; i < l; i++ ) {
# +				elem = this[ i ];
# +
# +				if ( elem.nodeType === 1 ) {
# +					if ( !elem.className && classNames.length === 1 ) {
# +						elem.className = value;
# +
# +					} else {
# +						setClass = " " + elem.className + " ";
# +
# +						for ( c = 0, cl = classNames.length; c < cl; c++ ) {
# +							if ( !~setClass.indexOf( " " + classNames[ c ] + " " ) ) {
# +								setClass += classNames[ c ] + " ";
# +							}
# +						}
# +						elem.className = jQuery.trim( setClass );
# +					}
# +				}
# +			}
# +		}
# +
# +		return this;
# +	},
# +
# +	removeClass: function( value ) {
# +		var classNames, i, l, elem, className, c, cl;
# +
# +		if ( jQuery.isFunction( value ) ) {
# +			return this.each(function( j ) {
# +				jQuery( this ).removeClass( value.call(this, j, this.className) );
# +			});
# +		}
# +
# +		if ( (value && typeof value === "string") || value === undefined ) {
# +			classNames = (value || "").split( rspace );
# +
# +			for ( i = 0, l = this.length; i < l; i++ ) {
# +				elem = this[ i ];
# +
# +				if ( elem.nodeType === 1 && elem.className ) {
# +					if ( value ) {
# +						className = (" " + elem.className + " ").replace( rclass, " " );
# +						for ( c = 0, cl = classNames.length; c < cl; c++ ) {
# +							className = className.replace(" " + classNames[ c ] + " ", " ");
# +						}
# +						elem.className = jQuery.trim( className );
# +
# +					} else {
# +						elem.className = "";
# +					}
# +				}
# +			}
# +		}
# +
# +		return this;
# +	},
# +
# +	toggleClass: function( value, stateVal ) {
# +		var type = typeof value,
# +			isBool = typeof stateVal === "boolean";
# +
# +		if ( jQuery.isFunction( value ) ) {
# +			return this.each(function( i ) {
# +				jQuery( this ).toggleClass( value.call(this, i, this.className, stateVal), stateVal );
# +			});
# +		}
# +
# +		return this.each(function() {
# +			if ( type === "string" ) {
# +				// toggle individual class names
# +				var className,
# +					i = 0,
# +					self = jQuery( this ),
# +					state = stateVal,
# +					classNames = value.split( rspace );
# +
# +				while ( (className = classNames[ i++ ]) ) {
# +					// check each className given, space seperated list
# +					state = isBool ? state : !self.hasClass( className );
# +					self[ state ? "addClass" : "removeClass" ]( className );
# +				}
# +
# +			} else if ( type === "undefined" || type === "boolean" ) {
# +				if ( this.className ) {
# +					// store className if set
# +					jQuery._data( this, "__className__", this.className );
# +				}
# +
# +				// toggle whole className
# +				this.className = this.className || value === false ? "" : jQuery._data( this, "__className__" ) || "";
# +			}
# +		});
# +	},
# +
# +	hasClass: function( selector ) {
# +		var className = " " + selector + " ";
# +		for ( var i = 0, l = this.length; i < l; i++ ) {
# +			if ( this[i].nodeType === 1 && (" " + this[i].className + " ").replace(rclass, " ").indexOf( className ) > -1 ) {
# +				return true;
# +			}
# +		}
# +
# +		return false;
# +	},
# +
# +	val: function( value ) {
# +		var hooks, ret,
# +			elem = this[0];
# +
# +		if ( !arguments.length ) {
# +			if ( elem ) {
# +				hooks = jQuery.valHooks[ elem.nodeName.toLowerCase() ] || jQuery.valHooks[ elem.type ];
# +
# +				if ( hooks && "get" in hooks && (ret = hooks.get( elem, "value" )) !== undefined ) {
# +					return ret;
# +				}
# +
# +				ret = elem.value;
# +
# +				return typeof ret === "string" ?
# +					// handle most common string cases
# +					ret.replace(rreturn, "") :
# +					// handle cases where value is null/undef or number
# +					ret == null ? "" : ret;
# +			}
# +
# +			return undefined;
# +		}
# +
# +		var isFunction = jQuery.isFunction( value );
# +
# +		return this.each(function( i ) {
# +			var self = jQuery(this), val;
# +
# +			if ( this.nodeType !== 1 ) {
# +				return;
# +			}
# +
# +			if ( isFunction ) {
# +				val = value.call( this, i, self.val() );
# +			} else {
# +				val = value;
# +			}
# +
# +			// Treat null/undefined as ""; convert numbers to string
# +			if ( val == null ) {
# +				val = "";
# +			} else if ( typeof val === "number" ) {
# +				val += "";
# +			} else if ( jQuery.isArray( val ) ) {
# +				val = jQuery.map(val, function ( value ) {
# +					return value == null ? "" : value + "";
# +				});
# +			}
# +
# +			hooks = jQuery.valHooks[ this.nodeName.toLowerCase() ] || jQuery.valHooks[ this.type ];
# +
# +			// If set returns undefined, fall back to normal setting
# +			if ( !hooks || !("set" in hooks) || hooks.set( this, val, "value" ) === undefined ) {
# +				this.value = val;
# +			}
# +		});
# +	}
# +});
# +
# +jQuery.extend({
# +	valHooks: {
# +		option: {
# +			get: function( elem ) {
# +				// attributes.value is undefined in Blackberry 4.7 but
# +				// uses .value. See #6932
# +				var val = elem.attributes.value;
# +				return !val || val.specified ? elem.value : elem.text;
# +			}
# +		},
# +		select: {
# +			get: function( elem ) {
# +				var value,
# +					index = elem.selectedIndex,
# +					values = [],
# +					options = elem.options,
# +					one = elem.type === "select-one";
# +
# +				// Nothing was selected
# +				if ( index < 0 ) {
# +					return null;
# +				}
# +
# +				// Loop through all the selected options
# +				for ( var i = one ? index : 0, max = one ? index + 1 : options.length; i < max; i++ ) {
# +					var option = options[ i ];
# +
# +					// Don't return options that are disabled or in a disabled optgroup
# +					if ( option.selected && (jQuery.support.optDisabled ? !option.disabled : option.getAttribute("disabled") === null) &&
# +							(!option.parentNode.disabled || !jQuery.nodeName( option.parentNode, "optgroup" )) ) {
# +
# +						// Get the specific value for the option
# +						value = jQuery( option ).val();
# +
# +						// We don't need an array for one selects
# +						if ( one ) {
# +							return value;
# +						}
# +
# +						// Multi-Selects return an array
# +						values.push( value );
# +					}
# +				}
# +
# +				// Fixes Bug #2551 -- select.val() broken in IE after form.reset()
# +				if ( one && !values.length && options.length ) {
# +					return jQuery( options[ index ] ).val();
# +				}
# +
# +				return values;
# +			},
# +
# +			set: function( elem, value ) {
# +				var values = jQuery.makeArray( value );
# +
# +				jQuery(elem).find("option").each(function() {
# +					this.selected = jQuery.inArray( jQuery(this).val(), values ) >= 0;
# +				});
# +
# +				if ( !values.length ) {
# +					elem.selectedIndex = -1;
# +				}
# +				return values;
# +			}
# +		}
# +	},
# +
# +	attrFn: {
# +		val: true,
# +		css: true,
# +		html: true,
# +		text: true,
# +		data: true,
# +		width: true,
# +		height: true,
# +		offset: true
# +	},
# +
# +	attrFix: {
# +		// Always normalize to ensure hook usage
# +		tabindex: "tabIndex"
# +	},
# +
# +	attr: function( elem, name, value, pass ) {
# +		var nType = elem.nodeType;
# +
# +		// don't get/set attributes on text, comment and attribute nodes
# +		if ( !elem || nType === 3 || nType === 8 || nType === 2 ) {
# +			return undefined;
# +		}
# +
# +		if ( pass && name in jQuery.attrFn ) {
# +			return jQuery( elem )[ name ]( value );
# +		}
# +
# +		// Fallback to prop when attributes are not supported
# +		if ( !("getAttribute" in elem) ) {
# +			return jQuery.prop( elem, name, value );
# +		}
# +
# +		var ret, hooks,
# +			notxml = nType !== 1 || !jQuery.isXMLDoc( elem );
# +
# +		// Normalize the name if needed
# +		if ( notxml ) {
# +			name = jQuery.attrFix[ name ] || name;
# +
# +			hooks = jQuery.attrHooks[ name ];
# +
# +			if ( !hooks ) {
# +				// Use boolHook for boolean attributes
# +				if ( rboolean.test( name ) ) {
# +					hooks = boolHook;
# +
# +				// Use nodeHook if available( IE6/7 )
# +				} else if ( nodeHook ) {
# +					hooks = nodeHook;
# +				}
# +			}
# +		}
# +
# +		if ( value !== undefined ) {
# +
# +			if ( value === null ) {
# +				jQuery.removeAttr( elem, name );
# +				return undefined;
# +
# +			} else if ( hooks && "set" in hooks && notxml && (ret = hooks.set( elem, value, name )) !== undefined ) {
# +				return ret;
# +
# +			} else {
# +				elem.setAttribute( name, "" + value );
# +				return value;
# +			}
# +
# +		} else if ( hooks && "get" in hooks && notxml && (ret = hooks.get( elem, name )) !== null ) {
# +			return ret;
# +
# +		} else {
# +
# +			ret = elem.getAttribute( name );
# +
# +			// Non-existent attributes return null, we normalize to undefined
# +			return ret === null ?
# +				undefined :
# +				ret;
# +		}
# +	},
# +
# +	removeAttr: function( elem, name ) {
# +		var propName;
# +		if ( elem.nodeType === 1 ) {
# +			name = jQuery.attrFix[ name ] || name;
# +
# +			jQuery.attr( elem, name, "" );
# +			elem.removeAttribute( name );
# +
# +			// Set corresponding property to false for boolean attributes
# +			if ( rboolean.test( name ) && (propName = jQuery.propFix[ name ] || name) in elem ) {
# +				elem[ propName ] = false;
# +			}
# +		}
# +	},
# +
# +	attrHooks: {
# +		type: {
# +			set: function( elem, value ) {
# +				// We can't allow the type property to be changed (since it causes problems in IE)
# +				if ( rtype.test( elem.nodeName ) && elem.parentNode ) {
# +					jQuery.error( "type property can't be changed" );
# +				} else if ( !jQuery.support.radioValue && value === "radio" && jQuery.nodeName(elem, "input") ) {
# +					// Setting the type on a radio button after the value resets the value in IE6-9
# +					// Reset value to it's default in case type is set after value
# +					// This is for element creation
# +					var val = elem.value;
# +					elem.setAttribute( "type", value );
# +					if ( val ) {
# +						elem.value = val;
# +					}
# +					return value;
# +				}
# +			}
# +		},
# +		// Use the value property for back compat
# +		// Use the nodeHook for button elements in IE6/7 (#1954)
# +		value: {
# +			get: function( elem, name ) {
# +				if ( nodeHook && jQuery.nodeName( elem, "button" ) ) {
# +					return nodeHook.get( elem, name );
# +				}
# +				return name in elem ?
# +					elem.value :
# +					null;
# +			},
# +			set: function( elem, value, name ) {
# +				if ( nodeHook && jQuery.nodeName( elem, "button" ) ) {
# +					return nodeHook.set( elem, value, name );
# +				}
# +				// Does not return so that setAttribute is also used
# +				elem.value = value;
# +			}
# +		}
# +	},
# +
# +	propFix: {
# +		tabindex: "tabIndex",
# +		readonly: "readOnly",
# +		"for": "htmlFor",
# +		"class": "className",
# +		maxlength: "maxLength",
# +		cellspacing: "cellSpacing",
# +		cellpadding: "cellPadding",
# +		rowspan: "rowSpan",
# +		colspan: "colSpan",
# +		usemap: "useMap",
# +		frameborder: "frameBorder",
# +		contenteditable: "contentEditable"
# +	},
# +
# +	prop: function( elem, name, value ) {
# +		var nType = elem.nodeType;
# +
# +		// don't get/set properties on text, comment and attribute nodes
# +		if ( !elem || nType === 3 || nType === 8 || nType === 2 ) {
# +			return undefined;
# +		}
# +
# +		var ret, hooks,
# +			notxml = nType !== 1 || !jQuery.isXMLDoc( elem );
# +
# +		if ( notxml ) {
# +			// Fix name and attach hooks
# +			name = jQuery.propFix[ name ] || name;
# +			hooks = jQuery.propHooks[ name ];
# +		}
# +
# +		if ( value !== undefined ) {
# +			if ( hooks && "set" in hooks && (ret = hooks.set( elem, value, name )) !== undefined ) {
# +				return ret;
# +
# +			} else {
# +				return (elem[ name ] = value);
# +			}
# +
# +		} else {
# +			if ( hooks && "get" in hooks && (ret = hooks.get( elem, name )) !== null ) {
# +				return ret;
# +
# +			} else {
# +				return elem[ name ];
# +			}
# +		}
# +	},
# +
# +	propHooks: {
# +		tabIndex: {
# +			get: function( elem ) {
# +				// elem.tabIndex doesn't always return the correct value when it hasn't been explicitly set
# +				// http://fluidproject.org/blog/2008/01/09/getting-setting-and-removing-tabindex-values-with-javascript/
# +				var attributeNode = elem.getAttributeNode("tabindex");
# +
# +				return attributeNode && attributeNode.specified ?
# +					parseInt( attributeNode.value, 10 ) :
# +					rfocusable.test( elem.nodeName ) || rclickable.test( elem.nodeName ) && elem.href ?
# +						0 :
# +						undefined;
# +			}
# +		}
# +	}
# +});
# +
# +// Add the tabindex propHook to attrHooks for back-compat
# +jQuery.attrHooks.tabIndex = jQuery.propHooks.tabIndex;
# +
# +// Hook for boolean attributes
# +boolHook = {
# +	get: function( elem, name ) {
# +		// Align boolean attributes with corresponding properties
# +		// Fall back to attribute presence where some booleans are not supported
# +		var attrNode;
# +		return jQuery.prop( elem, name ) === true || ( attrNode = elem.getAttributeNode( name ) ) && attrNode.nodeValue !== false ?
# +			name.toLowerCase() :
# +			undefined;
# +	},
# +	set: function( elem, value, name ) {
# +		var propName;
# +		if ( value === false ) {
# +			// Remove boolean attributes when set to false
# +			jQuery.removeAttr( elem, name );
# +		} else {
# +			// value is true since we know at this point it's type boolean and not false
# +			// Set boolean attributes to the same name and set the DOM property
# +			propName = jQuery.propFix[ name ] || name;
# +			if ( propName in elem ) {
# +				// Only set the IDL specifically if it already exists on the element
# +				elem[ propName ] = true;
# +			}
# +
# +			elem.setAttribute( name, name.toLowerCase() );
# +		}
# +		return name;
# +	}
# +};
# +
# +// IE6/7 do not support getting/setting some attributes with get/setAttribute
# +if ( !jQuery.support.getSetAttribute ) {
# +
# +	// Use this for any attribute in IE6/7
# +	// This fixes almost every IE6/7 issue
# +	nodeHook = jQuery.valHooks.button = {
# +		get: function( elem, name ) {
# +			var ret;
# +			ret = elem.getAttributeNode( name );
# +			// Return undefined if nodeValue is empty string
# +			return ret && ret.nodeValue !== "" ?
# +				ret.nodeValue :
# +				undefined;
# +		},
# +		set: function( elem, value, name ) {
# +			// Set the existing or create a new attribute node
# +			var ret = elem.getAttributeNode( name );
# +			if ( !ret ) {
# +				ret = document.createAttribute( name );
# +				elem.setAttributeNode( ret );
# +			}
# +			return (ret.nodeValue = value + "");
# +		}
# +	};
# +
# +	// Set width and height to auto instead of 0 on empty string( Bug #8150 )
# +	// This is for removals
# +	jQuery.each([ "width", "height" ], function( i, name ) {
# +		jQuery.attrHooks[ name ] = jQuery.extend( jQuery.attrHooks[ name ], {
# +			set: function( elem, value ) {
# +				if ( value === "" ) {
# +					elem.setAttribute( name, "auto" );
# +					return value;
# +				}
# +			}
# +		});
# +	});
# +}
# +
# +
# +// Some attributes require a special call on IE
# +if ( !jQuery.support.hrefNormalized ) {
# +	jQuery.each([ "href", "src", "width", "height" ], function( i, name ) {
# +		jQuery.attrHooks[ name ] = jQuery.extend( jQuery.attrHooks[ name ], {
# +			get: function( elem ) {
# +				var ret = elem.getAttribute( name, 2 );
# +				return ret === null ? undefined : ret;
# +			}
# +		});
# +	});
# +}
# +
# +if ( !jQuery.support.style ) {
# +	jQuery.attrHooks.style = {
# +		get: function( elem ) {
# +			// Return undefined in the case of empty string
# +			// Normalize to lowercase since IE uppercases css property names
# +			return elem.style.cssText.toLowerCase() || undefined;
# +		},
# +		set: function( elem, value ) {
# +			return (elem.style.cssText = "" + value);
# +		}
# +	};
# +}
# +
# +// Safari mis-reports the default selected property of an option
# +// Accessing the parent's selectedIndex property fixes it
# +if ( !jQuery.support.optSelected ) {
# +	jQuery.propHooks.selected = jQuery.extend( jQuery.propHooks.selected, {
# +		get: function( elem ) {
# +			var parent = elem.parentNode;
# +
# +			if ( parent ) {
# +				parent.selectedIndex;
# +
# +				// Make sure that it also works with optgroups, see #5701
# +				if ( parent.parentNode ) {
# +					parent.parentNode.selectedIndex;
# +				}
# +			}
# +			return null;
# +		}
# +	});
# +}
# +
# +// Radios and checkboxes getter/setter
# +if ( !jQuery.support.checkOn ) {
# +	jQuery.each([ "radio", "checkbox" ], function() {
# +		jQuery.valHooks[ this ] = {
# +			get: function( elem ) {
# +				// Handle the case where in Webkit "" is returned instead of "on" if a value isn't specified
# +				return elem.getAttribute("value") === null ? "on" : elem.value;
# +			}
# +		};
# +	});
# +}
# +jQuery.each([ "radio", "checkbox" ], function() {
# +	jQuery.valHooks[ this ] = jQuery.extend( jQuery.valHooks[ this ], {
# +		set: function( elem, value ) {
# +			if ( jQuery.isArray( value ) ) {
# +				return (elem.checked = jQuery.inArray( jQuery(elem).val(), value ) >= 0);
# +			}
# +		}
# +	});
# +});
# +
# +
# +
# +
# +var rnamespaces = /\.(.*)$/,
# +	rformElems = /^(?:textarea|input|select)$/i,
# +	rperiod = /\./g,
# +	rspaces = / /g,
# +	rescape = /[^\w\s.|`]/g,
# +	fcleanup = function( nm ) {
# +		return nm.replace(rescape, "\\$&");
# +	};
# +
# +/*
# + * A number of helper functions used for managing events.
# + * Many of the ideas behind this code originated from
# + * Dean Edwards' addEvent library.
# + */
# +jQuery.event = {
# +
# +	// Bind an event to an element
# +	// Original by Dean Edwards
# +	add: function( elem, types, handler, data ) {
# +		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
# +			return;
# +		}
# +
# +		if ( handler === false ) {
# +			handler = returnFalse;
# +		} else if ( !handler ) {
# +			// Fixes bug #7229. Fix recommended by jdalton
# +			return;
# +		}
# +
# +		var handleObjIn, handleObj;
# +
# +		if ( handler.handler ) {
# +			handleObjIn = handler;
# +			handler = handleObjIn.handler;
# +		}
# +
# +		// Make sure that the function being executed has a unique ID
# +		if ( !handler.guid ) {
# +			handler.guid = jQuery.guid++;
# +		}
# +
# +		// Init the element's event structure
# +		var elemData = jQuery._data( elem );
# +
# +		// If no elemData is found then we must be trying to bind to one of the
# +		// banned noData elements
# +		if ( !elemData ) {
# +			return;
# +		}
# +
# +		var events = elemData.events,
# +			eventHandle = elemData.handle;
# +
# +		if ( !events ) {
# +			elemData.events = events = {};
# +		}
# +
# +		if ( !eventHandle ) {
# +			elemData.handle = eventHandle = function( e ) {
# +				// Discard the second event of a jQuery.event.trigger() and
# +				// when an event is called after a page has unloaded
# +				return typeof jQuery !== "undefined" && (!e || jQuery.event.triggered !== e.type) ?
# +					jQuery.event.handle.apply( eventHandle.elem, arguments ) :
# +					undefined;
# +			};
# +		}
# +
# +		// Add elem as a property of the handle function
# +		// This is to prevent a memory leak with non-native events in IE.
# +		eventHandle.elem = elem;
# +
# +		// Handle multiple events separated by a space
# +		// jQuery(...).bind("mouseover mouseout", fn);
# +		types = types.split(" ");
# +
# +		var type, i = 0, namespaces;
# +
# +		while ( (type = types[ i++ ]) ) {
# +			handleObj = handleObjIn ?
# +				jQuery.extend({}, handleObjIn) :
# +				{ handler: handler, data: data };
# +
# +			// Namespaced event handlers
# +			if ( type.indexOf(".") > -1 ) {
# +				namespaces = type.split(".");
# +				type = namespaces.shift();
# +				handleObj.namespace = namespaces.slice(0).sort().join(".");
# +
# +			} else {
# +				namespaces = [];
# +				handleObj.namespace = "";
# +			}
# +
# +			handleObj.type = type;
# +			if ( !handleObj.guid ) {
# +				handleObj.guid = handler.guid;
# +			}
# +
# +			// Get the current list of functions bound to this event
# +			var handlers = events[ type ],
# +				special = jQuery.event.special[ type ] || {};
# +
# +			// Init the event handler queue
# +			if ( !handlers ) {
# +				handlers = events[ type ] = [];
# +
# +				// Check for a special event handler
# +				// Only use addEventListener/attachEvent if the special
# +				// events handler returns false
# +				if ( !special.setup || special.setup.call( elem, data, namespaces, eventHandle ) === false ) {
# +					// Bind the global event handler to the element
# +					if ( elem.addEventListener ) {
# +						elem.addEventListener( type, eventHandle, false );
# +
# +					} else if ( elem.attachEvent ) {
# +						elem.attachEvent( "on" + type, eventHandle );
# +					}
# +				}
# +			}
# +
# +			if ( special.add ) {
# +				special.add.call( elem, handleObj );
# +
# +				if ( !handleObj.handler.guid ) {
# +					handleObj.handler.guid = handler.guid;
# +				}
# +			}
# +
# +			// Add the function to the element's handler list
# +			handlers.push( handleObj );
# +
# +			// Keep track of which events have been used, for event optimization
# +			jQuery.event.global[ type ] = true;
# +		}
# +
# +		// Nullify elem to prevent memory leaks in IE
# +		elem = null;
# +	},
# +
# +	global: {},
# +
# +	// Detach an event or set of events from an element
# +	remove: function( elem, types, handler, pos ) {
# +		// don't do events on text and comment nodes
# +		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
# +			return;
# +		}
# +
# +		if ( handler === false ) {
# +			handler = returnFalse;
# +		}
# +
# +		var ret, type, fn, j, i = 0, all, namespaces, namespace, special, eventType, handleObj, origType,
# +			elemData = jQuery.hasData( elem ) && jQuery._data( elem ),
# +			events = elemData && elemData.events;
# +
# +		if ( !elemData || !events ) {
# +			return;
# +		}
# +
# +		// types is actually an event object here
# +		if ( types && types.type ) {
# +			handler = types.handler;
# +			types = types.type;
# +		}
# +
# +		// Unbind all events for the element
# +		if ( !types || typeof types === "string" && types.charAt(0) === "." ) {
# +			types = types || "";
# +
# +			for ( type in events ) {
# +				jQuery.event.remove( elem, type + types );
# +			}
# +
# +			return;
# +		}
# +
# +		// Handle multiple events separated by a space
# +		// jQuery(...).unbind("mouseover mouseout", fn);
# +		types = types.split(" ");
# +
# +		while ( (type = types[ i++ ]) ) {
# +			origType = type;
# +			handleObj = null;
# +			all = type.indexOf(".") < 0;
# +			namespaces = [];
# +
# +			if ( !all ) {
# +				// Namespaced event handlers
# +				namespaces = type.split(".");
# +				type = namespaces.shift();
# +
# +				namespace = new RegExp("(^|\\.)" +
# +					jQuery.map( namespaces.slice(0).sort(), fcleanup ).join("\\.(?:.*\\.)?") + "(\\.|$)");
# +			}
# +
# +			eventType = events[ type ];
# +
# +			if ( !eventType ) {
# +				continue;
# +			}
# +
# +			if ( !handler ) {
# +				for ( j = 0; j < eventType.length; j++ ) {
# +					handleObj = eventType[ j ];
# +
# +					if ( all || namespace.test( handleObj.namespace ) ) {
# +						jQuery.event.remove( elem, origType, handleObj.handler, j );
# +						eventType.splice( j--, 1 );
# +					}
# +				}
# +
# +				continue;
# +			}
# +
# +			special = jQuery.event.special[ type ] || {};
# +
# +			for ( j = pos || 0; j < eventType.length; j++ ) {
# +				handleObj = eventType[ j ];
# +
# +				if ( handler.guid === handleObj.guid ) {
# +					// remove the given handler for the given type
# +					if ( all || namespace.test( handleObj.namespace ) ) {
# +						if ( pos == null ) {
# +							eventType.splice( j--, 1 );
# +						}
# +
# +						if ( special.remove ) {
# +							special.remove.call( elem, handleObj );
# +						}
# +					}
# +
# +					if ( pos != null ) {
# +						break;
# +					}
# +				}
# +			}
# +
# +			// remove generic event handler if no more handlers exist
# +			if ( eventType.length === 0 || pos != null && eventType.length === 1 ) {
# +				if ( !special.teardown || special.teardown.call( elem, namespaces ) === false ) {
# +					jQuery.removeEvent( elem, type, elemData.handle );
# +				}
# +
# +				ret = null;
# +				delete events[ type ];
# +			}
# +		}
# +
# +		// Remove the expando if it's no longer used
# +		if ( jQuery.isEmptyObject( events ) ) {
# +			var handle = elemData.handle;
# +			if ( handle ) {
# +				handle.elem = null;
# +			}
# +
# +			delete elemData.events;
# +			delete elemData.handle;
# +
# +			if ( jQuery.isEmptyObject( elemData ) ) {
# +				jQuery.removeData( elem, undefined, true );
# +			}
# +		}
# +	},
# +
# +	// Events that are safe to short-circuit if no handlers are attached.
# +	// Native DOM events should not be added, they may have inline handlers.
# +	customEvent: {
# +		"getData": true,
# +		"setData": true,
# +		"changeData": true
# +	},
# +
# +	trigger: function( event, data, elem, onlyHandlers ) {
# +		// Event object or event type
# +		var type = event.type || event,
# +			namespaces = [],
# +			exclusive;
# +
# +		if ( type.indexOf("!") >= 0 ) {
# +			// Exclusive events trigger only for the exact event (no namespaces)
# +			type = type.slice(0, -1);
# +			exclusive = true;
# +		}
# +
# +		if ( type.indexOf(".") >= 0 ) {
# +			// Namespaced trigger; create a regexp to match event type in handle()
# +			namespaces = type.split(".");
# +			type = namespaces.shift();
# +			namespaces.sort();
# +		}
# +
# +		if ( (!elem || jQuery.event.customEvent[ type ]) && !jQuery.event.global[ type ] ) {
# +			// No jQuery handlers for this event type, and it can't have inline handlers
# +			return;
# +		}
# +
# +		// Caller can pass in an Event, Object, or just an event type string
# +		event = typeof event === "object" ?
# +			// jQuery.Event object
# +			event[ jQuery.expando ] ? event :
# +			// Object literal
# +			new jQuery.Event( type, event ) :
# +			// Just the event type (string)
# +			new jQuery.Event( type );
# +
# +		event.type = type;
# +		event.exclusive = exclusive;
# +		event.namespace = namespaces.join(".");
# +		event.namespace_re = new RegExp("(^|\\.)" + namespaces.join("\\.(?:.*\\.)?") + "(\\.|$)");
# +
# +		// triggerHandler() and global events don't bubble or run the default action
# +		if ( onlyHandlers || !elem ) {
# +			event.preventDefault();
# +			event.stopPropagation();
# +		}
# +
# +		// Handle a global trigger
# +		if ( !elem ) {
# +			// TODO: Stop taunting the data cache; remove global events and always attach to document
# +			jQuery.each( jQuery.cache, function() {
# +				// internalKey variable is just used to make it easier to find
# +				// and potentially change this stuff later; currently it just
# +				// points to jQuery.expando
# +				var internalKey = jQuery.expando,
# +					internalCache = this[ internalKey ];
# +				if ( internalCache && internalCache.events && internalCache.events[ type ] ) {
# +					jQuery.event.trigger( event, data, internalCache.handle.elem );
# +				}
# +			});
# +			return;
# +		}
# +
# +		// Don't do events on text and comment nodes
# +		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
# +			return;
# +		}
# +
# +		// Clean up the event in case it is being reused
# +		event.result = undefined;
# +		event.target = elem;
# +
# +		// Clone any incoming data and prepend the event, creating the handler arg list
# +		data = data != null ? jQuery.makeArray( data ) : [];
# +		data.unshift( event );
# +
# +		var cur = elem,
# +			// IE doesn't like method names with a colon (#3533, #8272)
# +			ontype = type.indexOf(":") < 0 ? "on" + type : "";
# +
# +		// Fire event on the current element, then bubble up the DOM tree
# +		do {
# +			var handle = jQuery._data( cur, "handle" );
# +
# +			event.currentTarget = cur;
# +			if ( handle ) {
# +				handle.apply( cur, data );
# +			}
# +
# +			// Trigger an inline bound script
# +			if ( ontype && jQuery.acceptData( cur ) && cur[ ontype ] && cur[ ontype ].apply( cur, data ) === false ) {
# +				event.result = false;
# +				event.preventDefault();
# +			}
# +
# +			// Bubble up to document, then to window
# +			cur = cur.parentNode || cur.ownerDocument || cur === event.target.ownerDocument && window;
# +		} while ( cur && !event.isPropagationStopped() );
# +
# +		// If nobody prevented the default action, do it now
# +		if ( !event.isDefaultPrevented() ) {
# +			var old,
# +				special = jQuery.event.special[ type ] || {};
# +
# +			if ( (!special._default || special._default.call( elem.ownerDocument, event ) === false) &&
# +				!(type === "click" && jQuery.nodeName( elem, "a" )) && jQuery.acceptData( elem ) ) {
# +
# +				// Call a native DOM method on the target with the same name name as the event.
# +				// Can't use an .isFunction)() check here because IE6/7 fails that test.
# +				// IE<9 dies on focus to hidden element (#1486), may want to revisit a try/catch.
# +				try {
# +					if ( ontype && elem[ type ] ) {
# +						// Don't re-trigger an onFOO event when we call its FOO() method
# +						old = elem[ ontype ];
# +
# +						if ( old ) {
# +							elem[ ontype ] = null;
# +						}
# +
# +						jQuery.event.triggered = type;
# +						elem[ type ]();
# +					}
# +				} catch ( ieError ) {}
# +
# +				if ( old ) {
# +					elem[ ontype ] = old;
# +				}
# +
# +				jQuery.event.triggered = undefined;
# +			}
# +		}
# +
# +		return event.result;
# +	},
# +
# +	handle: function( event ) {
# +		event = jQuery.event.fix( event || window.event );
# +		// Snapshot the handlers list since a called handler may add/remove events.
# +		var handlers = ((jQuery._data( this, "events" ) || {})[ event.type ] || []).slice(0),
# +			run_all = !event.exclusive && !event.namespace,
# +			args = Array.prototype.slice.call( arguments, 0 );
# +
# +		// Use the fix-ed Event rather than the (read-only) native event
# +		args[0] = event;
# +		event.currentTarget = this;
# +
# +		for ( var j = 0, l = handlers.length; j < l; j++ ) {
# +			var handleObj = handlers[ j ];
# +
# +			// Triggered event must 1) be non-exclusive and have no namespace, or
# +			// 2) have namespace(s) a subset or equal to those in the bound event.
# +			if ( run_all || event.namespace_re.test( handleObj.namespace ) ) {
# +				// Pass in a reference to the handler function itself
# +				// So that we can later remove it
# +				event.handler = handleObj.handler;
# +				event.data = handleObj.data;
# +				event.handleObj = handleObj;
# +
# +				var ret = handleObj.handler.apply( this, args );
# +
# +				if ( ret !== undefined ) {
# +					event.result = ret;
# +					if ( ret === false ) {
# +						event.preventDefault();
# +						event.stopPropagation();
# +					}
# +				}
# +
# +				if ( event.isImmediatePropagationStopped() ) {
# +					break;
# +				}
# +			}
# +		}
# +		return event.result;
# +	},
# +
# +	props: "altKey attrChange attrName bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement handler keyCode layerX layerY metaKey newValue offsetX offsetY pageX pageY prevValue relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" "),
# +
# +	fix: function( event ) {
# +		if ( event[ jQuery.expando ] ) {
# +			return event;
# +		}
# +
# +		// store a copy of the original event object
# +		// and "clone" to set read-only properties
# +		var originalEvent = event;
# +		event = jQuery.Event( originalEvent );
# +
# +		for ( var i = this.props.length, prop; i; ) {
# +			prop = this.props[ --i ];
# +			event[ prop ] = originalEvent[ prop ];
# +		}
# +
# +		// Fix target property, if necessary
# +		if ( !event.target ) {
# +			// Fixes #1925 where srcElement might not be defined either
# +			event.target = event.srcElement || document;
# +		}
# +
# +		// check if target is a textnode (safari)
# +		if ( event.target.nodeType === 3 ) {
# +			event.target = event.target.parentNode;
# +		}
# +
# +		// Add relatedTarget, if necessary
# +		if ( !event.relatedTarget && event.fromElement ) {
# +			event.relatedTarget = event.fromElement === event.target ? event.toElement : event.fromElement;
# +		}
# +
# +		// Calculate pageX/Y if missing and clientX/Y available
# +		if ( event.pageX == null && event.clientX != null ) {
# +			var eventDocument = event.target.ownerDocument || document,
# +				doc = eventDocument.documentElement,
# +				body = eventDocument.body;
# +
# +			event.pageX = event.clientX + (doc && doc.scrollLeft || body && body.scrollLeft || 0) - (doc && doc.clientLeft || body && body.clientLeft || 0);
# +			event.pageY = event.clientY + (doc && doc.scrollTop  || body && body.scrollTop  || 0) - (doc && doc.clientTop  || body && body.clientTop  || 0);
# +		}
# +
# +		// Add which for key events
# +		if ( event.which == null && (event.charCode != null || event.keyCode != null) ) {
# +			event.which = event.charCode != null ? event.charCode : event.keyCode;
# +		}
# +
# +		// Add metaKey to non-Mac browsers (use ctrl for PC's and Meta for Macs)
# +		if ( !event.metaKey && event.ctrlKey ) {
# +			event.metaKey = event.ctrlKey;
# +		}
# +
# +		// Add which for click: 1 === left; 2 === middle; 3 === right
# +		// Note: button is not normalized, so don't use it
# +		if ( !event.which && event.button !== undefined ) {
# +			event.which = (event.button & 1 ? 1 : ( event.button & 2 ? 3 : ( event.button & 4 ? 2 : 0 ) ));
# +		}
# +
# +		return event;
# +	},
# +
# +	// Deprecated, use jQuery.guid instead
# +	guid: 1E8,
# +
# +	// Deprecated, use jQuery.proxy instead
# +	proxy: jQuery.proxy,
# +
# +	special: {
# +		ready: {
# +			// Make sure the ready event is setup
# +			setup: jQuery.bindReady,
# +			teardown: jQuery.noop
# +		},
# +
# +		live: {
# +			add: function( handleObj ) {
# +				jQuery.event.add( this,
# +					liveConvert( handleObj.origType, handleObj.selector ),
# +					jQuery.extend({}, handleObj, {handler: liveHandler, guid: handleObj.handler.guid}) );
# +			},
# +
# +			remove: function( handleObj ) {
# +				jQuery.event.remove( this, liveConvert( handleObj.origType, handleObj.selector ), handleObj );
# +			}
# +		},
# +
# +		beforeunload: {
# +			setup: function( data, namespaces, eventHandle ) {
# +				// We only want to do this special case on windows
# +				if ( jQuery.isWindow( this ) ) {
# +					this.onbeforeunload = eventHandle;
# +				}
# +			},
# +
# +			teardown: function( namespaces, eventHandle ) {
# +				if ( this.onbeforeunload === eventHandle ) {
# +					this.onbeforeunload = null;
# +				}
# +			}
# +		}
# +	}
# +};
# +
# +jQuery.removeEvent = document.removeEventListener ?
# +	function( elem, type, handle ) {
# +		if ( elem.removeEventListener ) {
# +			elem.removeEventListener( type, handle, false );
# +		}
# +	} :
# +	function( elem, type, handle ) {
# +		if ( elem.detachEvent ) {
# +			elem.detachEvent( "on" + type, handle );
# +		}
# +	};
# +
# +jQuery.Event = function( src, props ) {
# +	// Allow instantiation without the 'new' keyword
# +	if ( !this.preventDefault ) {
# +		return new jQuery.Event( src, props );
# +	}
# +
# +	// Event object
# +	if ( src && src.type ) {
# +		this.originalEvent = src;
# +		this.type = src.type;
# +
# +		// Events bubbling up the document may have been marked as prevented
# +		// by a handler lower down the tree; reflect the correct value.
# +		this.isDefaultPrevented = (src.defaultPrevented || src.returnValue === false ||
# +			src.getPreventDefault && src.getPreventDefault()) ? returnTrue : returnFalse;
# +
# +	// Event type
# +	} else {
# +		this.type = src;
# +	}
# +
# +	// Put explicitly provided properties onto the event object
# +	if ( props ) {
# +		jQuery.extend( this, props );
# +	}
# +
# +	// timeStamp is buggy for some events on Firefox(#3843)
# +	// So we won't rely on the native value
# +	this.timeStamp = jQuery.now();
# +
# +	// Mark it as fixed
# +	this[ jQuery.expando ] = true;
# +};
# +
# +function returnFalse() {
# +	return false;
# +}
# +function returnTrue() {
# +	return true;
# +}
# +
# +// jQuery.Event is based on DOM3 Events as specified by the ECMAScript Language Binding
# +// http://www.w3.org/TR/2003/WD-DOM-Level-3-Events-20030331/ecma-script-binding.html
# +jQuery.Event.prototype = {
# +	preventDefault: function() {
# +		this.isDefaultPrevented = returnTrue;
# +
# +		var e = this.originalEvent;
# +		if ( !e ) {
# +			return;
# +		}
# +
# +		// if preventDefault exists run it on the original event
# +		if ( e.preventDefault ) {
# +			e.preventDefault();
# +
# +		// otherwise set the returnValue property of the original event to false (IE)
# +		} else {
# +			e.returnValue = false;
# +		}
# +	},
# +	stopPropagation: function() {
# +		this.isPropagationStopped = returnTrue;
# +
# +		var e = this.originalEvent;
# +		if ( !e ) {
# +			return;
# +		}
# +		// if stopPropagation exists run it on the original event
# +		if ( e.stopPropagation ) {
# +			e.stopPropagation();
# +		}
# +		// otherwise set the cancelBubble property of the original event to true (IE)
# +		e.cancelBubble = true;
# +	},
# +	stopImmediatePropagation: function() {
# +		this.isImmediatePropagationStopped = returnTrue;
# +		this.stopPropagation();
# +	},
# +	isDefaultPrevented: returnFalse,
# +	isPropagationStopped: returnFalse,
# +	isImmediatePropagationStopped: returnFalse
# +};
# +
# +// Checks if an event happened on an element within another element
# +// Used in jQuery.event.special.mouseenter and mouseleave handlers
# +var withinElement = function( event ) {
# +
# +	// Check if mouse(over|out) are still within the same parent element
# +	var related = event.relatedTarget,
# +		inside = false,
# +		eventType = event.type;
# +
# +	event.type = event.data;
# +
# +	if ( related !== this ) {
# +
# +		if ( related ) {
# +			inside = jQuery.contains( this, related );
# +		}
# +
# +		if ( !inside ) {
# +
# +			jQuery.event.handle.apply( this, arguments );
# +
# +			event.type = eventType;
# +		}
# +	}
# +},
# +
# +// In case of event delegation, we only need to rename the event.type,
# +// liveHandler will take care of the rest.
# +delegate = function( event ) {
# +	event.type = event.data;
# +	jQuery.event.handle.apply( this, arguments );
# +};
# +
# +// Create mouseenter and mouseleave events
# +jQuery.each({
# +	mouseenter: "mouseover",
# +	mouseleave: "mouseout"
# +}, function( orig, fix ) {
# +	jQuery.event.special[ orig ] = {
# +		setup: function( data ) {
# +			jQuery.event.add( this, fix, data && data.selector ? delegate : withinElement, orig );
# +		},
# +		teardown: function( data ) {
# +			jQuery.event.remove( this, fix, data && data.selector ? delegate : withinElement );
# +		}
# +	};
# +});
# +
# +// submit delegation
# +if ( !jQuery.support.submitBubbles ) {
# +
# +	jQuery.event.special.submit = {
# +		setup: function( data, namespaces ) {
# +			if ( !jQuery.nodeName( this, "form" ) ) {
# +				jQuery.event.add(this, "click.specialSubmit", function( e ) {
# +					// Avoid triggering error on non-existent type attribute in IE VML (#7071)
# +					var elem = e.target,
# +						type = jQuery.nodeName( elem, "input" ) || jQuery.nodeName( elem, "button" ) ? elem.type : "";
# +
# +					if ( (type === "submit" || type === "image") && jQuery( elem ).closest("form").length ) {
# +						trigger( "submit", this, arguments );
# +					}
# +				});
# +
# +				jQuery.event.add(this, "keypress.specialSubmit", function( e ) {
# +					var elem = e.target,
# +						type = jQuery.nodeName( elem, "input" ) || jQuery.nodeName( elem, "button" ) ? elem.type : "";
# +
# +					if ( (type === "text" || type === "password") && jQuery( elem ).closest("form").length && e.keyCode === 13 ) {
# +						trigger( "submit", this, arguments );
# +					}
# +				});
# +
# +			} else {
# +				return false;
# +			}
# +		},
# +
# +		teardown: function( namespaces ) {
# +			jQuery.event.remove( this, ".specialSubmit" );
# +		}
# +	};
# +
# +}
# +
# +// change delegation, happens here so we have bind.
# +if ( !jQuery.support.changeBubbles ) {
# +
# +	var changeFilters,
# +
# +	getVal = function( elem ) {
# +		var type = jQuery.nodeName( elem, "input" ) ? elem.type : "",
# +			val = elem.value;
# +
# +		if ( type === "radio" || type === "checkbox" ) {
# +			val = elem.checked;
# +
# +		} else if ( type === "select-multiple" ) {
# +			val = elem.selectedIndex > -1 ?
# +				jQuery.map( elem.options, function( elem ) {
# +					return elem.selected;
# +				}).join("-") :
# +				"";
# +
# +		} else if ( jQuery.nodeName( elem, "select" ) ) {
# +			val = elem.selectedIndex;
# +		}
# +
# +		return val;
# +	},
# +
# +	testChange = function testChange( e ) {
# +		var elem = e.target, data, val;
# +
# +		if ( !rformElems.test( elem.nodeName ) || elem.readOnly ) {
# +			return;
# +		}
# +
# +		data = jQuery._data( elem, "_change_data" );
# +		val = getVal(elem);
# +
# +		// the current data will be also retrieved by beforeactivate
# +		if ( e.type !== "focusout" || elem.type !== "radio" ) {
# +			jQuery._data( elem, "_change_data", val );
# +		}
# +
# +		if ( data === undefined || val === data ) {
# +			return;
# +		}
# +
# +		if ( data != null || val ) {
# +			e.type = "change";
# +			e.liveFired = undefined;
# +			jQuery.event.trigger( e, arguments[1], elem );
# +		}
# +	};
# +
# +	jQuery.event.special.change = {
# +		filters: {
# +			focusout: testChange,
# +
# +			beforedeactivate: testChange,
# +
# +			click: function( e ) {
# +				var elem = e.target, type = jQuery.nodeName( elem, "input" ) ? elem.type : "";
# +
# +				if ( type === "radio" || type === "checkbox" || jQuery.nodeName( elem, "select" ) ) {
# +					testChange.call( this, e );
# +				}
# +			},
# +
# +			// Change has to be called before submit
# +			// Keydown will be called before keypress, which is used in submit-event delegation
# +			keydown: function( e ) {
# +				var elem = e.target, type = jQuery.nodeName( elem, "input" ) ? elem.type : "";
# +
# +				if ( (e.keyCode === 13 && !jQuery.nodeName( elem, "textarea" ) ) ||
# +					(e.keyCode === 32 && (type === "checkbox" || type === "radio")) ||
# +					type === "select-multiple" ) {
# +					testChange.call( this, e );
# +				}
# +			},
# +
# +			// Beforeactivate happens also before the previous element is blurred
# +			// with this event you can't trigger a change event, but you can store
# +			// information
# +			beforeactivate: function( e ) {
# +				var elem = e.target;
# +				jQuery._data( elem, "_change_data", getVal(elem) );
# +			}
# +		},
# +
# +		setup: function( data, namespaces ) {
# +			if ( this.type === "file" ) {
# +				return false;
# +			}
# +
# +			for ( var type in changeFilters ) {
# +				jQuery.event.add( this, type + ".specialChange", changeFilters[type] );
# +			}
# +
# +			return rformElems.test( this.nodeName );
# +		},
# +
# +		teardown: function( namespaces ) {
# +			jQuery.event.remove( this, ".specialChange" );
# +
# +			return rformElems.test( this.nodeName );
# +		}
# +	};
# +
# +	changeFilters = jQuery.event.special.change.filters;
# +
# +	// Handle when the input is .focus()'d
# +	changeFilters.focus = changeFilters.beforeactivate;
# +}
# +
# +function trigger( type, elem, args ) {
# +	// Piggyback on a donor event to simulate a different one.
# +	// Fake originalEvent to avoid donor's stopPropagation, but if the
# +	// simulated event prevents default then we do the same on the donor.
# +	// Don't pass args or remember liveFired; they apply to the donor event.
# +	var event = jQuery.extend( {}, args[ 0 ] );
# +	event.type = type;
# +	event.originalEvent = {};
# +	event.liveFired = undefined;
# +	jQuery.event.handle.call( elem, event );
# +	if ( event.isDefaultPrevented() ) {
# +		args[ 0 ].preventDefault();
# +	}
# +}
# +
# +// Create "bubbling" focus and blur events
# +if ( !jQuery.support.focusinBubbles ) {
# +	jQuery.each({ focus: "focusin", blur: "focusout" }, function( orig, fix ) {
# +
# +		// Attach a single capturing handler while someone wants focusin/focusout
# +		var attaches = 0;
# +
# +		jQuery.event.special[ fix ] = {
# +			setup: function() {
# +				if ( attaches++ === 0 ) {
# +					document.addEventListener( orig, handler, true );
# +				}
# +			},
# +			teardown: function() {
# +				if ( --attaches === 0 ) {
# +					document.removeEventListener( orig, handler, true );
# +				}
# +			}
# +		};
# +
# +		function handler( donor ) {
# +			// Donor event is always a native one; fix it and switch its type.
# +			// Let focusin/out handler cancel the donor focus/blur event.
# +			var e = jQuery.event.fix( donor );
# +			e.type = fix;
# +			e.originalEvent = {};
# +			jQuery.event.trigger( e, null, e.target );
# +			if ( e.isDefaultPrevented() ) {
# +				donor.preventDefault();
# +			}
# +		}
# +	});
# +}
# +
# +jQuery.each(["bind", "one"], function( i, name ) {
# +	jQuery.fn[ name ] = function( type, data, fn ) {
# +		var handler;
# +
# +		// Handle object literals
# +		if ( typeof type === "object" ) {
# +			for ( var key in type ) {
# +				this[ name ](key, data, type[key], fn);
# +			}
# +			return this;
# +		}
# +
# +		if ( arguments.length === 2 || data === false ) {
# +			fn = data;
# +			data = undefined;
# +		}
# +
# +		if ( name === "one" ) {
# +			handler = function( event ) {
# +				jQuery( this ).unbind( event, handler );
# +				return fn.apply( this, arguments );
# +			};
# +			handler.guid = fn.guid || jQuery.guid++;
# +		} else {
# +			handler = fn;
# +		}
# +
# +		if ( type === "unload" && name !== "one" ) {
# +			this.one( type, data, fn );
# +
# +		} else {
# +			for ( var i = 0, l = this.length; i < l; i++ ) {
# +				jQuery.event.add( this[i], type, handler, data );
# +			}
# +		}
# +
# +		return this;
# +	};
# +});
# +
# +jQuery.fn.extend({
# +	unbind: function( type, fn ) {
# +		// Handle object literals
# +		if ( typeof type === "object" && !type.preventDefault ) {
# +			for ( var key in type ) {
# +				this.unbind(key, type[key]);
# +			}
# +
# +		} else {
# +			for ( var i = 0, l = this.length; i < l; i++ ) {
# +				jQuery.event.remove( this[i], type, fn );
# +			}
# +		}
# +
# +		return this;
# +	},
# +
# +	delegate: function( selector, types, data, fn ) {
# +		return this.live( types, data, fn, selector );
# +	},
# +
# +	undelegate: function( selector, types, fn ) {
# +		if ( arguments.length === 0 ) {
# +			return this.unbind( "live" );
# +
# +		} else {
# +			return this.die( types, null, fn, selector );
# +		}
# +	},
# +
# +	trigger: function( type, data ) {
# +		return this.each(function() {
# +			jQuery.event.trigger( type, data, this );
# +		});
# +	},
# +
# +	triggerHandler: function( type, data ) {
# +		if ( this[0] ) {
# +			return jQuery.event.trigger( type, data, this[0], true );
# +		}
# +	},
# +
# +	toggle: function( fn ) {
# +		// Save reference to arguments for access in closure
# +		var args = arguments,
# +			guid = fn.guid || jQuery.guid++,
# +			i = 0,
# +			toggler = function( event ) {
# +				// Figure out which function to execute
# +				var lastToggle = ( jQuery.data( this, "lastToggle" + fn.guid ) || 0 ) % i;
# +				jQuery.data( this, "lastToggle" + fn.guid, lastToggle + 1 );
# +
# +				// Make sure that clicks stop
# +				event.preventDefault();
# +
# +				// and execute the function
# +				return args[ lastToggle ].apply( this, arguments ) || false;
# +			};
# +
# +		// link all the functions, so any of them can unbind this click handler
# +		toggler.guid = guid;
# +		while ( i < args.length ) {
# +			args[ i++ ].guid = guid;
# +		}
# +
# +		return this.click( toggler );
# +	},
# +
# +	hover: function( fnOver, fnOut ) {
# +		return this.mouseenter( fnOver ).mouseleave( fnOut || fnOver );
# +	}
# +});
# +
# +var liveMap = {
# +	focus: "focusin",
# +	blur: "focusout",
# +	mouseenter: "mouseover",
# +	mouseleave: "mouseout"
# +};
# +
# +jQuery.each(["live", "die"], function( i, name ) {
# +	jQuery.fn[ name ] = function( types, data, fn, origSelector /* Internal Use Only */ ) {
# +		var type, i = 0, match, namespaces, preType,
# +			selector = origSelector || this.selector,
# +			context = origSelector ? this : jQuery( this.context );
# +
# +		if ( typeof types === "object" && !types.preventDefault ) {
# +			for ( var key in types ) {
# +				context[ name ]( key, data, types[key], selector );
# +			}
# +
# +			return this;
# +		}
# +
# +		if ( name === "die" && !types &&
# +					origSelector && origSelector.charAt(0) === "." ) {
# +
# +			context.unbind( origSelector );
# +
# +			return this;
# +		}
# +
# +		if ( data === false || jQuery.isFunction( data ) ) {
# +			fn = data || returnFalse;
# +			data = undefined;
# +		}
# +
# +		types = (types || "").split(" ");
# +
# +		while ( (type = types[ i++ ]) != null ) {
# +			match = rnamespaces.exec( type );
# +			namespaces = "";
# +
# +			if ( match )  {
# +				namespaces = match[0];
# +				type = type.replace( rnamespaces, "" );
# +			}
# +
# +			if ( type === "hover" ) {
# +				types.push( "mouseenter" + namespaces, "mouseleave" + namespaces );
# +				continue;
# +			}
# +
# +			preType = type;
# +
# +			if ( liveMap[ type ] ) {
# +				types.push( liveMap[ type ] + namespaces );
# +				type = type + namespaces;
# +
# +			} else {
# +				type = (liveMap[ type ] || type) + namespaces;
# +			}
# +
# +			if ( name === "live" ) {
# +				// bind live handler
# +				for ( var j = 0, l = context.length; j < l; j++ ) {
# +					jQuery.event.add( context[j], "live." + liveConvert( type, selector ),
# +						{ data: data, selector: selector, handler: fn, origType: type, origHandler: fn, preType: preType } );
# +				}
# +
# +			} else {
# +				// unbind live handler
# +				context.unbind( "live." + liveConvert( type, selector ), fn );
# +			}
# +		}
# +
# +		return this;
# +	};
# +});
# +
# +function liveHandler( event ) {
# +	var stop, maxLevel, related, match, handleObj, elem, j, i, l, data, close, namespace, ret,
# +		elems = [],
# +		selectors = [],
# +		events = jQuery._data( this, "events" );
# +
# +	// Make sure we avoid non-left-click bubbling in Firefox (#3861) and disabled elements in IE (#6911)
# +	if ( event.liveFired === this || !events || !events.live || event.target.disabled || event.button && event.type === "click" ) {
# +		return;
# +	}
# +
# +	if ( event.namespace ) {
# +		namespace = new RegExp("(^|\\.)" + event.namespace.split(".").join("\\.(?:.*\\.)?") + "(\\.|$)");
# +	}
# +
# +	event.liveFired = this;
# +
# +	var live = events.live.slice(0);
# +
# +	for ( j = 0; j < live.length; j++ ) {
# +		handleObj = live[j];
# +
# +		if ( handleObj.origType.replace( rnamespaces, "" ) === event.type ) {
# +			selectors.push( handleObj.selector );
# +
# +		} else {
# +			live.splice( j--, 1 );
# +		}
# +	}
# +
# +	match = jQuery( event.target ).closest( selectors, event.currentTarget );
# +
# +	for ( i = 0, l = match.length; i < l; i++ ) {
# +		close = match[i];
# +
# +		for ( j = 0; j < live.length; j++ ) {
# +			handleObj = live[j];
# +
# +			if ( close.selector === handleObj.selector && (!namespace || namespace.test( handleObj.namespace )) && !close.elem.disabled ) {
# +				elem = close.elem;
# +				related = null;
# +
# +				// Those two events require additional checking
# +				if ( handleObj.preType === "mouseenter" || handleObj.preType === "mouseleave" ) {
# +					event.type = handleObj.preType;
# +					related = jQuery( event.relatedTarget ).closest( handleObj.selector )[0];
# +
# +					// Make sure not to accidentally match a child element with the same selector
# +					if ( related && jQuery.contains( elem, related ) ) {
# +						related = elem;
# +					}
# +				}
# +
# +				if ( !related || related !== elem ) {
# +					elems.push({ elem: elem, handleObj: handleObj, level: close.level });
# +				}
# +			}
# +		}
# +	}
# +
# +	for ( i = 0, l = elems.length; i < l; i++ ) {
# +		match = elems[i];
# +
# +		if ( maxLevel && match.level > maxLevel ) {
# +			break;
# +		}
# +
# +		event.currentTarget = match.elem;
# +		event.data = match.handleObj.data;
# +		event.handleObj = match.handleObj;
# +
# +		ret = match.handleObj.origHandler.apply( match.elem, arguments );
# +
# +		if ( ret === false || event.isPropagationStopped() ) {
# +			maxLevel = match.level;
# +
# +			if ( ret === false ) {
# +				stop = false;
# +			}
# +			if ( event.isImmediatePropagationStopped() ) {
# +				break;
# +			}
# +		}
# +	}
# +
# +	return stop;
# +}
# +
# +function liveConvert( type, selector ) {
# +	return (type && type !== "*" ? type + "." : "") + selector.replace(rperiod, "`").replace(rspaces, "&");
# +}
# +
# +jQuery.each( ("blur focus focusin focusout load resize scroll unload click dblclick " +
# +	"mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave " +
# +	"change select submit keydown keypress keyup error").split(" "), function( i, name ) {
# +
# +	// Handle event binding
# +	jQuery.fn[ name ] = function( data, fn ) {
# +		if ( fn == null ) {
# +			fn = data;
# +			data = null;
# +		}
# +
# +		return arguments.length > 0 ?
# +			this.bind( name, data, fn ) :
# +			this.trigger( name );
# +	};
# +
# +	if ( jQuery.attrFn ) {
# +		jQuery.attrFn[ name ] = true;
# +	}
# +});
# +
# +
# +
# +/*!
# + * Sizzle CSS Selector Engine
# + *  Copyright 2011, The Dojo Foundation
# + *  Released under the MIT, BSD, and GPL Licenses.
# + *  More information: http://sizzlejs.com/
# + */
# +(function(){
# +
# +var chunker = /((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^\[\]]*\]|['"][^'"]*['"]|[^\[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g,
# +	done = 0,
# +	toString = Object.prototype.toString,
# +	hasDuplicate = false,
# +	baseHasDuplicate = true,
# +	rBackslash = /\\/g,
# +	rNonWord = /\W/;
# +
# +// Here we check if the JavaScript engine is using some sort of
# +// optimization where it does not always call our comparision
# +// function. If that is the case, discard the hasDuplicate value.
# +//   Thus far that includes Google Chrome.
# +[0, 0].sort(function() {
# +	baseHasDuplicate = false;
# +	return 0;
# +});
# +
# +var Sizzle = function( selector, context, results, seed ) {
# +	results = results || [];
# +	context = context || document;
# +
# +	var origContext = context;
# +
# +	if ( context.nodeType !== 1 && context.nodeType !== 9 ) {
# +		return [];
# +	}
# +
# +	if ( !selector || typeof selector !== "string" ) {
# +		return results;
# +	}
# +
# +	var m, set, checkSet, extra, ret, cur, pop, i,
# +		prune = true,
# +		contextXML = Sizzle.isXML( context ),
# +		parts = [],
# +		soFar = selector;
# +
# +	// Reset the position of the chunker regexp (start from head)
# +	do {
# +		chunker.exec( "" );
# +		m = chunker.exec( soFar );
# +
# +		if ( m ) {
# +			soFar = m[3];
# +
# +			parts.push( m[1] );
# +
# +			if ( m[2] ) {
# +				extra = m[3];
# +				break;
# +			}
# +		}
# +	} while ( m );
# +
# +	if ( parts.length > 1 && origPOS.exec( selector ) ) {
# +
# +		if ( parts.length === 2 && Expr.relative[ parts[0] ] ) {
# +			set = posProcess( parts[0] + parts[1], context );
# +
# +		} else {
# +			set = Expr.relative[ parts[0] ] ?
# +				[ context ] :
# +				Sizzle( parts.shift(), context );
# +
# +			while ( parts.length ) {
# +				selector = parts.shift();
# +
# +				if ( Expr.relative[ selector ] ) {
# +					selector += parts.shift();
# +				}
# +
# +				set = posProcess( selector, set );
# +			}
# +		}
# +
# +	} else {
# +		// Take a shortcut and set the context if the root selector is an ID
# +		// (but not if it'll be faster if the inner selector is an ID)
# +		if ( !seed && parts.length > 1 && context.nodeType === 9 && !contextXML &&
# +				Expr.match.ID.test(parts[0]) && !Expr.match.ID.test(parts[parts.length - 1]) ) {
# +
# +			ret = Sizzle.find( parts.shift(), context, contextXML );
# +			context = ret.expr ?
# +				Sizzle.filter( ret.expr, ret.set )[0] :
# +				ret.set[0];
# +		}
# +
# +		if ( context ) {
# +			ret = seed ?
# +				{ expr: parts.pop(), set: makeArray(seed) } :
# +				Sizzle.find( parts.pop(), parts.length === 1 && (parts[0] === "~" || parts[0] === "+") && context.parentNode ? context.parentNode : context, contextXML );
# +
# +			set = ret.expr ?
# +				Sizzle.filter( ret.expr, ret.set ) :
# +				ret.set;
# +
# +			if ( parts.length > 0 ) {
# +				checkSet = makeArray( set );
# +
# +			} else {
# +				prune = false;
# +			}
# +
# +			while ( parts.length ) {
# +				cur = parts.pop();
# +				pop = cur;
# +
# +				if ( !Expr.relative[ cur ] ) {
# +					cur = "";
# +				} else {
# +					pop = parts.pop();
# +				}
# +
# +				if ( pop == null ) {
# +					pop = context;
# +				}
# +
# +				Expr.relative[ cur ]( checkSet, pop, contextXML );
# +			}
# +
# +		} else {
# +			checkSet = parts = [];
# +		}
# +	}
# +
# +	if ( !checkSet ) {
# +		checkSet = set;
# +	}
# +
# +	if ( !checkSet ) {
# +		Sizzle.error( cur || selector );
# +	}
# +
# +	if ( toString.call(checkSet) === "[object Array]" ) {
# +		if ( !prune ) {
# +			results.push.apply( results, checkSet );
# +
# +		} else if ( context && context.nodeType === 1 ) {
# +			for ( i = 0; checkSet[i] != null; i++ ) {
# +				if ( checkSet[i] && (checkSet[i] === true || checkSet[i].nodeType === 1 && Sizzle.contains(context, checkSet[i])) ) {
# +					results.push( set[i] );
# +				}
# +			}
# +
# +		} else {
# +			for ( i = 0; checkSet[i] != null; i++ ) {
# +				if ( checkSet[i] && checkSet[i].nodeType === 1 ) {
# +					results.push( set[i] );
# +				}
# +			}
# +		}
# +
# +	} else {
# +		makeArray( checkSet, results );
# +	}
# +
# +	if ( extra ) {
# +		Sizzle( extra, origContext, results, seed );
# +		Sizzle.uniqueSort( results );
# +	}
# +
# +	return results;
# +};
# +
# +Sizzle.uniqueSort = function( results ) {
# +	if ( sortOrder ) {
# +		hasDuplicate = baseHasDuplicate;
# +		results.sort( sortOrder );
# +
# +		if ( hasDuplicate ) {
# +			for ( var i = 1; i < results.length; i++ ) {
# +				if ( results[i] === results[ i - 1 ] ) {
# +					results.splice( i--, 1 );
# +				}
# +			}
# +		}
# +	}
# +
# +	return results;
# +};
# +
# +Sizzle.matches = function( expr, set ) {
# +	return Sizzle( expr, null, null, set );
# +};
# +
# +Sizzle.matchesSelector = function( node, expr ) {
# +	return Sizzle( expr, null, null, [node] ).length > 0;
# +};
# +
# +Sizzle.find = function( expr, context, isXML ) {
# +	var set;
# +
# +	if ( !expr ) {
# +		return [];
# +	}
# +
# +	for ( var i = 0, l = Expr.order.length; i < l; i++ ) {
# +		var match,
# +			type = Expr.order[i];
# +
# +		if ( (match = Expr.leftMatch[ type ].exec( expr )) ) {
# +			var left = match[1];
# +			match.splice( 1, 1 );
# +
# +			if ( left.substr( left.length - 1 ) !== "\\" ) {
# +				match[1] = (match[1] || "").replace( rBackslash, "" );
# +				set = Expr.find[ type ]( match, context, isXML );
# +
# +				if ( set != null ) {
# +					expr = expr.replace( Expr.match[ type ], "" );
# +					break;
# +				}
# +			}
# +		}
# +	}
# +
# +	if ( !set ) {
# +		set = typeof context.getElementsByTagName !== "undefined" ?
# +			context.getElementsByTagName( "*" ) :
# +			[];
# +	}
# +
# +	return { set: set, expr: expr };
# +};
# +
# +Sizzle.filter = function( expr, set, inplace, not ) {
# +	var match, anyFound,
# +		old = expr,
# +		result = [],
# +		curLoop = set,
# +		isXMLFilter = set && set[0] && Sizzle.isXML( set[0] );
# +
# +	while ( expr && set.length ) {
# +		for ( var type in Expr.filter ) {
# +			if ( (match = Expr.leftMatch[ type ].exec( expr )) != null && match[2] ) {
# +				var found, item,
# +					filter = Expr.filter[ type ],
# +					left = match[1];
# +
# +				anyFound = false;
# +
# +				match.splice(1,1);
# +
# +				if ( left.substr( left.length - 1 ) === "\\" ) {
# +					continue;
# +				}
# +
# +				if ( curLoop === result ) {
# +					result = [];
# +				}
# +
# +				if ( Expr.preFilter[ type ] ) {
# +					match = Expr.preFilter[ type ]( match, curLoop, inplace, result, not, isXMLFilter );
# +
# +					if ( !match ) {
# +						anyFound = found = true;
# +
# +					} else if ( match === true ) {
# +						continue;
# +					}
# +				}
# +
# +				if ( match ) {
# +					for ( var i = 0; (item = curLoop[i]) != null; i++ ) {
# +						if ( item ) {
# +							found = filter( item, match, i, curLoop );
# +							var pass = not ^ !!found;
# +
# +							if ( inplace && found != null ) {
# +								if ( pass ) {
# +									anyFound = true;
# +
# +								} else {
# +									curLoop[i] = false;
# +								}
# +
# +							} else if ( pass ) {
# +								result.push( item );
# +								anyFound = true;
# +							}
# +						}
# +					}
# +				}
# +
# +				if ( found !== undefined ) {
# +					if ( !inplace ) {
# +						curLoop = result;
# +					}
# +
# +					expr = expr.replace( Expr.match[ type ], "" );
# +
# +					if ( !anyFound ) {
# +						return [];
# +					}
# +
# +					break;
# +				}
# +			}
# +		}
# +
# +		// Improper expression
# +		if ( expr === old ) {
# +			if ( anyFound == null ) {
# +				Sizzle.error( expr );
# +
# +			} else {
# +				break;
# +			}
# +		}
# +
# +		old = expr;
# +	}
# +
# +	return curLoop;
# +};
# +
# +Sizzle.error = function( msg ) {
# +	throw "Syntax error, unrecognized expression: " + msg;
# +};
# +
# +var Expr = Sizzle.selectors = {
# +	order: [ "ID", "NAME", "TAG" ],
# +
# +	match: {
# +		ID: /#((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,
# +		CLASS: /\.((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,
# +		NAME: /\[name=['"]*((?:[\w\u00c0-\uFFFF\-]|\\.)+)['"]*\]/,
# +		ATTR: /\[\s*((?:[\w\u00c0-\uFFFF\-]|\\.)+)\s*(?:(\S?=)\s*(?:(['"])(.*?)\3|(#?(?:[\w\u00c0-\uFFFF\-]|\\.)*)|)|)\s*\]/,
# +		TAG: /^((?:[\w\u00c0-\uFFFF\*\-]|\\.)+)/,
# +		CHILD: /:(only|nth|last|first)-child(?:\(\s*(even|odd|(?:[+\-]?\d+|(?:[+\-]?\d*)?n\s*(?:[+\-]\s*\d+)?))\s*\))?/,
# +		POS: /:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)/,
# +		PSEUDO: /:((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?/
# +	},
# +
# +	leftMatch: {},
# +
# +	attrMap: {
# +		"class": "className",
# +		"for": "htmlFor"
# +	},
# +
# +	attrHandle: {
# +		href: function( elem ) {
# +			return elem.getAttribute( "href" );
# +		},
# +		type: function( elem ) {
# +			return elem.getAttribute( "type" );
# +		}
# +	},
# +
# +	relative: {
# +		"+": function(checkSet, part){
# +			var isPartStr = typeof part === "string",
# +				isTag = isPartStr && !rNonWord.test( part ),
# +				isPartStrNotTag = isPartStr && !isTag;
# +
# +			if ( isTag ) {
# +				part = part.toLowerCase();
# +			}
# +
# +			for ( var i = 0, l = checkSet.length, elem; i < l; i++ ) {
# +				if ( (elem = checkSet[i]) ) {
# +					while ( (elem = elem.previousSibling) && elem.nodeType !== 1 ) {}
# +
# +					checkSet[i] = isPartStrNotTag || elem && elem.nodeName.toLowerCase() === part ?
# +						elem || false :
# +						elem === part;
# +				}
# +			}
# +
# +			if ( isPartStrNotTag ) {
# +				Sizzle.filter( part, checkSet, true );
# +			}
# +		},
# +
# +		">": function( checkSet, part ) {
# +			var elem,
# +				isPartStr = typeof part === "string",
# +				i = 0,
# +				l = checkSet.length;
# +
# +			if ( isPartStr && !rNonWord.test( part ) ) {
# +				part = part.toLowerCase();
# +
# +				for ( ; i < l; i++ ) {
# +					elem = checkSet[i];
# +
# +					if ( elem ) {
# +						var parent = elem.parentNode;
# +						checkSet[i] = parent.nodeName.toLowerCase() === part ? parent : false;
# +					}
# +				}
# +
# +			} else {
# +				for ( ; i < l; i++ ) {
# +					elem = checkSet[i];
# +
# +					if ( elem ) {
# +						checkSet[i] = isPartStr ?
# +							elem.parentNode :
# +							elem.parentNode === part;
# +					}
# +				}
# +
# +				if ( isPartStr ) {
# +					Sizzle.filter( part, checkSet, true );
# +				}
# +			}
# +		},
# +
# +		"": function(checkSet, part, isXML){
# +			var nodeCheck,
# +				doneName = done++,
# +				checkFn = dirCheck;
# +
# +			if ( typeof part === "string" && !rNonWord.test( part ) ) {
# +				part = part.toLowerCase();
# +				nodeCheck = part;
# +				checkFn = dirNodeCheck;
# +			}
# +
# +			checkFn( "parentNode", part, doneName, checkSet, nodeCheck, isXML );
# +		},
# +
# +		"~": function( checkSet, part, isXML ) {
# +			var nodeCheck,
# +				doneName = done++,
# +				checkFn = dirCheck;
# +
# +			if ( typeof part === "string" && !rNonWord.test( part ) ) {
# +				part = part.toLowerCase();
# +				nodeCheck = part;
# +				checkFn = dirNodeCheck;
# +			}
# +
# +			checkFn( "previousSibling", part, doneName, checkSet, nodeCheck, isXML );
# +		}
# +	},
# +
# +	find: {
# +		ID: function( match, context, isXML ) {
# +			if ( typeof context.getElementById !== "undefined" && !isXML ) {
# +				var m = context.getElementById(match[1]);
# +				// Check parentNode to catch when Blackberry 4.6 returns
# +				// nodes that are no longer in the document #6963
# +				return m && m.parentNode ? [m] : [];
# +			}
# +		},
# +
# +		NAME: function( match, context ) {
# +			if ( typeof context.getElementsByName !== "undefined" ) {
# +				var ret = [],
# +					results = context.getElementsByName( match[1] );
# +
# +				for ( var i = 0, l = results.length; i < l; i++ ) {
# +					if ( results[i].getAttribute("name") === match[1] ) {
# +						ret.push( results[i] );
# +					}
# +				}
# +
# +				return ret.length === 0 ? null : ret;
# +			}
# +		},
# +
# +		TAG: function( match, context ) {
# +			if ( typeof context.getElementsByTagName !== "undefined" ) {
# +				return context.getElementsByTagName( match[1] );
# +			}
# +		}
# +	},
# +	preFilter: {
# +		CLASS: function( match, curLoop, inplace, result, not, isXML ) {
# +			match = " " + match[1].replace( rBackslash, "" ) + " ";
# +
# +			if ( isXML ) {
# +				return match;
# +			}
# +
# +			for ( var i = 0, elem; (elem = curLoop[i]) != null; i++ ) {
# +				if ( elem ) {
# +					if ( not ^ (elem.className && (" " + elem.className + " ").replace(/[\t\n\r]/g, " ").indexOf(match) >= 0) ) {
# +						if ( !inplace ) {
# +							result.push( elem );
# +						}
# +
# +					} else if ( inplace ) {
# +						curLoop[i] = false;
# +					}
# +				}
# +			}
# +
# +			return false;
# +		},
# +
# +		ID: function( match ) {
# +			return match[1].replace( rBackslash, "" );
# +		},
# +
# +		TAG: function( match, curLoop ) {
# +			return match[1].replace( rBackslash, "" ).toLowerCase();
# +		},
# +
# +		CHILD: function( match ) {
# +			if ( match[1] === "nth" ) {
# +				if ( !match[2] ) {
# +					Sizzle.error( match[0] );
# +				}
# +
# +				match[2] = match[2].replace(/^\+|\s*/g, '');
# +
# +				// parse equations like 'even', 'odd', '5', '2n', '3n+2', '4n-1', '-n+6'
# +				var test = /(-?)(\d*)(?:n([+\-]?\d*))?/.exec(
# +					match[2] === "even" && "2n" || match[2] === "odd" && "2n+1" ||
# +					!/\D/.test( match[2] ) && "0n+" + match[2] || match[2]);
# +
# +				// calculate the numbers (first)n+(last) including if they are negative
# +				match[2] = (test[1] + (test[2] || 1)) - 0;
# +				match[3] = test[3] - 0;
# +			}
# +			else if ( match[2] ) {
# +				Sizzle.error( match[0] );
# +			}
# +
# +			// TODO: Move to normal caching system
# +			match[0] = done++;
# +
# +			return match;
# +		},
# +
# +		ATTR: function( match, curLoop, inplace, result, not, isXML ) {
# +			var name = match[1] = match[1].replace( rBackslash, "" );
# +
# +			if ( !isXML && Expr.attrMap[name] ) {
# +				match[1] = Expr.attrMap[name];
# +			}
# +
# +			// Handle if an un-quoted value was used
# +			match[4] = ( match[4] || match[5] || "" ).replace( rBackslash, "" );
# +
# +			if ( match[2] === "~=" ) {
# +				match[4] = " " + match[4] + " ";
# +			}
# +
# +			return match;
# +		},
# +
# +		PSEUDO: function( match, curLoop, inplace, result, not ) {
# +			if ( match[1] === "not" ) {
# +				// If we're dealing with a complex expression, or a simple one
# +				if ( ( chunker.exec(match[3]) || "" ).length > 1 || /^\w/.test(match[3]) ) {
# +					match[3] = Sizzle(match[3], null, null, curLoop);
# +
# +				} else {
# +					var ret = Sizzle.filter(match[3], curLoop, inplace, true ^ not);
# +
# +					if ( !inplace ) {
# +						result.push.apply( result, ret );
# +					}
# +
# +					return false;
# +				}
# +
# +			} else if ( Expr.match.POS.test( match[0] ) || Expr.match.CHILD.test( match[0] ) ) {
# +				return true;
# +			}
# +
# +			return match;
# +		},
# +
# +		POS: function( match ) {
# +			match.unshift( true );
# +
# +			return match;
# +		}
# +	},
# +
# +	filters: {
# +		enabled: function( elem ) {
# +			return elem.disabled === false && elem.type !== "hidden";
# +		},
# +
# +		disabled: function( elem ) {
# +			return elem.disabled === true;
# +		},
# +
# +		checked: function( elem ) {
# +			return elem.checked === true;
# +		},
# +
# +		selected: function( elem ) {
# +			// Accessing this property makes selected-by-default
# +			// options in Safari work properly
# +			if ( elem.parentNode ) {
# +				elem.parentNode.selectedIndex;
# +			}
# +
# +			return elem.selected === true;
# +		},
# +
# +		parent: function( elem ) {
# +			return !!elem.firstChild;
# +		},
# +
# +		empty: function( elem ) {
# +			return !elem.firstChild;
# +		},
# +
# +		has: function( elem, i, match ) {
# +			return !!Sizzle( match[3], elem ).length;
# +		},
# +
# +		header: function( elem ) {
# +			return (/h\d/i).test( elem.nodeName );
# +		},
# +
# +		text: function( elem ) {
# +			var attr = elem.getAttribute( "type" ), type = elem.type;
# +			// IE6 and 7 will map elem.type to 'text' for new HTML5 types (search, etc)
# +			// use getAttribute instead to test this case
# +			return elem.nodeName.toLowerCase() === "input" && "text" === type && ( attr === type || attr === null );
# +		},
# +
# +		radio: function( elem ) {
# +			return elem.nodeName.toLowerCase() === "input" && "radio" === elem.type;
# +		},
# +
# +		checkbox: function( elem ) {
# +			return elem.nodeName.toLowerCase() === "input" && "checkbox" === elem.type;
# +		},
# +
# +		file: function( elem ) {
# +			return elem.nodeName.toLowerCase() === "input" && "file" === elem.type;
# +		},
# +
# +		password: function( elem ) {
# +			return elem.nodeName.toLowerCase() === "input" && "password" === elem.type;
# +		},
# +
# +		submit: function( elem ) {
# +			var name = elem.nodeName.toLowerCase();
# +			return (name === "input" || name === "button") && "submit" === elem.type;
# +		},
# +
# +		image: function( elem ) {
# +			return elem.nodeName.toLowerCase() === "input" && "image" === elem.type;
# +		},
# +
# +		reset: function( elem ) {
# +			var name = elem.nodeName.toLowerCase();
# +			return (name === "input" || name === "button") && "reset" === elem.type;
# +		},
# +
# +		button: function( elem ) {
# +			var name = elem.nodeName.toLowerCase();
# +			return name === "input" && "button" === elem.type || name === "button";
# +		},
# +
# +		input: function( elem ) {
# +			return (/input|select|textarea|button/i).test( elem.nodeName );
# +		},
# +
# +		focus: function( elem ) {
# +			return elem === elem.ownerDocument.activeElement;
# +		}
# +	},
# +	setFilters: {
# +		first: function( elem, i ) {
# +			return i === 0;
# +		},
# +
# +		last: function( elem, i, match, array ) {
# +			return i === array.length - 1;
# +		},
# +
# +		even: function( elem, i ) {
# +			return i % 2 === 0;
# +		},
# +
# +		odd: function( elem, i ) {
# +			return i % 2 === 1;
# +		},
# +
# +		lt: function( elem, i, match ) {
# +			return i < match[3] - 0;
# +		},
# +
# +		gt: function( elem, i, match ) {
# +			return i > match[3] - 0;
# +		},
# +
# +		nth: function( elem, i, match ) {
# +			return match[3] - 0 === i;
# +		},
# +
# +		eq: function( elem, i, match ) {
# +			return match[3] - 0 === i;
# +		}
# +	},
# +	filter: {
# +		PSEUDO: function( elem, match, i, array ) {
# +			var name = match[1],
# +				filter = Expr.filters[ name ];
# +
# +			if ( filter ) {
# +				return filter( elem, i, match, array );
# +
# +			} else if ( name === "contains" ) {
# +				return (elem.textContent || elem.innerText || Sizzle.getText([ elem ]) || "").indexOf(match[3]) >= 0;
# +
# +			} else if ( name === "not" ) {
# +				var not = match[3];
# +
# +				for ( var j = 0, l = not.length; j < l; j++ ) {
# +					if ( not[j] === elem ) {
# +						return false;
# +					}
# +				}
# +
# +				return true;
# +
# +			} else {
# +				Sizzle.error( name );
# +			}
# +		},
# +
# +		CHILD: function( elem, match ) {
# +			var type = match[1],
# +				node = elem;
# +
# +			switch ( type ) {
# +				case "only":
# +				case "first":
# +					while ( (node = node.previousSibling) )	 {
# +						if ( node.nodeType === 1 ) {
# +							return false;
# +						}
# +					}
# +
# +					if ( type === "first" ) {
# +						return true;
# +					}
# +
# +					node = elem;
# +
# +				case "last":
# +					while ( (node = node.nextSibling) )	 {
# +						if ( node.nodeType === 1 ) {
# +							return false;
# +						}
# +					}
# +
# +					return true;
# +
# +				case "nth":
# +					var first = match[2],
# +						last = match[3];
# +
# +					if ( first === 1 && last === 0 ) {
# +						return true;
# +					}
# +
# +					var doneName = match[0],
# +						parent = elem.parentNode;
# +
# +					if ( parent && (parent.sizcache !== doneName || !elem.nodeIndex) ) {
# +						var count = 0;
# +
# +						for ( node = parent.firstChild; node; node = node.nextSibling ) {
# +							if ( node.nodeType === 1 ) {
# +								node.nodeIndex = ++count;
# +							}
# +						}
# +
# +						parent.sizcache = doneName;
# +					}
# +
# +					var diff = elem.nodeIndex - last;
# +
# +					if ( first === 0 ) {
# +						return diff === 0;
# +
# +					} else {
# +						return ( diff % first === 0 && diff / first >= 0 );
# +					}
# +			}
# +		},
# +
# +		ID: function( elem, match ) {
# +			return elem.nodeType === 1 && elem.getAttribute("id") === match;
# +		},
# +
# +		TAG: function( elem, match ) {
# +			return (match === "*" && elem.nodeType === 1) || elem.nodeName.toLowerCase() === match;
# +		},
# +
# +		CLASS: function( elem, match ) {
# +			return (" " + (elem.className || elem.getAttribute("class")) + " ")
# +				.indexOf( match ) > -1;
# +		},
# +
# +		ATTR: function( elem, match ) {
# +			var name = match[1],
# +				result = Expr.attrHandle[ name ] ?
# +					Expr.attrHandle[ name ]( elem ) :
# +					elem[ name ] != null ?
# +						elem[ name ] :
# +						elem.getAttribute( name ),
# +				value = result + "",
# +				type = match[2],
# +				check = match[4];
# +
# +			return result == null ?
# +				type === "!=" :
# +				type === "=" ?
# +				value === check :
# +				type === "*=" ?
# +				value.indexOf(check) >= 0 :
# +				type === "~=" ?
# +				(" " + value + " ").indexOf(check) >= 0 :
# +				!check ?
# +				value && result !== false :
# +				type === "!=" ?
# +				value !== check :
# +				type === "^=" ?
# +				value.indexOf(check) === 0 :
# +				type === "$=" ?
# +				value.substr(value.length - check.length) === check :
# +				type === "|=" ?
# +				value === check || value.substr(0, check.length + 1) === check + "-" :
# +				false;
# +		},
# +
# +		POS: function( elem, match, i, array ) {
# +			var name = match[2],
# +				filter = Expr.setFilters[ name ];
# +
# +			if ( filter ) {
# +				return filter( elem, i, match, array );
# +			}
# +		}
# +	}
# +};
# +
# +var origPOS = Expr.match.POS,
# +	fescape = function(all, num){
# +		return "\\" + (num - 0 + 1);
# +	};
# +
# +for ( var type in Expr.match ) {
# +	Expr.match[ type ] = new RegExp( Expr.match[ type ].source + (/(?![^\[]*\])(?![^\(]*\))/.source) );
# +	Expr.leftMatch[ type ] = new RegExp( /(^(?:.|\r|\n)*?)/.source + Expr.match[ type ].source.replace(/\\(\d+)/g, fescape) );
# +}
# +
# +var makeArray = function( array, results ) {
# +	array = Array.prototype.slice.call( array, 0 );
# +
# +	if ( results ) {
# +		results.push.apply( results, array );
# +		return results;
# +	}
# +
# +	return array;
# +};
# +
# +// Perform a simple check to determine if the browser is capable of
# +// converting a NodeList to an array using builtin methods.
# +// Also verifies that the returned array holds DOM nodes
# +// (which is not the case in the Blackberry browser)
# +try {
# +	Array.prototype.slice.call( document.documentElement.childNodes, 0 )[0].nodeType;
# +
# +// Provide a fallback method if it does not work
# +} catch( e ) {
# +	makeArray = function( array, results ) {
# +		var i = 0,
# +			ret = results || [];
# +
# +		if ( toString.call(array) === "[object Array]" ) {
# +			Array.prototype.push.apply( ret, array );
# +
# +		} else {
# +			if ( typeof array.length === "number" ) {
# +				for ( var l = array.length; i < l; i++ ) {
# +					ret.push( array[i] );
# +				}
# +
# +			} else {
# +				for ( ; array[i]; i++ ) {
# +					ret.push( array[i] );
# +				}
# +			}
# +		}
# +
# +		return ret;
# +	};
# +}
# +
# +var sortOrder, siblingCheck;
# +
# +if ( document.documentElement.compareDocumentPosition ) {
# +	sortOrder = function( a, b ) {
# +		if ( a === b ) {
# +			hasDuplicate = true;
# +			return 0;
# +		}
# +
# +		if ( !a.compareDocumentPosition || !b.compareDocumentPosition ) {
# +			return a.compareDocumentPosition ? -1 : 1;
# +		}
# +
# +		return a.compareDocumentPosition(b) & 4 ? -1 : 1;
# +	};
# +
# +} else {
# +	sortOrder = function( a, b ) {
# +		// The nodes are identical, we can exit early
# +		if ( a === b ) {
# +			hasDuplicate = true;
# +			return 0;
# +
# +		// Fallback to using sourceIndex (in IE) if it's available on both nodes
# +		} else if ( a.sourceIndex && b.sourceIndex ) {
# +			return a.sourceIndex - b.sourceIndex;
# +		}
# +
# +		var al, bl,
# +			ap = [],
# +			bp = [],
# +			aup = a.parentNode,
# +			bup = b.parentNode,
# +			cur = aup;
# +
# +		// If the nodes are siblings (or identical) we can do a quick check
# +		if ( aup === bup ) {
# +			return siblingCheck( a, b );
# +
# +		// If no parents were found then the nodes are disconnected
# +		} else if ( !aup ) {
# +			return -1;
# +
# +		} else if ( !bup ) {
# +			return 1;
# +		}
# +
# +		// Otherwise they're somewhere else in the tree so we need
# +		// to build up a full list of the parentNodes for comparison
# +		while ( cur ) {
# +			ap.unshift( cur );
# +			cur = cur.parentNode;
# +		}
# +
# +		cur = bup;
# +
# +		while ( cur ) {
# +			bp.unshift( cur );
# +			cur = cur.parentNode;
# +		}
# +
# +		al = ap.length;
# +		bl = bp.length;
# +
# +		// Start walking down the tree looking for a discrepancy
# +		for ( var i = 0; i < al && i < bl; i++ ) {
# +			if ( ap[i] !== bp[i] ) {
# +				return siblingCheck( ap[i], bp[i] );
# +			}
# +		}
# +
# +		// We ended someplace up the tree so do a sibling check
# +		return i === al ?
# +			siblingCheck( a, bp[i], -1 ) :
# +			siblingCheck( ap[i], b, 1 );
# +	};
# +
# +	siblingCheck = function( a, b, ret ) {
# +		if ( a === b ) {
# +			return ret;
# +		}
# +
# +		var cur = a.nextSibling;
# +
# +		while ( cur ) {
# +			if ( cur === b ) {
# +				return -1;
# +			}
# +
# +			cur = cur.nextSibling;
# +		}
# +
# +		return 1;
# +	};
# +}
# +
# +// Utility function for retreiving the text value of an array of DOM nodes
# +Sizzle.getText = function( elems ) {
# +	var ret = "", elem;
# +
# +	for ( var i = 0; elems[i]; i++ ) {
# +		elem = elems[i];
# +
# +		// Get the text from text nodes and CDATA nodes
# +		if ( elem.nodeType === 3 || elem.nodeType === 4 ) {
# +			ret += elem.nodeValue;
# +
# +		// Traverse everything else, except comment nodes
# +		} else if ( elem.nodeType !== 8 ) {
# +			ret += Sizzle.getText( elem.childNodes );
# +		}
# +	}
# +
# +	return ret;
# +};
# +
# +// Check to see if the browser returns elements by name when
# +// querying by getElementById (and provide a workaround)
# +(function(){
# +	// We're going to inject a fake input element with a specified name
# +	var form = document.createElement("div"),
# +		id = "script" + (new Date()).getTime(),
# +		root = document.documentElement;
# +
# +	form.innerHTML = "<a name='" + id + "'/>";
# +
# +	// Inject it into the root element, check its status, and remove it quickly
# +	root.insertBefore( form, root.firstChild );
# +
# +	// The workaround has to do additional checks after a getElementById
# +	// Which slows things down for other browsers (hence the branching)
# +	if ( document.getElementById( id ) ) {
# +		Expr.find.ID = function( match, context, isXML ) {
# +			if ( typeof context.getElementById !== "undefined" && !isXML ) {
# +				var m = context.getElementById(match[1]);
# +
# +				return m ?
# +					m.id === match[1] || typeof m.getAttributeNode !== "undefined" && m.getAttributeNode("id").nodeValue === match[1] ?
# +						[m] :
# +						undefined :
# +					[];
# +			}
# +		};
# +
# +		Expr.filter.ID = function( elem, match ) {
# +			var node = typeof elem.getAttributeNode !== "undefined" && elem.getAttributeNode("id");
# +
# +			return elem.nodeType === 1 && node && node.nodeValue === match;
# +		};
# +	}
# +
# +	root.removeChild( form );
# +
# +	// release memory in IE
# +	root = form = null;
# +})();
# +
# +(function(){
# +	// Check to see if the browser returns only elements
# +	// when doing getElementsByTagName("*")
# +
# +	// Create a fake element
# +	var div = document.createElement("div");
# +	div.appendChild( document.createComment("") );
# +
# +	// Make sure no comments are found
# +	if ( div.getElementsByTagName("*").length > 0 ) {
# +		Expr.find.TAG = function( match, context ) {
# +			var results = context.getElementsByTagName( match[1] );
# +
# +			// Filter out possible comments
# +			if ( match[1] === "*" ) {
# +				var tmp = [];
# +
# +				for ( var i = 0; results[i]; i++ ) {
# +					if ( results[i].nodeType === 1 ) {
# +						tmp.push( results[i] );
# +					}
# +				}
# +
# +				results = tmp;
# +			}
# +
# +			return results;
# +		};
# +	}
# +
# +	// Check to see if an attribute returns normalized href attributes
# +	div.innerHTML = "<a href='#'></a>";
# +
# +	if ( div.firstChild && typeof div.firstChild.getAttribute !== "undefined" &&
# +			div.firstChild.getAttribute("href") !== "#" ) {
# +
# +		Expr.attrHandle.href = function( elem ) {
# +			return elem.getAttribute( "href", 2 );
# +		};
# +	}
# +
# +	// release memory in IE
# +	div = null;
# +})();
# +
# +if ( document.querySelectorAll ) {
# +	(function(){
# +		var oldSizzle = Sizzle,
# +			div = document.createElement("div"),
# +			id = "__sizzle__";
# +
# +		div.innerHTML = "<p class='TEST'></p>";
# +
# +		// Safari can't handle uppercase or unicode characters when
# +		// in quirks mode.
# +		if ( div.querySelectorAll && div.querySelectorAll(".TEST").length === 0 ) {
# +			return;
# +		}
# +
# +		Sizzle = function( query, context, extra, seed ) {
# +			context = context || document;
# +
# +			// Only use querySelectorAll on non-XML documents
# +			// (ID selectors don't work in non-HTML documents)
# +			if ( !seed && !Sizzle.isXML(context) ) {
# +				// See if we find a selector to speed up
# +				var match = /^(\w+$)|^\.([\w\-]+$)|^#([\w\-]+$)/.exec( query );
# +
# +				if ( match && (context.nodeType === 1 || context.nodeType === 9) ) {
# +					// Speed-up: Sizzle("TAG")
# +					if ( match[1] ) {
# +						return makeArray( context.getElementsByTagName( query ), extra );
# +
# +					// Speed-up: Sizzle(".CLASS")
# +					} else if ( match[2] && Expr.find.CLASS && context.getElementsByClassName ) {
# +						return makeArray( context.getElementsByClassName( match[2] ), extra );
# +					}
# +				}
# +
# +				if ( context.nodeType === 9 ) {
# +					// Speed-up: Sizzle("body")
# +					// The body element only exists once, optimize finding it
# +					if ( query === "body" && context.body ) {
# +						return makeArray( [ context.body ], extra );
# +
# +					// Speed-up: Sizzle("#ID")
# +					} else if ( match && match[3] ) {
# +						var elem = context.getElementById( match[3] );
# +
# +						// Check parentNode to catch when Blackberry 4.6 returns
# +						// nodes that are no longer in the document #6963
# +						if ( elem && elem.parentNode ) {
# +							// Handle the case where IE and Opera return items
# +							// by name instead of ID
# +							if ( elem.id === match[3] ) {
# +								return makeArray( [ elem ], extra );
# +							}
# +
# +						} else {
# +							return makeArray( [], extra );
# +						}
# +					}
# +
# +					try {
# +						return makeArray( context.querySelectorAll(query), extra );
# +					} catch(qsaError) {}
# +
# +				// qSA works strangely on Element-rooted queries
# +				// We can work around this by specifying an extra ID on the root
# +				// and working up from there (Thanks to Andrew Dupont for the technique)
# +				// IE 8 doesn't work on object elements
# +				} else if ( context.nodeType === 1 && context.nodeName.toLowerCase() !== "object" ) {
# +					var oldContext = context,
# +						old = context.getAttribute( "id" ),
# +						nid = old || id,
# +						hasParent = context.parentNode,
# +						relativeHierarchySelector = /^\s*[+~]/.test( query );
# +
# +					if ( !old ) {
# +						context.setAttribute( "id", nid );
# +					} else {
# +						nid = nid.replace( /'/g, "\\$&" );
# +					}
# +					if ( relativeHierarchySelector && hasParent ) {
# +						context = context.parentNode;
# +					}
# +
# +					try {
# +						if ( !relativeHierarchySelector || hasParent ) {
# +							return makeArray( context.querySelectorAll( "[id='" + nid + "'] " + query ), extra );
# +						}
# +
# +					} catch(pseudoError) {
# +					} finally {
# +						if ( !old ) {
# +							oldContext.removeAttribute( "id" );
# +						}
# +					}
# +				}
# +			}
# +
# +			return oldSizzle(query, context, extra, seed);
# +		};
# +
# +		for ( var prop in oldSizzle ) {
# +			Sizzle[ prop ] = oldSizzle[ prop ];
# +		}
# +
# +		// release memory in IE
# +		div = null;
# +	})();
# +}
# +
# +(function(){
# +	var html = document.documentElement,
# +		matches = html.matchesSelector || html.mozMatchesSelector || html.webkitMatchesSelector || html.msMatchesSelector;
# +
# +	if ( matches ) {
# +		// Check to see if it's possible to do matchesSelector
# +		// on a disconnected node (IE 9 fails this)
# +		var disconnectedMatch = !matches.call( document.createElement( "div" ), "div" ),
# +			pseudoWorks = false;
# +
# +		try {
# +			// This should fail with an exception
# +			// Gecko does not error, returns false instead
# +			matches.call( document.documentElement, "[test!='']:sizzle" );
# +
# +		} catch( pseudoError ) {
# +			pseudoWorks = true;
# +		}
# +
# +		Sizzle.matchesSelector = function( node, expr ) {
# +			// Make sure that attribute selectors are quoted
# +			expr = expr.replace(/\=\s*([^'"\]]*)\s*\]/g, "='$1']");
# +
# +			if ( !Sizzle.isXML( node ) ) {
# +				try {
# +					if ( pseudoWorks || !Expr.match.PSEUDO.test( expr ) && !/!=/.test( expr ) ) {
# +						var ret = matches.call( node, expr );
# +
# +						// IE 9's matchesSelector returns false on disconnected nodes
# +						if ( ret || !disconnectedMatch ||
# +								// As well, disconnected nodes are said to be in a document
# +								// fragment in IE 9, so check for that
# +								node.document && node.document.nodeType !== 11 ) {
# +							return ret;
# +						}
# +					}
# +				} catch(e) {}
# +			}
# +
# +			return Sizzle(expr, null, null, [node]).length > 0;
# +		};
# +	}
# +})();
# +
# +(function(){
# +	var div = document.createElement("div");
# +
# +	div.innerHTML = "<div class='test e'></div><div class='test'></div>";
# +
# +	// Opera can't find a second classname (in 9.6)
# +	// Also, make sure that getElementsByClassName actually exists
# +	if ( !div.getElementsByClassName || div.getElementsByClassName("e").length === 0 ) {
# +		return;
# +	}
# +
# +	// Safari caches class attributes, doesn't catch changes (in 3.2)
# +	div.lastChild.className = "e";
# +
# +	if ( div.getElementsByClassName("e").length === 1 ) {
# +		return;
# +	}
# +
# +	Expr.order.splice(1, 0, "CLASS");
# +	Expr.find.CLASS = function( match, context, isXML ) {
# +		if ( typeof context.getElementsByClassName !== "undefined" && !isXML ) {
# +			return context.getElementsByClassName(match[1]);
# +		}
# +	};
# +
# +	// release memory in IE
# +	div = null;
# +})();
# +
# +function dirNodeCheck( dir, cur, doneName, checkSet, nodeCheck, isXML ) {
# +	for ( var i = 0, l = checkSet.length; i < l; i++ ) {
# +		var elem = checkSet[i];
# +
# +		if ( elem ) {
# +			var match = false;
# +
# +			elem = elem[dir];
# +
# +			while ( elem ) {
# +				if ( elem.sizcache === doneName ) {
# +					match = checkSet[elem.sizset];
# +					break;
# +				}
# +
# +				if ( elem.nodeType === 1 && !isXML ){
# +					elem.sizcache = doneName;
# +					elem.sizset = i;
# +				}
# +
# +				if ( elem.nodeName.toLowerCase() === cur ) {
# +					match = elem;
# +					break;
# +				}
# +
# +				elem = elem[dir];
# +			}
# +
# +			checkSet[i] = match;
# +		}
# +	}
# +}
# +
# +function dirCheck( dir, cur, doneName, checkSet, nodeCheck, isXML ) {
# +	for ( var i = 0, l = checkSet.length; i < l; i++ ) {
# +		var elem = checkSet[i];
# +
# +		if ( elem ) {
# +			var match = false;
# +
# +			elem = elem[dir];
# +
# +			while ( elem ) {
# +				if ( elem.sizcache === doneName ) {
# +					match = checkSet[elem.sizset];
# +					break;
# +				}
# +
# +				if ( elem.nodeType === 1 ) {
# +					if ( !isXML ) {
# +						elem.sizcache = doneName;
# +						elem.sizset = i;
# +					}
# +
# +					if ( typeof cur !== "string" ) {
# +						if ( elem === cur ) {
# +							match = true;
# +							break;
# +						}
# +
# +					} else if ( Sizzle.filter( cur, [elem] ).length > 0 ) {
# +						match = elem;
# +						break;
# +					}
# +				}
# +
# +				elem = elem[dir];
# +			}
# +
# +			checkSet[i] = match;
# +		}
# +	}
# +}
# +
# +if ( document.documentElement.contains ) {
# +	Sizzle.contains = function( a, b ) {
# +		return a !== b && (a.contains ? a.contains(b) : true);
# +	};
# +
# +} else if ( document.documentElement.compareDocumentPosition ) {
# +	Sizzle.contains = function( a, b ) {
# +		return !!(a.compareDocumentPosition(b) & 16);
# +	};
# +
# +} else {
# +	Sizzle.contains = function() {
# +		return false;
# +	};
# +}
# +
# +Sizzle.isXML = function( elem ) {
# +	// documentElement is verified for cases where it doesn't yet exist
# +	// (such as loading iframes in IE - #4833)
# +	var documentElement = (elem ? elem.ownerDocument || elem : 0).documentElement;
# +
# +	return documentElement ? documentElement.nodeName !== "HTML" : false;
# +};
# +
# +var posProcess = function( selector, context ) {
# +	var match,
# +		tmpSet = [],
# +		later = "",
# +		root = context.nodeType ? [context] : context;
# +
# +	// Position selectors must be done after the filter
# +	// And so must :not(positional) so we move all PSEUDOs to the end
# +	while ( (match = Expr.match.PSEUDO.exec( selector )) ) {
# +		later += match[0];
# +		selector = selector.replace( Expr.match.PSEUDO, "" );
# +	}
# +
# +	selector = Expr.relative[selector] ? selector + "*" : selector;
# +
# +	for ( var i = 0, l = root.length; i < l; i++ ) {
# +		Sizzle( selector, root[i], tmpSet );
# +	}
# +
# +	return Sizzle.filter( later, tmpSet );
# +};
# +
# +// EXPOSE
# +jQuery.find = Sizzle;
# +jQuery.expr = Sizzle.selectors;
# +jQuery.expr[":"] = jQuery.expr.filters;
# +jQuery.unique = Sizzle.uniqueSort;
# +jQuery.text = Sizzle.getText;
# +jQuery.isXMLDoc = Sizzle.isXML;
# +jQuery.contains = Sizzle.contains;
# +
# +
# +})();
# +
# +
# +var runtil = /Until$/,
# +	rparentsprev = /^(?:parents|prevUntil|prevAll)/,
# +	// Note: This RegExp should be improved, or likely pulled from Sizzle
# +	rmultiselector = /,/,
# +	isSimple = /^.[^:#\[\.,]*$/,
# +	slice = Array.prototype.slice,
# +	POS = jQuery.expr.match.POS,
# +	// methods guaranteed to produce a unique set when starting from a unique set
# +	guaranteedUnique = {
# +		children: true,
# +		contents: true,
# +		next: true,
# +		prev: true
# +	};
# +
# +jQuery.fn.extend({
# +	find: function( selector ) {
# +		var self = this,
# +			i, l;
# +
# +		if ( typeof selector !== "string" ) {
# +			return jQuery( selector ).filter(function() {
# +				for ( i = 0, l = self.length; i < l; i++ ) {
# +					if ( jQuery.contains( self[ i ], this ) ) {
# +						return true;
# +					}
# +				}
# +			});
# +		}
# +
# +		var ret = this.pushStack( "", "find", selector ),
# +			length, n, r;
# +
# +		for ( i = 0, l = this.length; i < l; i++ ) {
# +			length = ret.length;
# +			jQuery.find( selector, this[i], ret );
# +
# +			if ( i > 0 ) {
# +				// Make sure that the results are unique
# +				for ( n = length; n < ret.length; n++ ) {
# +					for ( r = 0; r < length; r++ ) {
# +						if ( ret[r] === ret[n] ) {
# +							ret.splice(n--, 1);
# +							break;
# +						}
# +					}
# +				}
# +			}
# +		}
# +
# +		return ret;
# +	},
# +
# +	has: function( target ) {
# +		var targets = jQuery( target );
# +		return this.filter(function() {
# +			for ( var i = 0, l = targets.length; i < l; i++ ) {
# +				if ( jQuery.contains( this, targets[i] ) ) {
# +					return true;
# +				}
# +			}
# +		});
# +	},
# +
# +	not: function( selector ) {
# +		return this.pushStack( winnow(this, selector, false), "not", selector);
# +	},
# +
# +	filter: function( selector ) {
# +		return this.pushStack( winnow(this, selector, true), "filter", selector );
# +	},
# +
# +	is: function( selector ) {
# +		return !!selector && ( typeof selector === "string" ?
# +			jQuery.filter( selector, this ).length > 0 :
# +			this.filter( selector ).length > 0 );
# +	},
# +
# +	closest: function( selectors, context ) {
# +		var ret = [], i, l, cur = this[0];
# +
# +		// Array
# +		if ( jQuery.isArray( selectors ) ) {
# +			var match, selector,
# +				matches = {},
# +				level = 1;
# +
# +			if ( cur && selectors.length ) {
# +				for ( i = 0, l = selectors.length; i < l; i++ ) {
# +					selector = selectors[i];
# +
# +					if ( !matches[ selector ] ) {
# +						matches[ selector ] = POS.test( selector ) ?
# +							jQuery( selector, context || this.context ) :
# +							selector;
# +					}
# +				}
# +
# +				while ( cur && cur.ownerDocument && cur !== context ) {
# +					for ( selector in matches ) {
# +						match = matches[ selector ];
# +
# +						if ( match.jquery ? match.index( cur ) > -1 : jQuery( cur ).is( match ) ) {
# +							ret.push({ selector: selector, elem: cur, level: level });
# +						}
# +					}
# +
# +					cur = cur.parentNode;
# +					level++;
# +				}
# +			}
# +
# +			return ret;
# +		}
# +
# +		// String
# +		var pos = POS.test( selectors ) || typeof selectors !== "string" ?
# +				jQuery( selectors, context || this.context ) :
# +				0;
# +
# +		for ( i = 0, l = this.length; i < l; i++ ) {
# +			cur = this[i];
# +
# +			while ( cur ) {
# +				if ( pos ? pos.index(cur) > -1 : jQuery.find.matchesSelector(cur, selectors) ) {
# +					ret.push( cur );
# +					break;
# +
# +				} else {
# +					cur = cur.parentNode;
# +					if ( !cur || !cur.ownerDocument || cur === context || cur.nodeType === 11 ) {
# +						break;
# +					}
# +				}
# +			}
# +		}
# +
# +		ret = ret.length > 1 ? jQuery.unique( ret ) : ret;
# +
# +		return this.pushStack( ret, "closest", selectors );
# +	},
# +
# +	// Determine the position of an element within
# +	// the matched set of elements
# +	index: function( elem ) {
# +
# +		// No argument, return index in parent
# +		if ( !elem ) {
# +			return ( this[0] && this[0].parentNode ) ? this.prevAll().length : -1;
# +		}
# +
# +		// index in selector
# +		if ( typeof elem === "string" ) {
# +			return jQuery.inArray( this[0], jQuery( elem ) );
# +		}
# +
# +		// Locate the position of the desired element
# +		return jQuery.inArray(
# +			// If it receives a jQuery object, the first element is used
# +			elem.jquery ? elem[0] : elem, this );
# +	},
# +
# +	add: function( selector, context ) {
# +		var set = typeof selector === "string" ?
# +				jQuery( selector, context ) :
# +				jQuery.makeArray( selector && selector.nodeType ? [ selector ] : selector ),
# +			all = jQuery.merge( this.get(), set );
# +
# +		return this.pushStack( isDisconnected( set[0] ) || isDisconnected( all[0] ) ?
# +			all :
# +			jQuery.unique( all ) );
# +	},
# +
# +	andSelf: function() {
# +		return this.add( this.prevObject );
# +	}
# +});
# +
# +// A painfully simple check to see if an element is disconnected
# +// from a document (should be improved, where feasible).
# +function isDisconnected( node ) {
# +	return !node || !node.parentNode || node.parentNode.nodeType === 11;
# +}
# +
# +jQuery.each({
# +	parent: function( elem ) {
# +		var parent = elem.parentNode;
# +		return parent && parent.nodeType !== 11 ? parent : null;
# +	},
# +	parents: function( elem ) {
# +		return jQuery.dir( elem, "parentNode" );
# +	},
# +	parentsUntil: function( elem, i, until ) {
# +		return jQuery.dir( elem, "parentNode", until );
# +	},
# +	next: function( elem ) {
# +		return jQuery.nth( elem, 2, "nextSibling" );
# +	},
# +	prev: function( elem ) {
# +		return jQuery.nth( elem, 2, "previousSibling" );
# +	},
# +	nextAll: function( elem ) {
# +		return jQuery.dir( elem, "nextSibling" );
# +	},
# +	prevAll: function( elem ) {
# +		return jQuery.dir( elem, "previousSibling" );
# +	},
# +	nextUntil: function( elem, i, until ) {
# +		return jQuery.dir( elem, "nextSibling", until );
# +	},
# +	prevUntil: function( elem, i, until ) {
# +		return jQuery.dir( elem, "previousSibling", until );
# +	},
# +	siblings: function( elem ) {
# +		return jQuery.sibling( elem.parentNode.firstChild, elem );
# +	},
# +	children: function( elem ) {
# +		return jQuery.sibling( elem.firstChild );
# +	},
# +	contents: function( elem ) {
# +		return jQuery.nodeName( elem, "iframe" ) ?
# +			elem.contentDocument || elem.contentWindow.document :
# +			jQuery.makeArray( elem.childNodes );
# +	}
# +}, function( name, fn ) {
# +	jQuery.fn[ name ] = function( until, selector ) {
# +		var ret = jQuery.map( this, fn, until ),
# +			// The variable 'args' was introduced in
# +			// https://github.com/jquery/jquery/commit/52a0238
# +			// to work around a bug in Chrome 10 (Dev) and should be removed when the bug is fixed.
# +			// http://code.google.com/p/v8/issues/detail?id=1050
# +			args = slice.call(arguments);
# +
# +		if ( !runtil.test( name ) ) {
# +			selector = until;
# +		}
# +
# +		if ( selector && typeof selector === "string" ) {
# +			ret = jQuery.filter( selector, ret );
# +		}
# +
# +		ret = this.length > 1 && !guaranteedUnique[ name ] ? jQuery.unique( ret ) : ret;
# +
# +		if ( (this.length > 1 || rmultiselector.test( selector )) && rparentsprev.test( name ) ) {
# +			ret = ret.reverse();
# +		}
# +
# +		return this.pushStack( ret, name, args.join(",") );
# +	};
# +});
# +
# +jQuery.extend({
# +	filter: function( expr, elems, not ) {
# +		if ( not ) {
# +			expr = ":not(" + expr + ")";
# +		}
# +
# +		return elems.length === 1 ?
# +			jQuery.find.matchesSelector(elems[0], expr) ? [ elems[0] ] : [] :
# +			jQuery.find.matches(expr, elems);
# +	},
# +
# +	dir: function( elem, dir, until ) {
# +		var matched = [],
# +			cur = elem[ dir ];
# +
# +		while ( cur && cur.nodeType !== 9 && (until === undefined || cur.nodeType !== 1 || !jQuery( cur ).is( until )) ) {
# +			if ( cur.nodeType === 1 ) {
# +				matched.push( cur );
# +			}
# +			cur = cur[dir];
# +		}
# +		return matched;
# +	},
# +
# +	nth: function( cur, result, dir, elem ) {
# +		result = result || 1;
# +		var num = 0;
# +
# +		for ( ; cur; cur = cur[dir] ) {
# +			if ( cur.nodeType === 1 && ++num === result ) {
# +				break;
# +			}
# +		}
# +
# +		return cur;
# +	},
# +
# +	sibling: function( n, elem ) {
# +		var r = [];
# +
# +		for ( ; n; n = n.nextSibling ) {
# +			if ( n.nodeType === 1 && n !== elem ) {
# +				r.push( n );
# +			}
# +		}
# +
# +		return r;
# +	}
# +});
# +
# +// Implement the identical functionality for filter and not
# +function winnow( elements, qualifier, keep ) {
# +
# +	// Can't pass null or undefined to indexOf in Firefox 4
# +	// Set to 0 to skip string check
# +	qualifier = qualifier || 0;
# +
# +	if ( jQuery.isFunction( qualifier ) ) {
# +		return jQuery.grep(elements, function( elem, i ) {
# +			var retVal = !!qualifier.call( elem, i, elem );
# +			return retVal === keep;
# +		});
# +
# +	} else if ( qualifier.nodeType ) {
# +		return jQuery.grep(elements, function( elem, i ) {
# +			return (elem === qualifier) === keep;
# +		});
# +
# +	} else if ( typeof qualifier === "string" ) {
# +		var filtered = jQuery.grep(elements, function( elem ) {
# +			return elem.nodeType === 1;
# +		});
# +
# +		if ( isSimple.test( qualifier ) ) {
# +			return jQuery.filter(qualifier, filtered, !keep);
# +		} else {
# +			qualifier = jQuery.filter( qualifier, filtered );
# +		}
# +	}
# +
# +	return jQuery.grep(elements, function( elem, i ) {
# +		return (jQuery.inArray( elem, qualifier ) >= 0) === keep;
# +	});
# +}
# +
# +
# +
# +
# +var rinlinejQuery = / jQuery\d+="(?:\d+|null)"/g,
# +	rleadingWhitespace = /^\s+/,
# +	rxhtmlTag = /<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:]+)[^>]*)\/>/ig,
# +	rtagName = /<([\w:]+)/,
# +	rtbody = /<tbody/i,
# +	rhtml = /<|&#?\w+;/,
# +	rnocache = /<(?:script|object|embed|option|style)/i,
# +	// checked="checked" or checked
# +	rchecked = /checked\s*(?:[^=]|=\s*.checked.)/i,
# +	rscriptType = /\/(java|ecma)script/i,
# +	rcleanScript = /^\s*<!(?:\[CDATA\[|\-\-)/,
# +	wrapMap = {
# +		option: [ 1, "<select multiple='multiple'>", "</select>" ],
# +		legend: [ 1, "<fieldset>", "</fieldset>" ],
# +		thead: [ 1, "<table>", "</table>" ],
# +		tr: [ 2, "<table><tbody>", "</tbody></table>" ],
# +		td: [ 3, "<table><tbody><tr>", "</tr></tbody></table>" ],
# +		col: [ 2, "<table><tbody></tbody><colgroup>", "</colgroup></table>" ],
# +		area: [ 1, "<map>", "</map>" ],
# +		_default: [ 0, "", "" ]
# +	};
# +
# +wrapMap.optgroup = wrapMap.option;
# +wrapMap.tbody = wrapMap.tfoot = wrapMap.colgroup = wrapMap.caption = wrapMap.thead;
# +wrapMap.th = wrapMap.td;
# +
# +// IE can't serialize <link> and <script> tags normally
# +if ( !jQuery.support.htmlSerialize ) {
# +	wrapMap._default = [ 1, "div<div>", "</div>" ];
# +}
# +
# +jQuery.fn.extend({
# +	text: function( text ) {
# +		if ( jQuery.isFunction(text) ) {
# +			return this.each(function(i) {
# +				var self = jQuery( this );
# +
# +				self.text( text.call(this, i, self.text()) );
# +			});
# +		}
# +
# +		if ( typeof text !== "object" && text !== undefined ) {
# +			return this.empty().append( (this[0] && this[0].ownerDocument || document).createTextNode( text ) );
# +		}
# +
# +		return jQuery.text( this );
# +	},
# +
# +	wrapAll: function( html ) {
# +		if ( jQuery.isFunction( html ) ) {
# +			return this.each(function(i) {
# +				jQuery(this).wrapAll( html.call(this, i) );
# +			});
# +		}
# +
# +		if ( this[0] ) {
# +			// The elements to wrap the target around
# +			var wrap = jQuery( html, this[0].ownerDocument ).eq(0).clone(true);
# +
# +			if ( this[0].parentNode ) {
# +				wrap.insertBefore( this[0] );
# +			}
# +
# +			wrap.map(function() {
# +				var elem = this;
# +
# +				while ( elem.firstChild && elem.firstChild.nodeType === 1 ) {
# +					elem = elem.firstChild;
# +				}
# +
# +				return elem;
# +			}).append( this );
# +		}
# +
# +		return this;
# +	},
# +
# +	wrapInner: function( html ) {
# +		if ( jQuery.isFunction( html ) ) {
# +			return this.each(function(i) {
# +				jQuery(this).wrapInner( html.call(this, i) );
# +			});
# +		}
# +
# +		return this.each(function() {
# +			var self = jQuery( this ),
# +				contents = self.contents();
# +
# +			if ( contents.length ) {
# +				contents.wrapAll( html );
# +
# +			} else {
# +				self.append( html );
# +			}
# +		});
# +	},
# +
# +	wrap: function( html ) {
# +		return this.each(function() {
# +			jQuery( this ).wrapAll( html );
# +		});
# +	},
# +
# +	unwrap: function() {
# +		return this.parent().each(function() {
# +			if ( !jQuery.nodeName( this, "body" ) ) {
# +				jQuery( this ).replaceWith( this.childNodes );
# +			}
# +		}).end();
# +	},
# +
# +	append: function() {
# +		return this.domManip(arguments, true, function( elem ) {
# +			if ( this.nodeType === 1 ) {
# +				this.appendChild( elem );
# +			}
# +		});
# +	},
# +
# +	prepend: function() {
# +		return this.domManip(arguments, true, function( elem ) {
# +			if ( this.nodeType === 1 ) {
# +				this.insertBefore( elem, this.firstChild );
# +			}
# +		});
# +	},
# +
# +	before: function() {
# +		if ( this[0] && this[0].parentNode ) {
# +			return this.domManip(arguments, false, function( elem ) {
# +				this.parentNode.insertBefore( elem, this );
# +			});
# +		} else if ( arguments.length ) {
# +			var set = jQuery(arguments[0]);
# +			set.push.apply( set, this.toArray() );
# +			return this.pushStack( set, "before", arguments );
# +		}
# +	},
# +
# +	after: function() {
# +		if ( this[0] && this[0].parentNode ) {
# +			return this.domManip(arguments, false, function( elem ) {
# +				this.parentNode.insertBefore( elem, this.nextSibling );
# +			});
# +		} else if ( arguments.length ) {
# +			var set = this.pushStack( this, "after", arguments );
# +			set.push.apply( set, jQuery(arguments[0]).toArray() );
# +			return set;
# +		}
# +	},
# +
# +	// keepData is for internal use only--do not document
# +	remove: function( selector, keepData ) {
# +		for ( var i = 0, elem; (elem = this[i]) != null; i++ ) {
# +			if ( !selector || jQuery.filter( selector, [ elem ] ).length ) {
# +				if ( !keepData && elem.nodeType === 1 ) {
# +					jQuery.cleanData( elem.getElementsByTagName("*") );
# +					jQuery.cleanData( [ elem ] );
# +				}
# +
# +				if ( elem.parentNode ) {
# +					elem.parentNode.removeChild( elem );
# +				}
# +			}
# +		}
# +
# +		return this;
# +	},
# +
# +	empty: function() {
# +		for ( var i = 0, elem; (elem = this[i]) != null; i++ ) {
# +			// Remove element nodes and prevent memory leaks
# +			if ( elem.nodeType === 1 ) {
# +				jQuery.cleanData( elem.getElementsByTagName("*") );
# +			}
# +
# +			// Remove any remaining nodes
# +			while ( elem.firstChild ) {
# +				elem.removeChild( elem.firstChild );
# +			}
# +		}
# +
# +		return this;
# +	},
# +
# +	clone: function( dataAndEvents, deepDataAndEvents ) {
# +		dataAndEvents = dataAndEvents == null ? false : dataAndEvents;
# +		deepDataAndEvents = deepDataAndEvents == null ? dataAndEvents : deepDataAndEvents;
# +
# +		return this.map( function () {
# +			return jQuery.clone( this, dataAndEvents, deepDataAndEvents );
# +		});
# +	},
# +
# +	html: function( value ) {
# +		if ( value === undefined ) {
# +			return this[0] && this[0].nodeType === 1 ?
# +				this[0].innerHTML.replace(rinlinejQuery, "") :
# +				null;
# +
# +		// See if we can take a shortcut and just use innerHTML
# +		} else if ( typeof value === "string" && !rnocache.test( value ) &&
# +			(jQuery.support.leadingWhitespace || !rleadingWhitespace.test( value )) &&
# +			!wrapMap[ (rtagName.exec( value ) || ["", ""])[1].toLowerCase() ] ) {
# +
# +			value = value.replace(rxhtmlTag, "<$1></$2>");
# +
# +			try {
# +				for ( var i = 0, l = this.length; i < l; i++ ) {
# +					// Remove element nodes and prevent memory leaks
# +					if ( this[i].nodeType === 1 ) {
# +						jQuery.cleanData( this[i].getElementsByTagName("*") );
# +						this[i].innerHTML = value;
# +					}
# +				}
# +
# +			// If using innerHTML throws an exception, use the fallback method
# +			} catch(e) {
# +				this.empty().append( value );
# +			}
# +
# +		} else if ( jQuery.isFunction( value ) ) {
# +			this.each(function(i){
# +				var self = jQuery( this );
# +
# +				self.html( value.call(this, i, self.html()) );
# +			});
# +
# +		} else {
# +			this.empty().append( value );
# +		}
# +
# +		return this;
# +	},
# +
# +	replaceWith: function( value ) {
# +		if ( this[0] && this[0].parentNode ) {
# +			// Make sure that the elements are removed from the DOM before they are inserted
# +			// this can help fix replacing a parent with child elements
# +			if ( jQuery.isFunction( value ) ) {
# +				return this.each(function(i) {
# +					var self = jQuery(this), old = self.html();
# +					self.replaceWith( value.call( this, i, old ) );
# +				});
# +			}
# +
# +			if ( typeof value !== "string" ) {
# +				value = jQuery( value ).detach();
# +			}
# +
# +			return this.each(function() {
# +				var next = this.nextSibling,
# +					parent = this.parentNode;
# +
# +				jQuery( this ).remove();
# +
# +				if ( next ) {
# +					jQuery(next).before( value );
# +				} else {
# +					jQuery(parent).append( value );
# +				}
# +			});
# +		} else {
# +			return this.length ?
# +				this.pushStack( jQuery(jQuery.isFunction(value) ? value() : value), "replaceWith", value ) :
# +				this;
# +		}
# +	},
# +
# +	detach: function( selector ) {
# +		return this.remove( selector, true );
# +	},
# +
# +	domManip: function( args, table, callback ) {
# +		var results, first, fragment, parent,
# +			value = args[0],
# +			scripts = [];
# +
# +		// We can't cloneNode fragments that contain checked, in WebKit
# +		if ( !jQuery.support.checkClone && arguments.length === 3 && typeof value === "string" && rchecked.test( value ) ) {
# +			return this.each(function() {
# +				jQuery(this).domManip( args, table, callback, true );
# +			});
# +		}
# +
# +		if ( jQuery.isFunction(value) ) {
# +			return this.each(function(i) {
# +				var self = jQuery(this);
# +				args[0] = value.call(this, i, table ? self.html() : undefined);
# +				self.domManip( args, table, callback );
# +			});
# +		}
# +
# +		if ( this[0] ) {
# +			parent = value && value.parentNode;
# +
# +			// If we're in a fragment, just use that instead of building a new one
# +			if ( jQuery.support.parentNode && parent && parent.nodeType === 11 && parent.childNodes.length === this.length ) {
# +				results = { fragment: parent };
# +
# +			} else {
# +				results = jQuery.buildFragment( args, this, scripts );
# +			}
# +
# +			fragment = results.fragment;
# +
# +			if ( fragment.childNodes.length === 1 ) {
# +				first = fragment = fragment.firstChild;
# +			} else {
# +				first = fragment.firstChild;
# +			}
# +
# +			if ( first ) {
# +				table = table && jQuery.nodeName( first, "tr" );
# +
# +				for ( var i = 0, l = this.length, lastIndex = l - 1; i < l; i++ ) {
# +					callback.call(
# +						table ?
# +							root(this[i], first) :
# +							this[i],
# +						// Make sure that we do not leak memory by inadvertently discarding
# +						// the original fragment (which might have attached data) instead of
# +						// using it; in addition, use the original fragment object for the last
# +						// item instead of first because it can end up being emptied incorrectly
# +						// in certain situations (Bug #8070).
# +						// Fragments from the fragment cache must always be cloned and never used
# +						// in place.
# +						results.cacheable || (l > 1 && i < lastIndex) ?
# +							jQuery.clone( fragment, true, true ) :
# +							fragment
# +					);
# +				}
# +			}
# +
# +			if ( scripts.length ) {
# +				jQuery.each( scripts, evalScript );
# +			}
# +		}
# +
# +		return this;
# +	}
# +});
# +
# +function root( elem, cur ) {
# +	return jQuery.nodeName(elem, "table") ?
# +		(elem.getElementsByTagName("tbody")[0] ||
# +		elem.appendChild(elem.ownerDocument.createElement("tbody"))) :
# +		elem;
# +}
# +
# +function cloneCopyEvent( src, dest ) {
# +
# +	if ( dest.nodeType !== 1 || !jQuery.hasData( src ) ) {
# +		return;
# +	}
# +
# +	var internalKey = jQuery.expando,
# +		oldData = jQuery.data( src ),
# +		curData = jQuery.data( dest, oldData );
# +
# +	// Switch to use the internal data object, if it exists, for the next
# +	// stage of data copying
# +	if ( (oldData = oldData[ internalKey ]) ) {
# +		var events = oldData.events;
# +				curData = curData[ internalKey ] = jQuery.extend({}, oldData);
# +
# +		if ( events ) {
# +			delete curData.handle;
# +			curData.events = {};
# +
# +			for ( var type in events ) {
# +				for ( var i = 0, l = events[ type ].length; i < l; i++ ) {
# +					jQuery.event.add( dest, type + ( events[ type ][ i ].namespace ? "." : "" ) + events[ type ][ i ].namespace, events[ type ][ i ], events[ type ][ i ].data );
# +				}
# +			}
# +		}
# +	}
# +}
# +
# +function cloneFixAttributes( src, dest ) {
# +	var nodeName;
# +
# +	// We do not need to do anything for non-Elements
# +	if ( dest.nodeType !== 1 ) {
# +		return;
# +	}
# +
# +	// clearAttributes removes the attributes, which we don't want,
# +	// but also removes the attachEvent events, which we *do* want
# +	if ( dest.clearAttributes ) {
# +		dest.clearAttributes();
# +	}
# +
# +	// mergeAttributes, in contrast, only merges back on the
# +	// original attributes, not the events
# +	if ( dest.mergeAttributes ) {
# +		dest.mergeAttributes( src );
# +	}
# +
# +	nodeName = dest.nodeName.toLowerCase();
# +
# +	// IE6-8 fail to clone children inside object elements that use
# +	// the proprietary classid attribute value (rather than the type
# +	// attribute) to identify the type of content to display
# +	if ( nodeName === "object" ) {
# +		dest.outerHTML = src.outerHTML;
# +
# +	} else if ( nodeName === "input" && (src.type === "checkbox" || src.type === "radio") ) {
# +		// IE6-8 fails to persist the checked state of a cloned checkbox
# +		// or radio button. Worse, IE6-7 fail to give the cloned element
# +		// a checked appearance if the defaultChecked value isn't also set
# +		if ( src.checked ) {
# +			dest.defaultChecked = dest.checked = src.checked;
# +		}
# +
# +		// IE6-7 get confused and end up setting the value of a cloned
# +		// checkbox/radio button to an empty string instead of "on"
# +		if ( dest.value !== src.value ) {
# +			dest.value = src.value;
# +		}
# +
# +	// IE6-8 fails to return the selected option to the default selected
# +	// state when cloning options
# +	} else if ( nodeName === "option" ) {
# +		dest.selected = src.defaultSelected;
# +
# +	// IE6-8 fails to set the defaultValue to the correct value when
# +	// cloning other types of input fields
# +	} else if ( nodeName === "input" || nodeName === "textarea" ) {
# +		dest.defaultValue = src.defaultValue;
# +	}
# +
# +	// Event data gets referenced instead of copied if the expando
# +	// gets copied too
# +	dest.removeAttribute( jQuery.expando );
# +}
# +
# +jQuery.buildFragment = function( args, nodes, scripts ) {
# +	var fragment, cacheable, cacheresults, doc;
# +
# +  // nodes may contain either an explicit document object,
# +  // a jQuery collection or context object.
# +  // If nodes[0] contains a valid object to assign to doc
# +  if ( nodes && nodes[0] ) {
# +    doc = nodes[0].ownerDocument || nodes[0];
# +  }
# +
# +  // Ensure that an attr object doesn't incorrectly stand in as a document object
# +	// Chrome and Firefox seem to allow this to occur and will throw exception
# +	// Fixes #8950
# +	if ( !doc.createDocumentFragment ) {
# +		doc = document;
# +	}
# +
# +	// Only cache "small" (1/2 KB) HTML strings that are associated with the main document
# +	// Cloning options loses the selected state, so don't cache them
# +	// IE 6 doesn't like it when you put <object> or <embed> elements in a fragment
# +	// Also, WebKit does not clone 'checked' attributes on cloneNode, so don't cache
# +	if ( args.length === 1 && typeof args[0] === "string" && args[0].length < 512 && doc === document &&
# +		args[0].charAt(0) === "<" && !rnocache.test( args[0] ) && (jQuery.support.checkClone || !rchecked.test( args[0] )) ) {
# +
# +		cacheable = true;
# +
# +		cacheresults = jQuery.fragments[ args[0] ];
# +		if ( cacheresults && cacheresults !== 1 ) {
# +			fragment = cacheresults;
# +		}
# +	}
# +
# +	if ( !fragment ) {
# +		fragment = doc.createDocumentFragment();
# +		jQuery.clean( args, doc, fragment, scripts );
# +	}
# +
# +	if ( cacheable ) {
# +		jQuery.fragments[ args[0] ] = cacheresults ? fragment : 1;
# +	}
# +
# +	return { fragment: fragment, cacheable: cacheable };
# +};
# +
# +jQuery.fragments = {};
# +
# +jQuery.each({
# +	appendTo: "append",
# +	prependTo: "prepend",
# +	insertBefore: "before",
# +	insertAfter: "after",
# +	replaceAll: "replaceWith"
# +}, function( name, original ) {
# +	jQuery.fn[ name ] = function( selector ) {
# +		var ret = [],
# +			insert = jQuery( selector ),
# +			parent = this.length === 1 && this[0].parentNode;
# +
# +		if ( parent && parent.nodeType === 11 && parent.childNodes.length === 1 && insert.length === 1 ) {
# +			insert[ original ]( this[0] );
# +			return this;
# +
# +		} else {
# +			for ( var i = 0, l = insert.length; i < l; i++ ) {
# +				var elems = (i > 0 ? this.clone(true) : this).get();
# +				jQuery( insert[i] )[ original ]( elems );
# +				ret = ret.concat( elems );
# +			}
# +
# +			return this.pushStack( ret, name, insert.selector );
# +		}
# +	};
# +});
# +
# +function getAll( elem ) {
# +	if ( "getElementsByTagName" in elem ) {
# +		return elem.getElementsByTagName( "*" );
# +
# +	} else if ( "querySelectorAll" in elem ) {
# +		return elem.querySelectorAll( "*" );
# +
# +	} else {
# +		return [];
# +	}
# +}
# +
# +// Used in clean, fixes the defaultChecked property
# +function fixDefaultChecked( elem ) {
# +	if ( elem.type === "checkbox" || elem.type === "radio" ) {
# +		elem.defaultChecked = elem.checked;
# +	}
# +}
# +// Finds all inputs and passes them to fixDefaultChecked
# +function findInputs( elem ) {
# +	if ( jQuery.nodeName( elem, "input" ) ) {
# +		fixDefaultChecked( elem );
# +	} else if ( "getElementsByTagName" in elem ) {
# +		jQuery.grep( elem.getElementsByTagName("input"), fixDefaultChecked );
# +	}
# +}
# +
# +jQuery.extend({
# +	clone: function( elem, dataAndEvents, deepDataAndEvents ) {
# +		var clone = elem.cloneNode(true),
# +				srcElements,
# +				destElements,
# +				i;
# +
# +		if ( (!jQuery.support.noCloneEvent || !jQuery.support.noCloneChecked) &&
# +				(elem.nodeType === 1 || elem.nodeType === 11) && !jQuery.isXMLDoc(elem) ) {
# +			// IE copies events bound via attachEvent when using cloneNode.
# +			// Calling detachEvent on the clone will also remove the events
# +			// from the original. In order to get around this, we use some
# +			// proprietary methods to clear the events. Thanks to MooTools
# +			// guys for this hotness.
# +
# +			cloneFixAttributes( elem, clone );
# +
# +			// Using Sizzle here is crazy slow, so we use getElementsByTagName
# +			// instead
# +			srcElements = getAll( elem );
# +			destElements = getAll( clone );
# +
# +			// Weird iteration because IE will replace the length property
# +			// with an element if you are cloning the body and one of the
# +			// elements on the page has a name or id of "length"
# +			for ( i = 0; srcElements[i]; ++i ) {
# +				// Ensure that the destination node is not null; Fixes #9587
# +				if ( destElements[i] ) {
# +					cloneFixAttributes( srcElements[i], destElements[i] );
# +				}
# +			}
# +		}
# +
# +		// Copy the events from the original to the clone
# +		if ( dataAndEvents ) {
# +			cloneCopyEvent( elem, clone );
# +
# +			if ( deepDataAndEvents ) {
# +				srcElements = getAll( elem );
# +				destElements = getAll( clone );
# +
# +				for ( i = 0; srcElements[i]; ++i ) {
# +					cloneCopyEvent( srcElements[i], destElements[i] );
# +				}
# +			}
# +		}
# +
# +		srcElements = destElements = null;
# +
# +		// Return the cloned set
# +		return clone;
# +	},
# +
# +	clean: function( elems, context, fragment, scripts ) {
# +		var checkScriptType;
# +
# +		context = context || document;
# +
# +		// !context.createElement fails in IE with an error but returns typeof 'object'
# +		if ( typeof context.createElement === "undefined" ) {
# +			context = context.ownerDocument || context[0] && context[0].ownerDocument || document;
# +		}
# +
# +		var ret = [], j;
# +
# +		for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
# +			if ( typeof elem === "number" ) {
# +				elem += "";
# +			}
# +
# +			if ( !elem ) {
# +				continue;
# +			}
# +
# +			// Convert html string into DOM nodes
# +			if ( typeof elem === "string" ) {
# +				if ( !rhtml.test( elem ) ) {
# +					elem = context.createTextNode( elem );
# +				} else {
# +					// Fix "XHTML"-style tags in all browsers
# +					elem = elem.replace(rxhtmlTag, "<$1></$2>");
# +
# +					// Trim whitespace, otherwise indexOf won't work as expected
# +					var tag = (rtagName.exec( elem ) || ["", ""])[1].toLowerCase(),
# +						wrap = wrapMap[ tag ] || wrapMap._default,
# +						depth = wrap[0],
# +						div = context.createElement("div");
# +
# +					// Go to html and back, then peel off extra wrappers
# +					div.innerHTML = wrap[1] + elem + wrap[2];
# +
# +					// Move to the right depth
# +					while ( depth-- ) {
# +						div = div.lastChild;
# +					}
# +
# +					// Remove IE's autoinserted <tbody> from table fragments
# +					if ( !jQuery.support.tbody ) {
# +
# +						// String was a <table>, *may* have spurious <tbody>
# +						var hasBody = rtbody.test(elem),
# +							tbody = tag === "table" && !hasBody ?
# +								div.firstChild && div.firstChild.childNodes :
# +
# +								// String was a bare <thead> or <tfoot>
# +								wrap[1] === "<table>" && !hasBody ?
# +									div.childNodes :
# +									[];
# +
# +						for ( j = tbody.length - 1; j >= 0 ; --j ) {
# +							if ( jQuery.nodeName( tbody[ j ], "tbody" ) && !tbody[ j ].childNodes.length ) {
# +								tbody[ j ].parentNode.removeChild( tbody[ j ] );
# +							}
# +						}
# +					}
# +
# +					// IE completely kills leading whitespace when innerHTML is used
# +					if ( !jQuery.support.leadingWhitespace && rleadingWhitespace.test( elem ) ) {
# +						div.insertBefore( context.createTextNode( rleadingWhitespace.exec(elem)[0] ), div.firstChild );
# +					}
# +
# +					elem = div.childNodes;
# +				}
# +			}
# +
# +			// Resets defaultChecked for any radios and checkboxes
# +			// about to be appended to the DOM in IE 6/7 (#8060)
# +			var len;
# +			if ( !jQuery.support.appendChecked ) {
# +				if ( elem[0] && typeof (len = elem.length) === "number" ) {
# +					for ( j = 0; j < len; j++ ) {
# +						findInputs( elem[j] );
# +					}
# +				} else {
# +					findInputs( elem );
# +				}
# +			}
# +
# +			if ( elem.nodeType ) {
# +				ret.push( elem );
# +			} else {
# +				ret = jQuery.merge( ret, elem );
# +			}
# +		}
# +
# +		if ( fragment ) {
# +			checkScriptType = function( elem ) {
# +				return !elem.type || rscriptType.test( elem.type );
# +			};
# +			for ( i = 0; ret[i]; i++ ) {
# +				if ( scripts && jQuery.nodeName( ret[i], "script" ) && (!ret[i].type || ret[i].type.toLowerCase() === "text/javascript") ) {
# +					scripts.push( ret[i].parentNode ? ret[i].parentNode.removeChild( ret[i] ) : ret[i] );
# +
# +				} else {
# +					if ( ret[i].nodeType === 1 ) {
# +						var jsTags = jQuery.grep( ret[i].getElementsByTagName( "script" ), checkScriptType );
# +
# +						ret.splice.apply( ret, [i + 1, 0].concat( jsTags ) );
# +					}
# +					fragment.appendChild( ret[i] );
# +				}
# +			}
# +		}
# +
# +		return ret;
# +	},
# +
# +	cleanData: function( elems ) {
# +		var data, id, cache = jQuery.cache, internalKey = jQuery.expando, special = jQuery.event.special,
# +			deleteExpando = jQuery.support.deleteExpando;
# +
# +		for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
# +			if ( elem.nodeName && jQuery.noData[elem.nodeName.toLowerCase()] ) {
# +				continue;
# +			}
# +
# +			id = elem[ jQuery.expando ];
# +
# +			if ( id ) {
# +				data = cache[ id ] && cache[ id ][ internalKey ];
# +
# +				if ( data && data.events ) {
# +					for ( var type in data.events ) {
# +						if ( special[ type ] ) {
# +							jQuery.event.remove( elem, type );
# +
# +						// This is a shortcut to avoid jQuery.event.remove's overhead
# +						} else {
# +							jQuery.removeEvent( elem, type, data.handle );
# +						}
# +					}
# +
# +					// Null the DOM reference to avoid IE6/7/8 leak (#7054)
# +					if ( data.handle ) {
# +						data.handle.elem = null;
# +					}
# +				}
# +
# +				if ( deleteExpando ) {
# +					delete elem[ jQuery.expando ];
# +
# +				} else if ( elem.removeAttribute ) {
# +					elem.removeAttribute( jQuery.expando );
# +				}
# +
# +				delete cache[ id ];
# +			}
# +		}
# +	}
# +});
# +
# +function evalScript( i, elem ) {
# +	if ( elem.src ) {
# +		jQuery.ajax({
# +			url: elem.src,
# +			async: false,
# +			dataType: "script"
# +		});
# +	} else {
# +		jQuery.globalEval( ( elem.text || elem.textContent || elem.innerHTML || "" ).replace( rcleanScript, "/*$0*/" ) );
# +	}
# +
# +	if ( elem.parentNode ) {
# +		elem.parentNode.removeChild( elem );
# +	}
# +}
# +
# +
# +
# +
# +var ralpha = /alpha\([^)]*\)/i,
# +	ropacity = /opacity=([^)]*)/,
# +	// fixed for IE9, see #8346
# +	rupper = /([A-Z]|^ms)/g,
# +	rnumpx = /^-?\d+(?:px)?$/i,
# +	rnum = /^-?\d/,
# +	rrelNum = /^([\-+])=([\-+.\de]+)/,
# +
# +	cssShow = { position: "absolute", visibility: "hidden", display: "block" },
# +	cssWidth = [ "Left", "Right" ],
# +	cssHeight = [ "Top", "Bottom" ],
# +	curCSS,
# +
# +	getComputedStyle,
# +	currentStyle;
# +
# +jQuery.fn.css = function( name, value ) {
# +	// Setting 'undefined' is a no-op
# +	if ( arguments.length === 2 && value === undefined ) {
# +		return this;
# +	}
# +
# +	return jQuery.access( this, name, value, true, function( elem, name, value ) {
# +		return value !== undefined ?
# +			jQuery.style( elem, name, value ) :
# +			jQuery.css( elem, name );
# +	});
# +};
# +
# +jQuery.extend({
# +	// Add in style property hooks for overriding the default
# +	// behavior of getting and setting a style property
# +	cssHooks: {
# +		opacity: {
# +			get: function( elem, computed ) {
# +				if ( computed ) {
# +					// We should always get a number back from opacity
# +					var ret = curCSS( elem, "opacity", "opacity" );
# +					return ret === "" ? "1" : ret;
# +
# +				} else {
# +					return elem.style.opacity;
# +				}
# +			}
# +		}
# +	},
# +
# +	// Exclude the following css properties to add px
# +	cssNumber: {
# +		"fillOpacity": true,
# +		"fontWeight": true,
# +		"lineHeight": true,
# +		"opacity": true,
# +		"orphans": true,
# +		"widows": true,
# +		"zIndex": true,
# +		"zoom": true
# +	},
# +
# +	// Add in properties whose names you wish to fix before
# +	// setting or getting the value
# +	cssProps: {
# +		// normalize float css property
# +		"float": jQuery.support.cssFloat ? "cssFloat" : "styleFloat"
# +	},
# +
# +	// Get and set the style property on a DOM Node
# +	style: function( elem, name, value, extra ) {
# +		// Don't set styles on text and comment nodes
# +		if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 || !elem.style ) {
# +			return;
# +		}
# +
# +		// Make sure that we're working with the right name
# +		var ret, type, origName = jQuery.camelCase( name ),
# +			style = elem.style, hooks = jQuery.cssHooks[ origName ];
# +
# +		name = jQuery.cssProps[ origName ] || origName;
# +
# +		// Check if we're setting a value
# +		if ( value !== undefined ) {
# +			type = typeof value;
# +
# +			// convert relative number strings (+= or -=) to relative numbers. #7345
# +			if ( type === "string" && (ret = rrelNum.exec( value )) ) {
# +				value = ( +( ret[1] + 1) * +ret[2] ) + parseFloat( jQuery.css( elem, name ) );
# +				// Fixes bug #9237
# +				type = "number";
# +			}
# +
# +			// Make sure that NaN and null values aren't set. See: #7116
# +			if ( value == null || type === "number" && isNaN( value ) ) {
# +				return;
# +			}
# +
# +			// If a number was passed in, add 'px' to the (except for certain CSS properties)
# +			if ( type === "number" && !jQuery.cssNumber[ origName ] ) {
# +				value += "px";
# +			}
# +
# +			// If a hook was provided, use that value, otherwise just set the specified value
# +			if ( !hooks || !("set" in hooks) || (value = hooks.set( elem, value )) !== undefined ) {
# +				// Wrapped to prevent IE from throwing errors when 'invalid' values are provided
# +				// Fixes bug #5509
# +				try {
# +					style[ name ] = value;
# +				} catch(e) {}
# +			}
# +
# +		} else {
# +			// If a hook was provided get the non-computed value from there
# +			if ( hooks && "get" in hooks && (ret = hooks.get( elem, false, extra )) !== undefined ) {
# +				return ret;
# +			}
# +
# +			// Otherwise just get the value from the style object
# +			return style[ name ];
# +		}
# +	},
# +
# +	css: function( elem, name, extra ) {
# +		var ret, hooks;
# +
# +		// Make sure that we're working with the right name
# +		name = jQuery.camelCase( name );
# +		hooks = jQuery.cssHooks[ name ];
# +		name = jQuery.cssProps[ name ] || name;
# +
# +		// cssFloat needs a special treatment
# +		if ( name === "cssFloat" ) {
# +			name = "float";
# +		}
# +
# +		// If a hook was provided get the computed value from there
# +		if ( hooks && "get" in hooks && (ret = hooks.get( elem, true, extra )) !== undefined ) {
# +			return ret;
# +
# +		// Otherwise, if a way to get the computed value exists, use that
# +		} else if ( curCSS ) {
# +			return curCSS( elem, name );
# +		}
# +	},
# +
# +	// A method for quickly swapping in/out CSS properties to get correct calculations
# +	swap: function( elem, options, callback ) {
# +		var old = {};
# +
# +		// Remember the old values, and insert the new ones
# +		for ( var name in options ) {
# +			old[ name ] = elem.style[ name ];
# +			elem.style[ name ] = options[ name ];
# +		}
# +
# +		callback.call( elem );
# +
# +		// Revert the old values
# +		for ( name in options ) {
# +			elem.style[ name ] = old[ name ];
# +		}
# +	}
# +});
# +
# +// DEPRECATED, Use jQuery.css() instead
# +jQuery.curCSS = jQuery.css;
# +
# +jQuery.each(["height", "width"], function( i, name ) {
# +	jQuery.cssHooks[ name ] = {
# +		get: function( elem, computed, extra ) {
# +			var val;
# +
# +			if ( computed ) {
# +				if ( elem.offsetWidth !== 0 ) {
# +					return getWH( elem, name, extra );
# +				} else {
# +					jQuery.swap( elem, cssShow, function() {
# +						val = getWH( elem, name, extra );
# +					});
# +				}
# +
# +				return val;
# +			}
# +		},
# +
# +		set: function( elem, value ) {
# +			if ( rnumpx.test( value ) ) {
# +				// ignore negative width and height values #1599
# +				value = parseFloat( value );
# +
# +				if ( value >= 0 ) {
# +					return value + "px";
# +				}
# +
# +			} else {
# +				return value;
# +			}
# +		}
# +	};
# +});
# +
# +if ( !jQuery.support.opacity ) {
# +	jQuery.cssHooks.opacity = {
# +		get: function( elem, computed ) {
# +			// IE uses filters for opacity
# +			return ropacity.test( (computed && elem.currentStyle ? elem.currentStyle.filter : elem.style.filter) || "" ) ?
# +				( parseFloat( RegExp.$1 ) / 100 ) + "" :
# +				computed ? "1" : "";
# +		},
# +
# +		set: function( elem, value ) {
# +			var style = elem.style,
# +				currentStyle = elem.currentStyle,
# +				opacity = jQuery.isNaN( value ) ? "" : "alpha(opacity=" + value * 100 + ")",
# +				filter = currentStyle && currentStyle.filter || style.filter || "";
# +
# +			// IE has trouble with opacity if it does not have layout
# +			// Force it by setting the zoom level
# +			style.zoom = 1;
# +
# +			// if setting opacity to 1, and no other filters exist - attempt to remove filter attribute #6652
# +			if ( value >= 1 && jQuery.trim( filter.replace( ralpha, "" ) ) === "" ) {
# +
# +				// Setting style.filter to null, "" & " " still leave "filter:" in the cssText
# +				// if "filter:" is present at all, clearType is disabled, we want to avoid this
# +				// style.removeAttribute is IE Only, but so apparently is this code path...
# +				style.removeAttribute( "filter" );
# +
# +				// if there there is no filter style applied in a css rule, we are done
# +				if ( currentStyle && !currentStyle.filter ) {
# +					return;
# +				}
# +			}
# +
# +			// otherwise, set new filter values
# +			style.filter = ralpha.test( filter ) ?
# +				filter.replace( ralpha, opacity ) :
# +				filter + " " + opacity;
# +		}
# +	};
# +}
# +
# +jQuery(function() {
# +	// This hook cannot be added until DOM ready because the support test
# +	// for it is not run until after DOM ready
# +	if ( !jQuery.support.reliableMarginRight ) {
# +		jQuery.cssHooks.marginRight = {
# +			get: function( elem, computed ) {
# +				// WebKit Bug 13343 - getComputedStyle returns wrong value for margin-right
# +				// Work around by temporarily setting element display to inline-block
# +				var ret;
# +				jQuery.swap( elem, { "display": "inline-block" }, function() {
# +					if ( computed ) {
# +						ret = curCSS( elem, "margin-right", "marginRight" );
# +					} else {
# +						ret = elem.style.marginRight;
# +					}
# +				});
# +				return ret;
# +			}
# +		};
# +	}
# +});
# +
# +if ( document.defaultView && document.defaultView.getComputedStyle ) {
# +	getComputedStyle = function( elem, name ) {
# +		var ret, defaultView, computedStyle;
# +
# +		name = name.replace( rupper, "-$1" ).toLowerCase();
# +
# +		if ( !(defaultView = elem.ownerDocument.defaultView) ) {
# +			return undefined;
# +		}
# +
# +		if ( (computedStyle = defaultView.getComputedStyle( elem, null )) ) {
# +			ret = computedStyle.getPropertyValue( name );
# +			if ( ret === "" && !jQuery.contains( elem.ownerDocument.documentElement, elem ) ) {
# +				ret = jQuery.style( elem, name );
# +			}
# +		}
# +
# +		return ret;
# +	};
# +}
# +
# +if ( document.documentElement.currentStyle ) {
# +	currentStyle = function( elem, name ) {
# +		var left,
# +			ret = elem.currentStyle && elem.currentStyle[ name ],
# +			rsLeft = elem.runtimeStyle && elem.runtimeStyle[ name ],
# +			style = elem.style;
# +
# +		// From the awesome hack by Dean Edwards
# +		// http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291
# +
# +		// If we're not dealing with a regular pixel number
# +		// but a number that has a weird ending, we need to convert it to pixels
# +		if ( !rnumpx.test( ret ) && rnum.test( ret ) ) {
# +			// Remember the original values
# +			left = style.left;
# +
# +			// Put in the new values to get a computed value out
# +			if ( rsLeft ) {
# +				elem.runtimeStyle.left = elem.currentStyle.left;
# +			}
# +			style.left = name === "fontSize" ? "1em" : (ret || 0);
# +			ret = style.pixelLeft + "px";
# +
# +			// Revert the changed values
# +			style.left = left;
# +			if ( rsLeft ) {
# +				elem.runtimeStyle.left = rsLeft;
# +			}
# +		}
# +
# +		return ret === "" ? "auto" : ret;
# +	};
# +}
# +
# +curCSS = getComputedStyle || currentStyle;
# +
# +function getWH( elem, name, extra ) {
# +
# +	// Start with offset property
# +	var val = name === "width" ? elem.offsetWidth : elem.offsetHeight,
# +		which = name === "width" ? cssWidth : cssHeight;
# +
# +	if ( val > 0 ) {
# +		if ( extra !== "border" ) {
# +			jQuery.each( which, function() {
# +				if ( !extra ) {
# +					val -= parseFloat( jQuery.css( elem, "padding" + this ) ) || 0;
# +				}
# +				if ( extra === "margin" ) {
# +					val += parseFloat( jQuery.css( elem, extra + this ) ) || 0;
# +				} else {
# +					val -= parseFloat( jQuery.css( elem, "border" + this + "Width" ) ) || 0;
# +				}
# +			});
# +		}
# +
# +		return val + "px";
# +	}
# +
# +	// Fall back to computed then uncomputed css if necessary
# +	val = curCSS( elem, name, name );
# +	if ( val < 0 || val == null ) {
# +		val = elem.style[ name ] || 0;
# +	}
# +	// Normalize "", auto, and prepare for extra
# +	val = parseFloat( val ) || 0;
# +
# +	// Add padding, border, margin
# +	if ( extra ) {
# +		jQuery.each( which, function() {
# +			val += parseFloat( jQuery.css( elem, "padding" + this ) ) || 0;
# +			if ( extra !== "padding" ) {
# +				val += parseFloat( jQuery.css( elem, "border" + this + "Width" ) ) || 0;
# +			}
# +			if ( extra === "margin" ) {
# +				val += parseFloat( jQuery.css( elem, extra + this ) ) || 0;
# +			}
# +		});
# +	}
# +
# +	return val + "px";
# +}
# +
# +if ( jQuery.expr && jQuery.expr.filters ) {
# +	jQuery.expr.filters.hidden = function( elem ) {
# +		var width = elem.offsetWidth,
# +			height = elem.offsetHeight;
# +
# +		return (width === 0 && height === 0) || (!jQuery.support.reliableHiddenOffsets && (elem.style.display || jQuery.css( elem, "display" )) === "none");
# +	};
# +
# +	jQuery.expr.filters.visible = function( elem ) {
# +		return !jQuery.expr.filters.hidden( elem );
# +	};
# +}
# +
# +
# +
# +
# +var r20 = /%20/g,
# +	rbracket = /\[\]$/,
# +	rCRLF = /\r?\n/g,
# +	rhash = /#.*$/,
# +	rheaders = /^(.*?):[ \t]*([^\r\n]*)\r?$/mg, // IE leaves an \r character at EOL
# +	rinput = /^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week)$/i,
# +	// #7653, #8125, #8152: local protocol detection
# +	rlocalProtocol = /^(?:about|app|app\-storage|.+\-extension|file|res|widget):$/,
# +	rnoContent = /^(?:GET|HEAD)$/,
# +	rprotocol = /^\/\//,
# +	rquery = /\?/,
# +	rscript = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
# +	rselectTextarea = /^(?:select|textarea)/i,
# +	rspacesAjax = /\s+/,
# +	rts = /([?&])_=[^&]*/,
# +	rurl = /^([\w\+\.\-]+:)(?:\/\/([^\/?#:]*)(?::(\d+))?)?/,
# +
# +	// Keep a copy of the old load method
# +	_load = jQuery.fn.load,
# +
# +	/* Prefilters
# +	 * 1) They are useful to introduce custom dataTypes (see ajax/jsonp.js for an example)
# +	 * 2) These are called:
# +	 *    - BEFORE asking for a transport
# +	 *    - AFTER param serialization (s.data is a string if s.processData is true)
# +	 * 3) key is the dataType
# +	 * 4) the catchall symbol "*" can be used
# +	 * 5) execution will start with transport dataType and THEN continue down to "*" if needed
# +	 */
# +	prefilters = {},
# +
# +	/* Transports bindings
# +	 * 1) key is the dataType
# +	 * 2) the catchall symbol "*" can be used
# +	 * 3) selection will start with transport dataType and THEN go to "*" if needed
# +	 */
# +	transports = {},
# +
# +	// Document location
# +	ajaxLocation,
# +
# +	// Document location segments
# +	ajaxLocParts,
# +
# +	// Avoid comment-prolog char sequence (#10098); must appease lint and evade compression
# +	allTypes = ["*/"] + ["*"];
# +
# +// #8138, IE may throw an exception when accessing
# +// a field from window.location if document.domain has been set
# +try {
# +	ajaxLocation = location.href;
# +} catch( e ) {
# +	// Use the href attribute of an A element
# +	// since IE will modify it given document.location
# +	ajaxLocation = document.createElement( "a" );
# +	ajaxLocation.href = "";
# +	ajaxLocation = ajaxLocation.href;
# +}
# +
# +// Segment location into parts
# +ajaxLocParts = rurl.exec( ajaxLocation.toLowerCase() ) || [];
# +
# +// Base "constructor" for jQuery.ajaxPrefilter and jQuery.ajaxTransport
# +function addToPrefiltersOrTransports( structure ) {
# +
# +	// dataTypeExpression is optional and defaults to "*"
# +	return function( dataTypeExpression, func ) {
# +
# +		if ( typeof dataTypeExpression !== "string" ) {
# +			func = dataTypeExpression;
# +			dataTypeExpression = "*";
# +		}
# +
# +		if ( jQuery.isFunction( func ) ) {
# +			var dataTypes = dataTypeExpression.toLowerCase().split( rspacesAjax ),
# +				i = 0,
# +				length = dataTypes.length,
# +				dataType,
# +				list,
# +				placeBefore;
# +
# +			// For each dataType in the dataTypeExpression
# +			for(; i < length; i++ ) {
# +				dataType = dataTypes[ i ];
# +				// We control if we're asked to add before
# +				// any existing element
# +				placeBefore = /^\+/.test( dataType );
# +				if ( placeBefore ) {
# +					dataType = dataType.substr( 1 ) || "*";
# +				}
# +				list = structure[ dataType ] = structure[ dataType ] || [];
# +				// then we add to the structure accordingly
# +				list[ placeBefore ? "unshift" : "push" ]( func );
# +			}
# +		}
# +	};
# +}
# +
# +// Base inspection function for prefilters and transports
# +function inspectPrefiltersOrTransports( structure, options, originalOptions, jqXHR,
# +		dataType /* internal */, inspected /* internal */ ) {
# +
# +	dataType = dataType || options.dataTypes[ 0 ];
# +	inspected = inspected || {};
# +
# +	inspected[ dataType ] = true;
# +
# +	var list = structure[ dataType ],
# +		i = 0,
# +		length = list ? list.length : 0,
# +		executeOnly = ( structure === prefilters ),
# +		selection;
# +
# +	for(; i < length && ( executeOnly || !selection ); i++ ) {
# +		selection = list[ i ]( options, originalOptions, jqXHR );
# +		// If we got redirected to another dataType
# +		// we try there if executing only and not done already
# +		if ( typeof selection === "string" ) {
# +			if ( !executeOnly || inspected[ selection ] ) {
# +				selection = undefined;
# +			} else {
# +				options.dataTypes.unshift( selection );
# +				selection = inspectPrefiltersOrTransports(
# +						structure, options, originalOptions, jqXHR, selection, inspected );
# +			}
# +		}
# +	}
# +	// If we're only executing or nothing was selected
# +	// we try the catchall dataType if not done already
# +	if ( ( executeOnly || !selection ) && !inspected[ "*" ] ) {
# +		selection = inspectPrefiltersOrTransports(
# +				structure, options, originalOptions, jqXHR, "*", inspected );
# +	}
# +	// unnecessary when only executing (prefilters)
# +	// but it'll be ignored by the caller in that case
# +	return selection;
# +}
# +
# +// A special extend for ajax options
# +// that takes "flat" options (not to be deep extended)
# +// Fixes #9887
# +function ajaxExtend( target, src ) {
# +	var key, deep,
# +		flatOptions = jQuery.ajaxSettings.flatOptions || {};
# +	for( key in src ) {
# +		if ( src[ key ] !== undefined ) {
# +			( flatOptions[ key ] ? target : ( deep || ( deep = {} ) ) )[ key ] = src[ key ];
# +		}
# +	}
# +	if ( deep ) {
# +		jQuery.extend( true, target, deep );
# +	}
# +}
# +
# +jQuery.fn.extend({
# +	load: function( url, params, callback ) {
# +		if ( typeof url !== "string" && _load ) {
# +			return _load.apply( this, arguments );
# +
# +		// Don't do a request if no elements are being requested
# +		} else if ( !this.length ) {
# +			return this;
# +		}
# +
# +		var off = url.indexOf( " " );
# +		if ( off >= 0 ) {
# +			var selector = url.slice( off, url.length );
# +			url = url.slice( 0, off );
# +		}
# +
# +		// Default to a GET request
# +		var type = "GET";
# +
# +		// If the second parameter was provided
# +		if ( params ) {
# +			// If it's a function
# +			if ( jQuery.isFunction( params ) ) {
# +				// We assume that it's the callback
# +				callback = params;
# +				params = undefined;
# +
# +			// Otherwise, build a param string
# +			} else if ( typeof params === "object" ) {
# +				params = jQuery.param( params, jQuery.ajaxSettings.traditional );
# +				type = "POST";
# +			}
# +		}
# +
# +		var self = this;
# +
# +		// Request the remote document
# +		jQuery.ajax({
# +			url: url,
# +			type: type,
# +			dataType: "html",
# +			data: params,
# +			// Complete callback (responseText is used internally)
# +			complete: function( jqXHR, status, responseText ) {
# +				// Store the response as specified by the jqXHR object
# +				responseText = jqXHR.responseText;
# +				// If successful, inject the HTML into all the matched elements
# +				if ( jqXHR.isResolved() ) {
# +					// #4825: Get the actual response in case
# +					// a dataFilter is present in ajaxSettings
# +					jqXHR.done(function( r ) {
# +						responseText = r;
# +					});
# +					// See if a selector was specified
# +					self.html( selector ?
# +						// Create a dummy div to hold the results
# +						jQuery("<div>")
# +							// inject the contents of the document in, removing the scripts
# +							// to avoid any 'Permission Denied' errors in IE
# +							.append(responseText.replace(rscript, ""))
# +
# +							// Locate the specified elements
# +							.find(selector) :
# +
# +						// If not, just inject the full result
# +						responseText );
# +				}
# +
# +				if ( callback ) {
# +					self.each( callback, [ responseText, status, jqXHR ] );
# +				}
# +			}
# +		});
# +
# +		return this;
# +	},
# +
# +	serialize: function() {
# +		return jQuery.param( this.serializeArray() );
# +	},
# +
# +	serializeArray: function() {
# +		return this.map(function(){
# +			return this.elements ? jQuery.makeArray( this.elements ) : this;
# +		})
# +		.filter(function(){
# +			return this.name && !this.disabled &&
# +				( this.checked || rselectTextarea.test( this.nodeName ) ||
# +					rinput.test( this.type ) );
# +		})
# +		.map(function( i, elem ){
# +			var val = jQuery( this ).val();
# +
# +			return val == null ?
# +				null :
# +				jQuery.isArray( val ) ?
# +					jQuery.map( val, function( val, i ){
# +						return { name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
# +					}) :
# +					{ name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
# +		}).get();
# +	}
# +});
# +
# +// Attach a bunch of functions for handling common AJAX events
# +jQuery.each( "ajaxStart ajaxStop ajaxComplete ajaxError ajaxSuccess ajaxSend".split( " " ), function( i, o ){
# +	jQuery.fn[ o ] = function( f ){
# +		return this.bind( o, f );
# +	};
# +});
# +
# +jQuery.each( [ "get", "post" ], function( i, method ) {
# +	jQuery[ method ] = function( url, data, callback, type ) {
# +		// shift arguments if data argument was omitted
# +		if ( jQuery.isFunction( data ) ) {
# +			type = type || callback;
# +			callback = data;
# +			data = undefined;
# +		}
# +
# +		return jQuery.ajax({
# +			type: method,
# +			url: url,
# +			data: data,
# +			success: callback,
# +			dataType: type
# +		});
# +	};
# +});
# +
# +jQuery.extend({
# +
# +	getScript: function( url, callback ) {
# +		return jQuery.get( url, undefined, callback, "script" );
# +	},
# +
# +	getJSON: function( url, data, callback ) {
# +		return jQuery.get( url, data, callback, "json" );
# +	},
# +
# +	// Creates a full fledged settings object into target
# +	// with both ajaxSettings and settings fields.
# +	// If target is omitted, writes into ajaxSettings.
# +	ajaxSetup: function( target, settings ) {
# +		if ( settings ) {
# +			// Building a settings object
# +			ajaxExtend( target, jQuery.ajaxSettings );
# +		} else {
# +			// Extending ajaxSettings
# +			settings = target;
# +			target = jQuery.ajaxSettings;
# +		}
# +		ajaxExtend( target, settings );
# +		return target;
# +	},
# +
# +	ajaxSettings: {
# +		url: ajaxLocation,
# +		isLocal: rlocalProtocol.test( ajaxLocParts[ 1 ] ),
# +		global: true,
# +		type: "GET",
# +		contentType: "application/x-www-form-urlencoded",
# +		processData: true,
# +		async: true,
# +		/*
# +		timeout: 0,
# +		data: null,
# +		dataType: null,
# +		username: null,
# +		password: null,
# +		cache: null,
# +		traditional: false,
# +		headers: {},
# +		*/
# +
# +		accepts: {
# +			xml: "application/xml, text/xml",
# +			html: "text/html",
# +			text: "text/plain",
# +			json: "application/json, text/javascript",
# +			"*": allTypes
# +		},
# +
# +		contents: {
# +			xml: /xml/,
# +			html: /html/,
# +			json: /json/
# +		},
# +
# +		responseFields: {
# +			xml: "responseXML",
# +			text: "responseText"
# +		},
# +
# +		// List of data converters
# +		// 1) key format is "source_type destination_type" (a single space in-between)
# +		// 2) the catchall symbol "*" can be used for source_type
# +		converters: {
# +
# +			// Convert anything to text
# +			"* text": window.String,
# +
# +			// Text to html (true = no transformation)
# +			"text html": true,
# +
# +			// Evaluate text as a json expression
# +			"text json": jQuery.parseJSON,
# +
# +			// Parse text as xml
# +			"text xml": jQuery.parseXML
# +		},
# +
# +		// For options that shouldn't be deep extended:
# +		// you can add your own custom options here if
# +		// and when you create one that shouldn't be
# +		// deep extended (see ajaxExtend)
# +		flatOptions: {
# +			context: true,
# +			url: true
# +		}
# +	},
# +
# +	ajaxPrefilter: addToPrefiltersOrTransports( prefilters ),
# +	ajaxTransport: addToPrefiltersOrTransports( transports ),
# +
# +	// Main method
# +	ajax: function( url, options ) {
# +
# +		// If url is an object, simulate pre-1.5 signature
# +		if ( typeof url === "object" ) {
# +			options = url;
# +			url = undefined;
# +		}
# +
# +		// Force options to be an object
# +		options = options || {};
# +
# +		var // Create the final options object
# +			s = jQuery.ajaxSetup( {}, options ),
# +			// Callbacks context
# +			callbackContext = s.context || s,
# +			// Context for global events
# +			// It's the callbackContext if one was provided in the options
# +			// and if it's a DOM node or a jQuery collection
# +			globalEventContext = callbackContext !== s &&
# +				( callbackContext.nodeType || callbackContext instanceof jQuery ) ?
# +						jQuery( callbackContext ) : jQuery.event,
# +			// Deferreds
# +			deferred = jQuery.Deferred(),
# +			completeDeferred = jQuery._Deferred(),
# +			// Status-dependent callbacks
# +			statusCode = s.statusCode || {},
# +			// ifModified key
# +			ifModifiedKey,
# +			// Headers (they are sent all at once)
# +			requestHeaders = {},
# +			requestHeadersNames = {},
# +			// Response headers
# +			responseHeadersString,
# +			responseHeaders,
# +			// transport
# +			transport,
# +			// timeout handle
# +			timeoutTimer,
# +			// Cross-domain detection vars
# +			parts,
# +			// The jqXHR state
# +			state = 0,
# +			// To know if global events are to be dispatched
# +			fireGlobals,
# +			// Loop variable
# +			i,
# +			// Fake xhr
# +			jqXHR = {
# +
# +				readyState: 0,
# +
# +				// Caches the header
# +				setRequestHeader: function( name, value ) {
# +					if ( !state ) {
# +						var lname = name.toLowerCase();
# +						name = requestHeadersNames[ lname ] = requestHeadersNames[ lname ] || name;
# +						requestHeaders[ name ] = value;
# +					}
# +					return this;
# +				},
# +
# +				// Raw string
# +				getAllResponseHeaders: function() {
# +					return state === 2 ? responseHeadersString : null;
# +				},
# +
# +				// Builds headers hashtable if needed
# +				getResponseHeader: function( key ) {
# +					var match;
# +					if ( state === 2 ) {
# +						if ( !responseHeaders ) {
# +							responseHeaders = {};
# +							while( ( match = rheaders.exec( responseHeadersString ) ) ) {
# +								responseHeaders[ match[1].toLowerCase() ] = match[ 2 ];
# +							}
# +						}
# +						match = responseHeaders[ key.toLowerCase() ];
# +					}
# +					return match === undefined ? null : match;
# +				},
# +
# +				// Overrides response content-type header
# +				overrideMimeType: function( type ) {
# +					if ( !state ) {
# +						s.mimeType = type;
# +					}
# +					return this;
# +				},
# +
# +				// Cancel the request
# +				abort: function( statusText ) {
# +					statusText = statusText || "abort";
# +					if ( transport ) {
# +						transport.abort( statusText );
# +					}
# +					done( 0, statusText );
# +					return this;
# +				}
# +			};
# +
# +		// Callback for when everything is done
# +		// It is defined here because jslint complains if it is declared
# +		// at the end of the function (which would be more logical and readable)
# +		function done( status, nativeStatusText, responses, headers ) {
# +
# +			// Called once
# +			if ( state === 2 ) {
# +				return;
# +			}
# +
# +			// State is "done" now
# +			state = 2;
# +
# +			// Clear timeout if it exists
# +			if ( timeoutTimer ) {
# +				clearTimeout( timeoutTimer );
# +			}
# +
# +			// Dereference transport for early garbage collection
# +			// (no matter how long the jqXHR object will be used)
# +			transport = undefined;
# +
# +			// Cache response headers
# +			responseHeadersString = headers || "";
# +
# +			// Set readyState
# +			jqXHR.readyState = status > 0 ? 4 : 0;
# +
# +			var isSuccess,
# +				success,
# +				error,
# +				statusText = nativeStatusText,
# +				response = responses ? ajaxHandleResponses( s, jqXHR, responses ) : undefined,
# +				lastModified,
# +				etag;
# +
# +			// If successful, handle type chaining
# +			if ( status >= 200 && status < 300 || status === 304 ) {
# +
# +				// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
# +				if ( s.ifModified ) {
# +
# +					if ( ( lastModified = jqXHR.getResponseHeader( "Last-Modified" ) ) ) {
# +						jQuery.lastModified[ ifModifiedKey ] = lastModified;
# +					}
# +					if ( ( etag = jqXHR.getResponseHeader( "Etag" ) ) ) {
# +						jQuery.etag[ ifModifiedKey ] = etag;
# +					}
# +				}
# +
# +				// If not modified
# +				if ( status === 304 ) {
# +
# +					statusText = "notmodified";
# +					isSuccess = true;
# +
# +				// If we have data
# +				} else {
# +
# +					try {
# +						success = ajaxConvert( s, response );
# +						statusText = "success";
# +						isSuccess = true;
# +					} catch(e) {
# +						// We have a parsererror
# +						statusText = "parsererror";
# +						error = e;
# +					}
# +				}
# +			} else {
# +				// We extract error from statusText
# +				// then normalize statusText and status for non-aborts
# +				error = statusText;
# +				if( !statusText || status ) {
# +					statusText = "error";
# +					if ( status < 0 ) {
# +						status = 0;
# +					}
# +				}
# +			}
# +
# +			// Set data for the fake xhr object
# +			jqXHR.status = status;
# +			jqXHR.statusText = "" + ( nativeStatusText || statusText );
# +
# +			// Success/Error
# +			if ( isSuccess ) {
# +				deferred.resolveWith( callbackContext, [ success, statusText, jqXHR ] );
# +			} else {
# +				deferred.rejectWith( callbackContext, [ jqXHR, statusText, error ] );
# +			}
# +
# +			// Status-dependent callbacks
# +			jqXHR.statusCode( statusCode );
# +			statusCode = undefined;
# +
# +			if ( fireGlobals ) {
# +				globalEventContext.trigger( "ajax" + ( isSuccess ? "Success" : "Error" ),
# +						[ jqXHR, s, isSuccess ? success : error ] );
# +			}
# +
# +			// Complete
# +			completeDeferred.resolveWith( callbackContext, [ jqXHR, statusText ] );
# +
# +			if ( fireGlobals ) {
# +				globalEventContext.trigger( "ajaxComplete", [ jqXHR, s ] );
# +				// Handle the global AJAX counter
# +				if ( !( --jQuery.active ) ) {
# +					jQuery.event.trigger( "ajaxStop" );
# +				}
# +			}
# +		}
# +
# +		// Attach deferreds
# +		deferred.promise( jqXHR );
# +		jqXHR.success = jqXHR.done;
# +		jqXHR.error = jqXHR.fail;
# +		jqXHR.complete = completeDeferred.done;
# +
# +		// Status-dependent callbacks
# +		jqXHR.statusCode = function( map ) {
# +			if ( map ) {
# +				var tmp;
# +				if ( state < 2 ) {
# +					for( tmp in map ) {
# +						statusCode[ tmp ] = [ statusCode[tmp], map[tmp] ];
# +					}
# +				} else {
# +					tmp = map[ jqXHR.status ];
# +					jqXHR.then( tmp, tmp );
# +				}
# +			}
# +			return this;
# +		};
# +
# +		// Remove hash character (#7531: and string promotion)
# +		// Add protocol if not provided (#5866: IE7 issue with protocol-less urls)
# +		// We also use the url parameter if available
# +		s.url = ( ( url || s.url ) + "" ).replace( rhash, "" ).replace( rprotocol, ajaxLocParts[ 1 ] + "//" );
# +
# +		// Extract dataTypes list
# +		s.dataTypes = jQuery.trim( s.dataType || "*" ).toLowerCase().split( rspacesAjax );
# +
# +		// Determine if a cross-domain request is in order
# +		if ( s.crossDomain == null ) {
# +			parts = rurl.exec( s.url.toLowerCase() );
# +			s.crossDomain = !!( parts &&
# +				( parts[ 1 ] != ajaxLocParts[ 1 ] || parts[ 2 ] != ajaxLocParts[ 2 ] ||
# +					( parts[ 3 ] || ( parts[ 1 ] === "http:" ? 80 : 443 ) ) !=
# +						( ajaxLocParts[ 3 ] || ( ajaxLocParts[ 1 ] === "http:" ? 80 : 443 ) ) )
# +			);
# +		}
# +
# +		// Convert data if not already a string
# +		if ( s.data && s.processData && typeof s.data !== "string" ) {
# +			s.data = jQuery.param( s.data, s.traditional );
# +		}
# +
# +		// Apply prefilters
# +		inspectPrefiltersOrTransports( prefilters, s, options, jqXHR );
# +
# +		// If request was aborted inside a prefiler, stop there
# +		if ( state === 2 ) {
# +			return false;
# +		}
# +
# +		// We can fire global events as of now if asked to
# +		fireGlobals = s.global;
# +
# +		// Uppercase the type
# +		s.type = s.type.toUpperCase();
# +
# +		// Determine if request has content
# +		s.hasContent = !rnoContent.test( s.type );
# +
# +		// Watch for a new set of requests
# +		if ( fireGlobals && jQuery.active++ === 0 ) {
# +			jQuery.event.trigger( "ajaxStart" );
# +		}
# +
# +		// More options handling for requests with no content
# +		if ( !s.hasContent ) {
# +
# +			// If data is available, append data to url
# +			if ( s.data ) {
# +				s.url += ( rquery.test( s.url ) ? "&" : "?" ) + s.data;
# +				// #9682: remove data so that it's not used in an eventual retry
# +				delete s.data;
# +			}
# +
# +			// Get ifModifiedKey before adding the anti-cache parameter
# +			ifModifiedKey = s.url;
# +
# +			// Add anti-cache in url if needed
# +			if ( s.cache === false ) {
# +
# +				var ts = jQuery.now(),
# +					// try replacing _= if it is there
# +					ret = s.url.replace( rts, "$1_=" + ts );
# +
# +				// if nothing was replaced, add timestamp to the end
# +				s.url = ret + ( (ret === s.url ) ? ( rquery.test( s.url ) ? "&" : "?" ) + "_=" + ts : "" );
# +			}
# +		}
# +
# +		// Set the correct header, if data is being sent
# +		if ( s.data && s.hasContent && s.contentType !== false || options.contentType ) {
# +			jqXHR.setRequestHeader( "Content-Type", s.contentType );
# +		}
# +
# +		// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
# +		if ( s.ifModified ) {
# +			ifModifiedKey = ifModifiedKey || s.url;
# +			if ( jQuery.lastModified[ ifModifiedKey ] ) {
# +				jqXHR.setRequestHeader( "If-Modified-Since", jQuery.lastModified[ ifModifiedKey ] );
# +			}
# +			if ( jQuery.etag[ ifModifiedKey ] ) {
# +				jqXHR.setRequestHeader( "If-None-Match", jQuery.etag[ ifModifiedKey ] );
# +			}
# +		}
# +
# +		// Set the Accepts header for the server, depending on the dataType
# +		jqXHR.setRequestHeader(
# +			"Accept",
# +			s.dataTypes[ 0 ] && s.accepts[ s.dataTypes[0] ] ?
# +				s.accepts[ s.dataTypes[0] ] + ( s.dataTypes[ 0 ] !== "*" ? ", " + allTypes + "; q=0.01" : "" ) :
# +				s.accepts[ "*" ]
# +		);
# +
# +		// Check for headers option
# +		for ( i in s.headers ) {
# +			jqXHR.setRequestHeader( i, s.headers[ i ] );
# +		}
# +
# +		// Allow custom headers/mimetypes and early abort
# +		if ( s.beforeSend && ( s.beforeSend.call( callbackContext, jqXHR, s ) === false || state === 2 ) ) {
# +				// Abort if not done already
# +				jqXHR.abort();
# +				return false;
# +
# +		}
# +
# +		// Install callbacks on deferreds
# +		for ( i in { success: 1, error: 1, complete: 1 } ) {
# +			jqXHR[ i ]( s[ i ] );
# +		}
# +
# +		// Get transport
# +		transport = inspectPrefiltersOrTransports( transports, s, options, jqXHR );
# +
# +		// If no transport, we auto-abort
# +		if ( !transport ) {
# +			done( -1, "No Transport" );
# +		} else {
# +			jqXHR.readyState = 1;
# +			// Send global event
# +			if ( fireGlobals ) {
# +				globalEventContext.trigger( "ajaxSend", [ jqXHR, s ] );
# +			}
# +			// Timeout
# +			if ( s.async && s.timeout > 0 ) {
# +				timeoutTimer = setTimeout( function(){
# +					jqXHR.abort( "timeout" );
# +				}, s.timeout );
# +			}
# +
# +			try {
# +				state = 1;
# +				transport.send( requestHeaders, done );
# +			} catch (e) {
# +				// Propagate exception as error if not done
# +				if ( state < 2 ) {
# +					done( -1, e );
# +				// Simply rethrow otherwise
# +				} else {
# +					jQuery.error( e );
# +				}
# +			}
# +		}
# +
# +		return jqXHR;
# +	},
# +
# +	// Serialize an array of form elements or a set of
# +	// key/values into a query string
# +	param: function( a, traditional ) {
# +		var s = [],
# +			add = function( key, value ) {
# +				// If value is a function, invoke it and return its value
# +				value = jQuery.isFunction( value ) ? value() : value;
# +				s[ s.length ] = encodeURIComponent( key ) + "=" + encodeURIComponent( value );
# +			};
# +
# +		// Set traditional to true for jQuery <= 1.3.2 behavior.
# +		if ( traditional === undefined ) {
# +			traditional = jQuery.ajaxSettings.traditional;
# +		}
# +
# +		// If an array was passed in, assume that it is an array of form elements.
# +		if ( jQuery.isArray( a ) || ( a.jquery && !jQuery.isPlainObject( a ) ) ) {
# +			// Serialize the form elements
# +			jQuery.each( a, function() {
# +				add( this.name, this.value );
# +			});
# +
# +		} else {
# +			// If traditional, encode the "old" way (the way 1.3.2 or older
# +			// did it), otherwise encode params recursively.
# +			for ( var prefix in a ) {
# +				buildParams( prefix, a[ prefix ], traditional, add );
# +			}
# +		}
# +
# +		// Return the resulting serialization
# +		return s.join( "&" ).replace( r20, "+" );
# +	}
# +});
# +
# +function buildParams( prefix, obj, traditional, add ) {
# +	if ( jQuery.isArray( obj ) ) {
# +		// Serialize array item.
# +		jQuery.each( obj, function( i, v ) {
# +			if ( traditional || rbracket.test( prefix ) ) {
# +				// Treat each array item as a scalar.
# +				add( prefix, v );
# +
# +			} else {
# +				// If array item is non-scalar (array or object), encode its
# +				// numeric index to resolve deserialization ambiguity issues.
# +				// Note that rack (as of 1.0.0) can't currently deserialize
# +				// nested arrays properly, and attempting to do so may cause
# +				// a server error. Possible fixes are to modify rack's
# +				// deserialization algorithm or to provide an option or flag
# +				// to force array serialization to be shallow.
# +				buildParams( prefix + "[" + ( typeof v === "object" || jQuery.isArray(v) ? i : "" ) + "]", v, traditional, add );
# +			}
# +		});
# +
# +	} else if ( !traditional && obj != null && typeof obj === "object" ) {
# +		// Serialize object item.
# +		for ( var name in obj ) {
# +			buildParams( prefix + "[" + name + "]", obj[ name ], traditional, add );
# +		}
# +
# +	} else {
# +		// Serialize scalar item.
# +		add( prefix, obj );
# +	}
# +}
# +
# +// This is still on the jQuery object... for now
# +// Want to move this to jQuery.ajax some day
# +jQuery.extend({
# +
# +	// Counter for holding the number of active queries
# +	active: 0,
# +
# +	// Last-Modified header cache for next request
# +	lastModified: {},
# +	etag: {}
# +
# +});
# +
# +/* Handles responses to an ajax request:
# + * - sets all responseXXX fields accordingly
# + * - finds the right dataType (mediates between content-type and expected dataType)
# + * - returns the corresponding response
# + */
# +function ajaxHandleResponses( s, jqXHR, responses ) {
# +
# +	var contents = s.contents,
# +		dataTypes = s.dataTypes,
# +		responseFields = s.responseFields,
# +		ct,
# +		type,
# +		finalDataType,
# +		firstDataType;
# +
# +	// Fill responseXXX fields
# +	for( type in responseFields ) {
# +		if ( type in responses ) {
# +			jqXHR[ responseFields[type] ] = responses[ type ];
# +		}
# +	}
# +
# +	// Remove auto dataType and get content-type in the process
# +	while( dataTypes[ 0 ] === "*" ) {
# +		dataTypes.shift();
# +		if ( ct === undefined ) {
# +			ct = s.mimeType || jqXHR.getResponseHeader( "content-type" );
# +		}
# +	}
# +
# +	// Check if we're dealing with a known content-type
# +	if ( ct ) {
# +		for ( type in contents ) {
# +			if ( contents[ type ] && contents[ type ].test( ct ) ) {
# +				dataTypes.unshift( type );
# +				break;
# +			}
# +		}
# +	}
# +
# +	// Check to see if we have a response for the expected dataType
# +	if ( dataTypes[ 0 ] in responses ) {
# +		finalDataType = dataTypes[ 0 ];
# +	} else {
# +		// Try convertible dataTypes
# +		for ( type in responses ) {
# +			if ( !dataTypes[ 0 ] || s.converters[ type + " " + dataTypes[0] ] ) {
# +				finalDataType = type;
# +				break;
# +			}
# +			if ( !firstDataType ) {
# +				firstDataType = type;
# +			}
# +		}
# +		// Or just use first one
# +		finalDataType = finalDataType || firstDataType;
# +	}
# +
# +	// If we found a dataType
# +	// We add the dataType to the list if needed
# +	// and return the corresponding response
# +	if ( finalDataType ) {
# +		if ( finalDataType !== dataTypes[ 0 ] ) {
# +			dataTypes.unshift( finalDataType );
# +		}
# +		return responses[ finalDataType ];
# +	}
# +}
# +
# +// Chain conversions given the request and the original response
# +function ajaxConvert( s, response ) {
# +
# +	// Apply the dataFilter if provided
# +	if ( s.dataFilter ) {
# +		response = s.dataFilter( response, s.dataType );
# +	}
# +
# +	var dataTypes = s.dataTypes,
# +		converters = {},
# +		i,
# +		key,
# +		length = dataTypes.length,
# +		tmp,
# +		// Current and previous dataTypes
# +		current = dataTypes[ 0 ],
# +		prev,
# +		// Conversion expression
# +		conversion,
# +		// Conversion function
# +		conv,
# +		// Conversion functions (transitive conversion)
# +		conv1,
# +		conv2;
# +
# +	// For each dataType in the chain
# +	for( i = 1; i < length; i++ ) {
# +
# +		// Create converters map
# +		// with lowercased keys
# +		if ( i === 1 ) {
# +			for( key in s.converters ) {
# +				if( typeof key === "string" ) {
# +					converters[ key.toLowerCase() ] = s.converters[ key ];
# +				}
# +			}
# +		}
# +
# +		// Get the dataTypes
# +		prev = current;
# +		current = dataTypes[ i ];
# +
# +		// If current is auto dataType, update it to prev
# +		if( current === "*" ) {
# +			current = prev;
# +		// If no auto and dataTypes are actually different
# +		} else if ( prev !== "*" && prev !== current ) {
# +
# +			// Get the converter
# +			conversion = prev + " " + current;
# +			conv = converters[ conversion ] || converters[ "* " + current ];
# +
# +			// If there is no direct converter, search transitively
# +			if ( !conv ) {
# +				conv2 = undefined;
# +				for( conv1 in converters ) {
# +					tmp = conv1.split( " " );
# +					if ( tmp[ 0 ] === prev || tmp[ 0 ] === "*" ) {
# +						conv2 = converters[ tmp[1] + " " + current ];
# +						if ( conv2 ) {
# +							conv1 = converters[ conv1 ];
# +							if ( conv1 === true ) {
# +								conv = conv2;
# +							} else if ( conv2 === true ) {
# +								conv = conv1;
# +							}
# +							break;
# +						}
# +					}
# +				}
# +			}
# +			// If we found no converter, dispatch an error
# +			if ( !( conv || conv2 ) ) {
# +				jQuery.error( "No conversion from " + conversion.replace(" "," to ") );
# +			}
# +			// If found converter is not an equivalence
# +			if ( conv !== true ) {
# +				// Convert with 1 or 2 converters accordingly
# +				response = conv ? conv( response ) : conv2( conv1(response) );
# +			}
# +		}
# +	}
# +	return response;
# +}
# +
# +
# +
# +
# +var jsc = jQuery.now(),
# +	jsre = /(\=)\?(&|$)|\?\?/i;
# +
# +// Default jsonp settings
# +jQuery.ajaxSetup({
# +	jsonp: "callback",
# +	jsonpCallback: function() {
# +		return jQuery.expando + "_" + ( jsc++ );
# +	}
# +});
# +
# +// Detect, normalize options and install callbacks for jsonp requests
# +jQuery.ajaxPrefilter( "json jsonp", function( s, originalSettings, jqXHR ) {
# +
# +	var inspectData = s.contentType === "application/x-www-form-urlencoded" &&
# +		( typeof s.data === "string" );
# +
# +	if ( s.dataTypes[ 0 ] === "jsonp" ||
# +		s.jsonp !== false && ( jsre.test( s.url ) ||
# +				inspectData && jsre.test( s.data ) ) ) {
# +
# +		var responseContainer,
# +			jsonpCallback = s.jsonpCallback =
# +				jQuery.isFunction( s.jsonpCallback ) ? s.jsonpCallback() : s.jsonpCallback,
# +			previous = window[ jsonpCallback ],
# +			url = s.url,
# +			data = s.data,
# +			replace = "$1" + jsonpCallback + "$2";
# +
# +		if ( s.jsonp !== false ) {
# +			url = url.replace( jsre, replace );
# +			if ( s.url === url ) {
# +				if ( inspectData ) {
# +					data = data.replace( jsre, replace );
# +				}
# +				if ( s.data === data ) {
# +					// Add callback manually
# +					url += (/\?/.test( url ) ? "&" : "?") + s.jsonp + "=" + jsonpCallback;
# +				}
# +			}
# +		}
# +
# +		s.url = url;
# +		s.data = data;
# +
# +		// Install callback
# +		window[ jsonpCallback ] = function( response ) {
# +			responseContainer = [ response ];
# +		};
# +
# +		// Clean-up function
# +		jqXHR.always(function() {
# +			// Set callback back to previous value
# +			window[ jsonpCallback ] = previous;
# +			// Call if it was a function and we have a response
# +			if ( responseContainer && jQuery.isFunction( previous ) ) {
# +				window[ jsonpCallback ]( responseContainer[ 0 ] );
# +			}
# +		});
# +
# +		// Use data converter to retrieve json after script execution
# +		s.converters["script json"] = function() {
# +			if ( !responseContainer ) {
# +				jQuery.error( jsonpCallback + " was not called" );
# +			}
# +			return responseContainer[ 0 ];
# +		};
# +
# +		// force json dataType
# +		s.dataTypes[ 0 ] = "json";
# +
# +		// Delegate to script
# +		return "script";
# +	}
# +});
# +
# +
# +
# +
# +// Install script dataType
# +jQuery.ajaxSetup({
# +	accepts: {
# +		script: "text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"
# +	},
# +	contents: {
# +		script: /javascript|ecmascript/
# +	},
# +	converters: {
# +		"text script": function( text ) {
# +			jQuery.globalEval( text );
# +			return text;
# +		}
# +	}
# +});
# +
# +// Handle cache's special case and global
# +jQuery.ajaxPrefilter( "script", function( s ) {
# +	if ( s.cache === undefined ) {
# +		s.cache = false;
# +	}
# +	if ( s.crossDomain ) {
# +		s.type = "GET";
# +		s.global = false;
# +	}
# +});
# +
# +// Bind script tag hack transport
# +jQuery.ajaxTransport( "script", function(s) {
# +
# +	// This transport only deals with cross domain requests
# +	if ( s.crossDomain ) {
# +
# +		var script,
# +			head = document.head || document.getElementsByTagName( "head" )[0] || document.documentElement;
# +
# +		return {
# +
# +			send: function( _, callback ) {
# +
# +				script = document.createElement( "script" );
# +
# +				script.async = "async";
# +
# +				if ( s.scriptCharset ) {
# +					script.charset = s.scriptCharset;
# +				}
# +
# +				script.src = s.url;
# +
# +				// Attach handlers for all browsers
# +				script.onload = script.onreadystatechange = function( _, isAbort ) {
# +
# +					if ( isAbort || !script.readyState || /loaded|complete/.test( script.readyState ) ) {
# +
# +						// Handle memory leak in IE
# +						script.onload = script.onreadystatechange = null;
# +
# +						// Remove the script
# +						if ( head && script.parentNode ) {
# +							head.removeChild( script );
# +						}
# +
# +						// Dereference the script
# +						script = undefined;
# +
# +						// Callback if not abort
# +						if ( !isAbort ) {
# +							callback( 200, "success" );
# +						}
# +					}
# +				};
# +				// Use insertBefore instead of appendChild  to circumvent an IE6 bug.
# +				// This arises when a base node is used (#2709 and #4378).
# +				head.insertBefore( script, head.firstChild );
# +			},
# +
# +			abort: function() {
# +				if ( script ) {
# +					script.onload( 0, 1 );
# +				}
# +			}
# +		};
# +	}
# +});
# +
# +
# +
# +
# +var // #5280: Internet Explorer will keep connections alive if we don't abort on unload
# +	xhrOnUnloadAbort = window.ActiveXObject ? function() {
# +		// Abort all pending requests
# +		for ( var key in xhrCallbacks ) {
# +			xhrCallbacks[ key ]( 0, 1 );
# +		}
# +	} : false,
# +	xhrId = 0,
# +	xhrCallbacks;
# +
# +// Functions to create xhrs
# +function createStandardXHR() {
# +	try {
# +		return new window.XMLHttpRequest();
# +	} catch( e ) {}
# +}
# +
# +function createActiveXHR() {
# +	try {
# +		return new window.ActiveXObject( "Microsoft.XMLHTTP" );
# +	} catch( e ) {}
# +}
# +
# +// Create the request object
# +// (This is still attached to ajaxSettings for backward compatibility)
# +jQuery.ajaxSettings.xhr = window.ActiveXObject ?
# +	/* Microsoft failed to properly
# +	 * implement the XMLHttpRequest in IE7 (can't request local files),
# +	 * so we use the ActiveXObject when it is available
# +	 * Additionally XMLHttpRequest can be disabled in IE7/IE8 so
# +	 * we need a fallback.
# +	 */
# +	function() {
# +		return !this.isLocal && createStandardXHR() || createActiveXHR();
# +	} :
# +	// For all other browsers, use the standard XMLHttpRequest object
# +	createStandardXHR;
# +
# +// Determine support properties
# +(function( xhr ) {
# +	jQuery.extend( jQuery.support, {
# +		ajax: !!xhr,
# +		cors: !!xhr && ( "withCredentials" in xhr )
# +	});
# +})( jQuery.ajaxSettings.xhr() );
# +
# +// Create transport if the browser can provide an xhr
# +if ( jQuery.support.ajax ) {
# +
# +	jQuery.ajaxTransport(function( s ) {
# +		// Cross domain only allowed if supported through XMLHttpRequest
# +		if ( !s.crossDomain || jQuery.support.cors ) {
# +
# +			var callback;
# +
# +			return {
# +				send: function( headers, complete ) {
# +
# +					// Get a new xhr
# +					var xhr = s.xhr(),
# +						handle,
# +						i;
# +
# +					// Open the socket
# +					// Passing null username, generates a login popup on Opera (#2865)
# +					if ( s.username ) {
# +						xhr.open( s.type, s.url, s.async, s.username, s.password );
# +					} else {
# +						xhr.open( s.type, s.url, s.async );
# +					}
# +
# +					// Apply custom fields if provided
# +					if ( s.xhrFields ) {
# +						for ( i in s.xhrFields ) {
# +							xhr[ i ] = s.xhrFields[ i ];
# +						}
# +					}
# +
# +					// Override mime type if needed
# +					if ( s.mimeType && xhr.overrideMimeType ) {
# +						xhr.overrideMimeType( s.mimeType );
# +					}
# +
# +					// X-Requested-With header
# +					// For cross-domain requests, seeing as conditions for a preflight are
# +					// akin to a jigsaw puzzle, we simply never set it to be sure.
# +					// (it can always be set on a per-request basis or even using ajaxSetup)
# +					// For same-domain requests, won't change header if already provided.
# +					if ( !s.crossDomain && !headers["X-Requested-With"] ) {
# +						headers[ "X-Requested-With" ] = "XMLHttpRequest";
# +					}
# +
# +					// Need an extra try/catch for cross domain requests in Firefox 3
# +					try {
# +						for ( i in headers ) {
# +							xhr.setRequestHeader( i, headers[ i ] );
# +						}
# +					} catch( _ ) {}
# +
# +					// Do send the request
# +					// This may raise an exception which is actually
# +					// handled in jQuery.ajax (so no try/catch here)
# +					xhr.send( ( s.hasContent && s.data ) || null );
# +
# +					// Listener
# +					callback = function( _, isAbort ) {
# +
# +						var status,
# +							statusText,
# +							responseHeaders,
# +							responses,
# +							xml;
# +
# +						// Firefox throws exceptions when accessing properties
# +						// of an xhr when a network error occured
# +						// http://helpful.knobs-dials.com/index.php/Component_returned_failure_code:_0x80040111_(NS_ERROR_NOT_AVAILABLE)
# +						try {
# +
# +							// Was never called and is aborted or complete
# +							if ( callback && ( isAbort || xhr.readyState === 4 ) ) {
# +
# +								// Only called once
# +								callback = undefined;
# +
# +								// Do not keep as active anymore
# +								if ( handle ) {
# +									xhr.onreadystatechange = jQuery.noop;
# +									if ( xhrOnUnloadAbort ) {
# +										delete xhrCallbacks[ handle ];
# +									}
# +								}
# +
# +								// If it's an abort
# +								if ( isAbort ) {
# +									// Abort it manually if needed
# +									if ( xhr.readyState !== 4 ) {
# +										xhr.abort();
# +									}
# +								} else {
# +									status = xhr.status;
# +									responseHeaders = xhr.getAllResponseHeaders();
# +									responses = {};
# +									xml = xhr.responseXML;
# +
# +									// Construct response list
# +									if ( xml && xml.documentElement /* #4958 */ ) {
# +										responses.xml = xml;
# +									}
# +									responses.text = xhr.responseText;
# +
# +									// Firefox throws an exception when accessing
# +									// statusText for faulty cross-domain requests
# +									try {
# +										statusText = xhr.statusText;
# +									} catch( e ) {
# +										// We normalize with Webkit giving an empty statusText
# +										statusText = "";
# +									}
# +
# +									// Filter status for non standard behaviors
# +
# +									// If the request is local and we have data: assume a success
# +									// (success with no data won't get notified, that's the best we
# +									// can do given current implementations)
# +									if ( !status && s.isLocal && !s.crossDomain ) {
# +										status = responses.text ? 200 : 404;
# +									// IE - #1450: sometimes returns 1223 when it should be 204
# +									} else if ( status === 1223 ) {
# +										status = 204;
# +									}
# +								}
# +							}
# +						} catch( firefoxAccessException ) {
# +							if ( !isAbort ) {
# +								complete( -1, firefoxAccessException );
# +							}
# +						}
# +
# +						// Call complete if needed
# +						if ( responses ) {
# +							complete( status, statusText, responses, responseHeaders );
# +						}
# +					};
# +
# +					// if we're in sync mode or it's in cache
# +					// and has been retrieved directly (IE6 & IE7)
# +					// we need to manually fire the callback
# +					if ( !s.async || xhr.readyState === 4 ) {
# +						callback();
# +					} else {
# +						handle = ++xhrId;
# +						if ( xhrOnUnloadAbort ) {
# +							// Create the active xhrs callbacks list if needed
# +							// and attach the unload handler
# +							if ( !xhrCallbacks ) {
# +								xhrCallbacks = {};
# +								jQuery( window ).unload( xhrOnUnloadAbort );
# +							}
# +							// Add to list of active xhrs callbacks
# +							xhrCallbacks[ handle ] = callback;
# +						}
# +						xhr.onreadystatechange = callback;
# +					}
# +				},
# +
# +				abort: function() {
# +					if ( callback ) {
# +						callback(0,1);
# +					}
# +				}
# +			};
# +		}
# +	});
# +}
# +
# +
# +
# +
# +var elemdisplay = {},
# +	iframe, iframeDoc,
# +	rfxtypes = /^(?:toggle|show|hide)$/,
# +	rfxnum = /^([+\-]=)?([\d+.\-]+)([a-z%]*)$/i,
# +	timerId,
# +	fxAttrs = [
# +		// height animations
# +		[ "height", "marginTop", "marginBottom", "paddingTop", "paddingBottom" ],
# +		// width animations
# +		[ "width", "marginLeft", "marginRight", "paddingLeft", "paddingRight" ],
# +		// opacity animations
# +		[ "opacity" ]
# +	],
# +	fxNow;
# +
# +jQuery.fn.extend({
# +	show: function( speed, easing, callback ) {
# +		var elem, display;
# +
# +		if ( speed || speed === 0 ) {
# +			return this.animate( genFx("show", 3), speed, easing, callback);
# +
# +		} else {
# +			for ( var i = 0, j = this.length; i < j; i++ ) {
# +				elem = this[i];
# +
# +				if ( elem.style ) {
# +					display = elem.style.display;
# +
# +					// Reset the inline display of this element to learn if it is
# +					// being hidden by cascaded rules or not
# +					if ( !jQuery._data(elem, "olddisplay") && display === "none" ) {
# +						display = elem.style.display = "";
# +					}
# +
# +					// Set elements which have been overridden with display: none
# +					// in a stylesheet to whatever the default browser style is
# +					// for such an element
# +					if ( display === "" && jQuery.css( elem, "display" ) === "none" ) {
# +						jQuery._data(elem, "olddisplay", defaultDisplay(elem.nodeName));
# +					}
# +				}
# +			}
# +
# +			// Set the display of most of the elements in a second loop
# +			// to avoid the constant reflow
# +			for ( i = 0; i < j; i++ ) {
# +				elem = this[i];
# +
# +				if ( elem.style ) {
# +					display = elem.style.display;
# +
# +					if ( display === "" || display === "none" ) {
# +						elem.style.display = jQuery._data(elem, "olddisplay") || "";
# +					}
# +				}
# +			}
# +
# +			return this;
# +		}
# +	},
# +
# +	hide: function( speed, easing, callback ) {
# +		if ( speed || speed === 0 ) {
# +			return this.animate( genFx("hide", 3), speed, easing, callback);
# +
# +		} else {
# +			for ( var i = 0, j = this.length; i < j; i++ ) {
# +				if ( this[i].style ) {
# +					var display = jQuery.css( this[i], "display" );
# +
# +					if ( display !== "none" && !jQuery._data( this[i], "olddisplay" ) ) {
# +						jQuery._data( this[i], "olddisplay", display );
# +					}
# +				}
# +			}
# +
# +			// Set the display of the elements in a second loop
# +			// to avoid the constant reflow
# +			for ( i = 0; i < j; i++ ) {
# +				if ( this[i].style ) {
# +					this[i].style.display = "none";
# +				}
# +			}
# +
# +			return this;
# +		}
# +	},
# +
# +	// Save the old toggle function
# +	_toggle: jQuery.fn.toggle,
# +
# +	toggle: function( fn, fn2, callback ) {
# +		var bool = typeof fn === "boolean";
# +
# +		if ( jQuery.isFunction(fn) && jQuery.isFunction(fn2) ) {
# +			this._toggle.apply( this, arguments );
# +
# +		} else if ( fn == null || bool ) {
# +			this.each(function() {
# +				var state = bool ? fn : jQuery(this).is(":hidden");
# +				jQuery(this)[ state ? "show" : "hide" ]();
# +			});
# +
# +		} else {
# +			this.animate(genFx("toggle", 3), fn, fn2, callback);
# +		}
# +
# +		return this;
# +	},
# +
# +	fadeTo: function( speed, to, easing, callback ) {
# +		return this.filter(":hidden").css("opacity", 0).show().end()
# +					.animate({opacity: to}, speed, easing, callback);
# +	},
# +
# +	animate: function( prop, speed, easing, callback ) {
# +		var optall = jQuery.speed(speed, easing, callback);
# +
# +		if ( jQuery.isEmptyObject( prop ) ) {
# +			return this.each( optall.complete, [ false ] );
# +		}
# +
# +		// Do not change referenced properties as per-property easing will be lost
# +		prop = jQuery.extend( {}, prop );
# +
# +		return this[ optall.queue === false ? "each" : "queue" ](function() {
# +			// XXX 'this' does not always have a nodeName when running the
# +			// test suite
# +
# +			if ( optall.queue === false ) {
# +				jQuery._mark( this );
# +			}
# +
# +			var opt = jQuery.extend( {}, optall ),
# +				isElement = this.nodeType === 1,
# +				hidden = isElement && jQuery(this).is(":hidden"),
# +				name, val, p,
# +				display, e,
# +				parts, start, end, unit;
# +
# +			// will store per property easing and be used to determine when an animation is complete
# +			opt.animatedProperties = {};
# +
# +			for ( p in prop ) {
# +
# +				// property name normalization
# +				name = jQuery.camelCase( p );
# +				if ( p !== name ) {
# +					prop[ name ] = prop[ p ];
# +					delete prop[ p ];
# +				}
# +
# +				val = prop[ name ];
# +
# +				// easing resolution: per property > opt.specialEasing > opt.easing > 'swing' (default)
# +				if ( jQuery.isArray( val ) ) {
# +					opt.animatedProperties[ name ] = val[ 1 ];
# +					val = prop[ name ] = val[ 0 ];
# +				} else {
# +					opt.animatedProperties[ name ] = opt.specialEasing && opt.specialEasing[ name ] || opt.easing || 'swing';
# +				}
# +
# +				if ( val === "hide" && hidden || val === "show" && !hidden ) {
# +					return opt.complete.call( this );
# +				}
# +
# +				if ( isElement && ( name === "height" || name === "width" ) ) {
# +					// Make sure that nothing sneaks out
# +					// Record all 3 overflow attributes because IE does not
# +					// change the overflow attribute when overflowX and
# +					// overflowY are set to the same value
# +					opt.overflow = [ this.style.overflow, this.style.overflowX, this.style.overflowY ];
# +
# +					// Set display property to inline-block for height/width
# +					// animations on inline elements that are having width/height
# +					// animated
# +					if ( jQuery.css( this, "display" ) === "inline" &&
# +							jQuery.css( this, "float" ) === "none" ) {
# +						if ( !jQuery.support.inlineBlockNeedsLayout ) {
# +							this.style.display = "inline-block";
# +
# +						} else {
# +							display = defaultDisplay( this.nodeName );
# +
# +							// inline-level elements accept inline-block;
# +							// block-level elements need to be inline with layout
# +							if ( display === "inline" ) {
# +								this.style.display = "inline-block";
# +
# +							} else {
# +								this.style.display = "inline";
# +								this.style.zoom = 1;
# +							}
# +						}
# +					}
# +				}
# +			}
# +
# +			if ( opt.overflow != null ) {
# +				this.style.overflow = "hidden";
# +			}
# +
# +			for ( p in prop ) {
# +				e = new jQuery.fx( this, opt, p );
# +				val = prop[ p ];
# +
# +				if ( rfxtypes.test(val) ) {
# +					e[ val === "toggle" ? hidden ? "show" : "hide" : val ]();
# +
# +				} else {
# +					parts = rfxnum.exec( val );
# +					start = e.cur();
# +
# +					if ( parts ) {
# +						end = parseFloat( parts[2] );
# +						unit = parts[3] || ( jQuery.cssNumber[ p ] ? "" : "px" );
# +
# +						// We need to compute starting value
# +						if ( unit !== "px" ) {
# +							jQuery.style( this, p, (end || 1) + unit);
# +							start = ((end || 1) / e.cur()) * start;
# +							jQuery.style( this, p, start + unit);
# +						}
# +
# +						// If a +=/-= token was provided, we're doing a relative animation
# +						if ( parts[1] ) {
# +							end = ( (parts[ 1 ] === "-=" ? -1 : 1) * end ) + start;
# +						}
# +
# +						e.custom( start, end, unit );
# +
# +					} else {
# +						e.custom( start, val, "" );
# +					}
# +				}
# +			}
# +
# +			// For JS strict compliance
# +			return true;
# +		});
# +	},
# +
# +	stop: function( clearQueue, gotoEnd ) {
# +		if ( clearQueue ) {
# +			this.queue([]);
# +		}
# +
# +		this.each(function() {
# +			var timers = jQuery.timers,
# +				i = timers.length;
# +			// clear marker counters if we know they won't be
# +			if ( !gotoEnd ) {
# +				jQuery._unmark( true, this );
# +			}
# +			while ( i-- ) {
# +				if ( timers[i].elem === this ) {
# +					if (gotoEnd) {
# +						// force the next step to be the last
# +						timers[i](true);
# +					}
# +
# +					timers.splice(i, 1);
# +				}
# +			}
# +		});
# +
# +		// start the next in the queue if the last step wasn't forced
# +		if ( !gotoEnd ) {
# +			this.dequeue();
# +		}
# +
# +		return this;
# +	}
# +
# +});
# +
# +// Animations created synchronously will run synchronously
# +function createFxNow() {
# +	setTimeout( clearFxNow, 0 );
# +	return ( fxNow = jQuery.now() );
# +}
# +
# +function clearFxNow() {
# +	fxNow = undefined;
# +}
# +
# +// Generate parameters to create a standard animation
# +function genFx( type, num ) {
# +	var obj = {};
# +
# +	jQuery.each( fxAttrs.concat.apply([], fxAttrs.slice(0,num)), function() {
# +		obj[ this ] = type;
# +	});
# +
# +	return obj;
# +}
# +
# +// Generate shortcuts for custom animations
# +jQuery.each({
# +	slideDown: genFx("show", 1),
# +	slideUp: genFx("hide", 1),
# +	slideToggle: genFx("toggle", 1),
# +	fadeIn: { opacity: "show" },
# +	fadeOut: { opacity: "hide" },
# +	fadeToggle: { opacity: "toggle" }
# +}, function( name, props ) {
# +	jQuery.fn[ name ] = function( speed, easing, callback ) {
# +		return this.animate( props, speed, easing, callback );
# +	};
# +});
# +
# +jQuery.extend({
# +	speed: function( speed, easing, fn ) {
# +		var opt = speed && typeof speed === "object" ? jQuery.extend({}, speed) : {
# +			complete: fn || !fn && easing ||
# +				jQuery.isFunction( speed ) && speed,
# +			duration: speed,
# +			easing: fn && easing || easing && !jQuery.isFunction(easing) && easing
# +		};
# +
# +		opt.duration = jQuery.fx.off ? 0 : typeof opt.duration === "number" ? opt.duration :
# +			opt.duration in jQuery.fx.speeds ? jQuery.fx.speeds[opt.duration] : jQuery.fx.speeds._default;
# +
# +		// Queueing
# +		opt.old = opt.complete;
# +		opt.complete = function( noUnmark ) {
# +			if ( jQuery.isFunction( opt.old ) ) {
# +				opt.old.call( this );
# +			}
# +
# +			if ( opt.queue !== false ) {
# +				jQuery.dequeue( this );
# +			} else if ( noUnmark !== false ) {
# +				jQuery._unmark( this );
# +			}
# +		};
# +
# +		return opt;
# +	},
# +
# +	easing: {
# +		linear: function( p, n, firstNum, diff ) {
# +			return firstNum + diff * p;
# +		},
# +		swing: function( p, n, firstNum, diff ) {
# +			return ((-Math.cos(p*Math.PI)/2) + 0.5) * diff + firstNum;
# +		}
# +	},
# +
# +	timers: [],
# +
# +	fx: function( elem, options, prop ) {
# +		this.options = options;
# +		this.elem = elem;
# +		this.prop = prop;
# +
# +		options.orig = options.orig || {};
# +	}
# +
# +});
# +
# +jQuery.fx.prototype = {
# +	// Simple function for setting a style value
# +	update: function() {
# +		if ( this.options.step ) {
# +			this.options.step.call( this.elem, this.now, this );
# +		}
# +
# +		(jQuery.fx.step[this.prop] || jQuery.fx.step._default)( this );
# +	},
# +
# +	// Get the current size
# +	cur: function() {
# +		if ( this.elem[this.prop] != null && (!this.elem.style || this.elem.style[this.prop] == null) ) {
# +			return this.elem[ this.prop ];
# +		}
# +
# +		var parsed,
# +			r = jQuery.css( this.elem, this.prop );
# +		// Empty strings, null, undefined and "auto" are converted to 0,
# +		// complex values such as "rotate(1rad)" are returned as is,
# +		// simple values such as "10px" are parsed to Float.
# +		return isNaN( parsed = parseFloat( r ) ) ? !r || r === "auto" ? 0 : r : parsed;
# +	},
# +
# +	// Start an animation from one number to another
# +	custom: function( from, to, unit ) {
# +		var self = this,
# +			fx = jQuery.fx;
# +
# +		this.startTime = fxNow || createFxNow();
# +		this.start = from;
# +		this.end = to;
# +		this.unit = unit || this.unit || ( jQuery.cssNumber[ this.prop ] ? "" : "px" );
# +		this.now = this.start;
# +		this.pos = this.state = 0;
# +
# +		function t( gotoEnd ) {
# +			return self.step(gotoEnd);
# +		}
# +
# +		t.elem = this.elem;
# +
# +		if ( t() && jQuery.timers.push(t) && !timerId ) {
# +			timerId = setInterval( fx.tick, fx.interval );
# +		}
# +	},
# +
# +	// Simple 'show' function
# +	show: function() {
# +		// Remember where we started, so that we can go back to it later
# +		this.options.orig[this.prop] = jQuery.style( this.elem, this.prop );
# +		this.options.show = true;
# +
# +		// Begin the animation
# +		// Make sure that we start at a small width/height to avoid any
# +		// flash of content
# +		this.custom(this.prop === "width" || this.prop === "height" ? 1 : 0, this.cur());
# +
# +		// Start by showing the element
# +		jQuery( this.elem ).show();
# +	},
# +
# +	// Simple 'hide' function
# +	hide: function() {
# +		// Remember where we started, so that we can go back to it later
# +		this.options.orig[this.prop] = jQuery.style( this.elem, this.prop );
# +		this.options.hide = true;
# +
# +		// Begin the animation
# +		this.custom(this.cur(), 0);
# +	},
# +
# +	// Each step of an animation
# +	step: function( gotoEnd ) {
# +		var t = fxNow || createFxNow(),
# +			done = true,
# +			elem = this.elem,
# +			options = this.options,
# +			i, n;
# +
# +		if ( gotoEnd || t >= options.duration + this.startTime ) {
# +			this.now = this.end;
# +			this.pos = this.state = 1;
# +			this.update();
# +
# +			options.animatedProperties[ this.prop ] = true;
# +
# +			for ( i in options.animatedProperties ) {
# +				if ( options.animatedProperties[i] !== true ) {
# +					done = false;
# +				}
# +			}
# +
# +			if ( done ) {
# +				// Reset the overflow
# +				if ( options.overflow != null && !jQuery.support.shrinkWrapBlocks ) {
# +
# +					jQuery.each( [ "", "X", "Y" ], function (index, value) {
# +						elem.style[ "overflow" + value ] = options.overflow[index];
# +					});
# +				}
# +
# +				// Hide the element if the "hide" operation was done
# +				if ( options.hide ) {
# +					jQuery(elem).hide();
# +				}
# +
# +				// Reset the properties, if the item has been hidden or shown
# +				if ( options.hide || options.show ) {
# +					for ( var p in options.animatedProperties ) {
# +						jQuery.style( elem, p, options.orig[p] );
# +					}
# +				}
# +
# +				// Execute the complete function
# +				options.complete.call( elem );
# +			}
# +
# +			return false;
# +
# +		} else {
# +			// classical easing cannot be used with an Infinity duration
# +			if ( options.duration == Infinity ) {
# +				this.now = t;
# +			} else {
# +				n = t - this.startTime;
# +				this.state = n / options.duration;
# +
# +				// Perform the easing function, defaults to swing
# +				this.pos = jQuery.easing[ options.animatedProperties[ this.prop ] ]( this.state, n, 0, 1, options.duration );
# +				this.now = this.start + ((this.end - this.start) * this.pos);
# +			}
# +			// Perform the next step of the animation
# +			this.update();
# +		}
# +
# +		return true;
# +	}
# +};
# +
# +jQuery.extend( jQuery.fx, {
# +	tick: function() {
# +		for ( var timers = jQuery.timers, i = 0 ; i < timers.length ; ++i ) {
# +			if ( !timers[i]() ) {
# +				timers.splice(i--, 1);
# +			}
# +		}
# +
# +		if ( !timers.length ) {
# +			jQuery.fx.stop();
# +		}
# +	},
# +
# +	interval: 13,
# +
# +	stop: function() {
# +		clearInterval( timerId );
# +		timerId = null;
# +	},
# +
# +	speeds: {
# +		slow: 600,
# +		fast: 200,
# +		// Default speed
# +		_default: 400
# +	},
# +
# +	step: {
# +		opacity: function( fx ) {
# +			jQuery.style( fx.elem, "opacity", fx.now );
# +		},
# +
# +		_default: function( fx ) {
# +			if ( fx.elem.style && fx.elem.style[ fx.prop ] != null ) {
# +				fx.elem.style[ fx.prop ] = (fx.prop === "width" || fx.prop === "height" ? Math.max(0, fx.now) : fx.now) + fx.unit;
# +			} else {
# +				fx.elem[ fx.prop ] = fx.now;
# +			}
# +		}
# +	}
# +});
# +
# +if ( jQuery.expr && jQuery.expr.filters ) {
# +	jQuery.expr.filters.animated = function( elem ) {
# +		return jQuery.grep(jQuery.timers, function( fn ) {
# +			return elem === fn.elem;
# +		}).length;
# +	};
# +}
# +
# +// Try to restore the default display value of an element
# +function defaultDisplay( nodeName ) {
# +
# +	if ( !elemdisplay[ nodeName ] ) {
# +
# +		var body = document.body,
# +			elem = jQuery( "<" + nodeName + ">" ).appendTo( body ),
# +			display = elem.css( "display" );
# +
# +		elem.remove();
# +
# +		// If the simple way fails,
# +		// get element's real default display by attaching it to a temp iframe
# +		if ( display === "none" || display === "" ) {
# +			// No iframe to use yet, so create it
# +			if ( !iframe ) {
# +				iframe = document.createElement( "iframe" );
# +				iframe.frameBorder = iframe.width = iframe.height = 0;
# +			}
# +
# +			body.appendChild( iframe );
# +
# +			// Create a cacheable copy of the iframe document on first call.
# +			// IE and Opera will allow us to reuse the iframeDoc without re-writing the fake HTML
# +			// document to it; WebKit & Firefox won't allow reusing the iframe document.
# +			if ( !iframeDoc || !iframe.createElement ) {
# +				iframeDoc = ( iframe.contentWindow || iframe.contentDocument ).document;
# +				iframeDoc.write( ( document.compatMode === "CSS1Compat" ? "<!doctype html>" : "" ) + "<html><body>" );
# +				iframeDoc.close();
# +			}
# +
# +			elem = iframeDoc.createElement( nodeName );
# +
# +			iframeDoc.body.appendChild( elem );
# +
# +			display = jQuery.css( elem, "display" );
# +
# +			body.removeChild( iframe );
# +		}
# +
# +		// Store the correct default display
# +		elemdisplay[ nodeName ] = display;
# +	}
# +
# +	return elemdisplay[ nodeName ];
# +}
# +
# +
# +
# +
# +var rtable = /^t(?:able|d|h)$/i,
# +	rroot = /^(?:body|html)$/i;
# +
# +if ( "getBoundingClientRect" in document.documentElement ) {
# +	jQuery.fn.offset = function( options ) {
# +		var elem = this[0], box;
# +
# +		if ( options ) {
# +			return this.each(function( i ) {
# +				jQuery.offset.setOffset( this, options, i );
# +			});
# +		}
# +
# +		if ( !elem || !elem.ownerDocument ) {
# +			return null;
# +		}
# +
# +		if ( elem === elem.ownerDocument.body ) {
# +			return jQuery.offset.bodyOffset( elem );
# +		}
# +
# +		try {
# +			box = elem.getBoundingClientRect();
# +		} catch(e) {}
# +
# +		var doc = elem.ownerDocument,
# +			docElem = doc.documentElement;
# +
# +		// Make sure we're not dealing with a disconnected DOM node
# +		if ( !box || !jQuery.contains( docElem, elem ) ) {
# +			return box ? { top: box.top, left: box.left } : { top: 0, left: 0 };
# +		}
# +
# +		var body = doc.body,
# +			win = getWindow(doc),
# +			clientTop  = docElem.clientTop  || body.clientTop  || 0,
# +			clientLeft = docElem.clientLeft || body.clientLeft || 0,
# +			scrollTop  = win.pageYOffset || jQuery.support.boxModel && docElem.scrollTop  || body.scrollTop,
# +			scrollLeft = win.pageXOffset || jQuery.support.boxModel && docElem.scrollLeft || body.scrollLeft,
# +			top  = box.top  + scrollTop  - clientTop,
# +			left = box.left + scrollLeft - clientLeft;
# +
# +		return { top: top, left: left };
# +	};
# +
# +} else {
# +	jQuery.fn.offset = function( options ) {
# +		var elem = this[0];
# +
# +		if ( options ) {
# +			return this.each(function( i ) {
# +				jQuery.offset.setOffset( this, options, i );
# +			});
# +		}
# +
# +		if ( !elem || !elem.ownerDocument ) {
# +			return null;
# +		}
# +
# +		if ( elem === elem.ownerDocument.body ) {
# +			return jQuery.offset.bodyOffset( elem );
# +		}
# +
# +		jQuery.offset.initialize();
# +
# +		var computedStyle,
# +			offsetParent = elem.offsetParent,
# +			prevOffsetParent = elem,
# +			doc = elem.ownerDocument,
# +			docElem = doc.documentElement,
# +			body = doc.body,
# +			defaultView = doc.defaultView,
# +			prevComputedStyle = defaultView ? defaultView.getComputedStyle( elem, null ) : elem.currentStyle,
# +			top = elem.offsetTop,
# +			left = elem.offsetLeft;
# +
# +		while ( (elem = elem.parentNode) && elem !== body && elem !== docElem ) {
# +			if ( jQuery.offset.supportsFixedPosition && prevComputedStyle.position === "fixed" ) {
# +				break;
# +			}
# +
# +			computedStyle = defaultView ? defaultView.getComputedStyle(elem, null) : elem.currentStyle;
# +			top  -= elem.scrollTop;
# +			left -= elem.scrollLeft;
# +
# +			if ( elem === offsetParent ) {
# +				top  += elem.offsetTop;
# +				left += elem.offsetLeft;
# +
# +				if ( jQuery.offset.doesNotAddBorder && !(jQuery.offset.doesAddBorderForTableAndCells && rtable.test(elem.nodeName)) ) {
# +					top  += parseFloat( computedStyle.borderTopWidth  ) || 0;
# +					left += parseFloat( computedStyle.borderLeftWidth ) || 0;
# +				}
# +
# +				prevOffsetParent = offsetParent;
# +				offsetParent = elem.offsetParent;
# +			}
# +
# +			if ( jQuery.offset.subtractsBorderForOverflowNotVisible && computedStyle.overflow !== "visible" ) {
# +				top  += parseFloat( computedStyle.borderTopWidth  ) || 0;
# +				left += parseFloat( computedStyle.borderLeftWidth ) || 0;
# +			}
# +
# +			prevComputedStyle = computedStyle;
# +		}
# +
# +		if ( prevComputedStyle.position === "relative" || prevComputedStyle.position === "static" ) {
# +			top  += body.offsetTop;
# +			left += body.offsetLeft;
# +		}
# +
# +		if ( jQuery.offset.supportsFixedPosition && prevComputedStyle.position === "fixed" ) {
# +			top  += Math.max( docElem.scrollTop, body.scrollTop );
# +			left += Math.max( docElem.scrollLeft, body.scrollLeft );
# +		}
# +
# +		return { top: top, left: left };
# +	};
# +}
# +
# +jQuery.offset = {
# +	initialize: function() {
# +		var body = document.body, container = document.createElement("div"), innerDiv, checkDiv, table, td, bodyMarginTop = parseFloat( jQuery.css(body, "marginTop") ) || 0,
# +			html = "<div style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;'><div></div></div><table style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;' cellpadding='0' cellspacing='0'><tr><td></td></tr></table>";
# +
# +		jQuery.extend( container.style, { position: "absolute", top: 0, left: 0, margin: 0, border: 0, width: "1px", height: "1px", visibility: "hidden" } );
# +
# +		container.innerHTML = html;
# +		body.insertBefore( container, body.firstChild );
# +		innerDiv = container.firstChild;
# +		checkDiv = innerDiv.firstChild;
# +		td = innerDiv.nextSibling.firstChild.firstChild;
# +
# +		this.doesNotAddBorder = (checkDiv.offsetTop !== 5);
# +		this.doesAddBorderForTableAndCells = (td.offsetTop === 5);
# +
# +		checkDiv.style.position = "fixed";
# +		checkDiv.style.top = "20px";
# +
# +		// safari subtracts parent border width here which is 5px
# +		this.supportsFixedPosition = (checkDiv.offsetTop === 20 || checkDiv.offsetTop === 15);
# +		checkDiv.style.position = checkDiv.style.top = "";
# +
# +		innerDiv.style.overflow = "hidden";
# +		innerDiv.style.position = "relative";
# +
# +		this.subtractsBorderForOverflowNotVisible = (checkDiv.offsetTop === -5);
# +
# +		this.doesNotIncludeMarginInBodyOffset = (body.offsetTop !== bodyMarginTop);
# +
# +		body.removeChild( container );
# +		jQuery.offset.initialize = jQuery.noop;
# +	},
# +
# +	bodyOffset: function( body ) {
# +		var top = body.offsetTop,
# +			left = body.offsetLeft;
# +
# +		jQuery.offset.initialize();
# +
# +		if ( jQuery.offset.doesNotIncludeMarginInBodyOffset ) {
# +			top  += parseFloat( jQuery.css(body, "marginTop") ) || 0;
# +			left += parseFloat( jQuery.css(body, "marginLeft") ) || 0;
# +		}
# +
# +		return { top: top, left: left };
# +	},
# +
# +	setOffset: function( elem, options, i ) {
# +		var position = jQuery.css( elem, "position" );
# +
# +		// set position first, in-case top/left are set even on static elem
# +		if ( position === "static" ) {
# +			elem.style.position = "relative";
# +		}
# +
# +		var curElem = jQuery( elem ),
# +			curOffset = curElem.offset(),
# +			curCSSTop = jQuery.css( elem, "top" ),
# +			curCSSLeft = jQuery.css( elem, "left" ),
# +			calculatePosition = (position === "absolute" || position === "fixed") && jQuery.inArray("auto", [curCSSTop, curCSSLeft]) > -1,
# +			props = {}, curPosition = {}, curTop, curLeft;
# +
# +		// need to be able to calculate position if either top or left is auto and position is either absolute or fixed
# +		if ( calculatePosition ) {
# +			curPosition = curElem.position();
# +			curTop = curPosition.top;
# +			curLeft = curPosition.left;
# +		} else {
# +			curTop = parseFloat( curCSSTop ) || 0;
# +			curLeft = parseFloat( curCSSLeft ) || 0;
# +		}
# +
# +		if ( jQuery.isFunction( options ) ) {
# +			options = options.call( elem, i, curOffset );
# +		}
# +
# +		if (options.top != null) {
# +			props.top = (options.top - curOffset.top) + curTop;
# +		}
# +		if (options.left != null) {
# +			props.left = (options.left - curOffset.left) + curLeft;
# +		}
# +
# +		if ( "using" in options ) {
# +			options.using.call( elem, props );
# +		} else {
# +			curElem.css( props );
# +		}
# +	}
# +};
# +
# +
# +jQuery.fn.extend({
# +	position: function() {
# +		if ( !this[0] ) {
# +			return null;
# +		}
# +
# +		var elem = this[0],
# +
# +		// Get *real* offsetParent
# +		offsetParent = this.offsetParent(),
# +
# +		// Get correct offsets
# +		offset       = this.offset(),
# +		parentOffset = rroot.test(offsetParent[0].nodeName) ? { top: 0, left: 0 } : offsetParent.offset();
# +
# +		// Subtract element margins
# +		// note: when an element has margin: auto the offsetLeft and marginLeft
# +		// are the same in Safari causing offset.left to incorrectly be 0
# +		offset.top  -= parseFloat( jQuery.css(elem, "marginTop") ) || 0;
# +		offset.left -= parseFloat( jQuery.css(elem, "marginLeft") ) || 0;
# +
# +		// Add offsetParent borders
# +		parentOffset.top  += parseFloat( jQuery.css(offsetParent[0], "borderTopWidth") ) || 0;
# +		parentOffset.left += parseFloat( jQuery.css(offsetParent[0], "borderLeftWidth") ) || 0;
# +
# +		// Subtract the two offsets
# +		return {
# +			top:  offset.top  - parentOffset.top,
# +			left: offset.left - parentOffset.left
# +		};
# +	},
# +
# +	offsetParent: function() {
# +		return this.map(function() {
# +			var offsetParent = this.offsetParent || document.body;
# +			while ( offsetParent && (!rroot.test(offsetParent.nodeName) && jQuery.css(offsetParent, "position") === "static") ) {
# +				offsetParent = offsetParent.offsetParent;
# +			}
# +			return offsetParent;
# +		});
# +	}
# +});
# +
# +
# +// Create scrollLeft and scrollTop methods
# +jQuery.each( ["Left", "Top"], function( i, name ) {
# +	var method = "scroll" + name;
# +
# +	jQuery.fn[ method ] = function( val ) {
# +		var elem, win;
# +
# +		if ( val === undefined ) {
# +			elem = this[ 0 ];
# +
# +			if ( !elem ) {
# +				return null;
# +			}
# +
# +			win = getWindow( elem );
# +
# +			// Return the scroll offset
# +			return win ? ("pageXOffset" in win) ? win[ i ? "pageYOffset" : "pageXOffset" ] :
# +				jQuery.support.boxModel && win.document.documentElement[ method ] ||
# +					win.document.body[ method ] :
# +				elem[ method ];
# +		}
# +
# +		// Set the scroll offset
# +		return this.each(function() {
# +			win = getWindow( this );
# +
# +			if ( win ) {
# +				win.scrollTo(
# +					!i ? val : jQuery( win ).scrollLeft(),
# +					 i ? val : jQuery( win ).scrollTop()
# +				);
# +
# +			} else {
# +				this[ method ] = val;
# +			}
# +		});
# +	};
# +});
# +
# +function getWindow( elem ) {
# +	return jQuery.isWindow( elem ) ?
# +		elem :
# +		elem.nodeType === 9 ?
# +			elem.defaultView || elem.parentWindow :
# +			false;
# +}
# +
# +
# +
# +
# +// Create width, height, innerHeight, innerWidth, outerHeight and outerWidth methods
# +jQuery.each([ "Height", "Width" ], function( i, name ) {
# +
# +	var type = name.toLowerCase();
# +
# +	// innerHeight and innerWidth
# +	jQuery.fn[ "inner" + name ] = function() {
# +		var elem = this[0];
# +		return elem && elem.style ?
# +			parseFloat( jQuery.css( elem, type, "padding" ) ) :
# +			null;
# +	};
# +
# +	// outerHeight and outerWidth
# +	jQuery.fn[ "outer" + name ] = function( margin ) {
# +		var elem = this[0];
# +		return elem && elem.style ?
# +			parseFloat( jQuery.css( elem, type, margin ? "margin" : "border" ) ) :
# +			null;
# +	};
# +
# +	jQuery.fn[ type ] = function( size ) {
# +		// Get window width or height
# +		var elem = this[0];
# +		if ( !elem ) {
# +			return size == null ? null : this;
# +		}
# +
# +		if ( jQuery.isFunction( size ) ) {
# +			return this.each(function( i ) {
# +				var self = jQuery( this );
# +				self[ type ]( size.call( this, i, self[ type ]() ) );
# +			});
# +		}
# +
# +		if ( jQuery.isWindow( elem ) ) {
# +			// Everyone else use document.documentElement or document.body depending on Quirks vs Standards mode
# +			// 3rd condition allows Nokia support, as it supports the docElem prop but not CSS1Compat
# +			var docElemProp = elem.document.documentElement[ "client" + name ],
# +				body = elem.document.body;
# +			return elem.document.compatMode === "CSS1Compat" && docElemProp ||
# +				body && body[ "client" + name ] || docElemProp;
# +
# +		// Get document width or height
# +		} else if ( elem.nodeType === 9 ) {
# +			// Either scroll[Width/Height] or offset[Width/Height], whichever is greater
# +			return Math.max(
# +				elem.documentElement["client" + name],
# +				elem.body["scroll" + name], elem.documentElement["scroll" + name],
# +				elem.body["offset" + name], elem.documentElement["offset" + name]
# +			);
# +
# +		// Get or set width or height on the element
# +		} else if ( size === undefined ) {
# +			var orig = jQuery.css( elem, type ),
# +				ret = parseFloat( orig );
# +
# +			return jQuery.isNaN( ret ) ? orig : ret;
# +
# +		// Set the width or height on the element (default to pixels if value is unitless)
# +		} else {
# +			return this.css( type, typeof size === "string" ? size : size + "px" );
# +		}
# +	};
# +
# +});
# +
# +
# +// Expose jQuery to the global object
# +window.jQuery = window.$ = jQuery;
# +})(window);
# diff -Nru debian~/newruby debian/newruby
# --- debian~/newruby	1969-12-31 19:00:00.000000000 -0500
# +++ debian/newruby	2021-01-25 23:37:04.806005435 -0500
# @@ -0,0 +1,29 @@
# +#!/bin/sh
# +
# +set -e
# +
# +if [ $# -ne 1 ]; then
# +  echo "usage: $0 NEWVERSION"
# +  exit 1
# +fi
# +
# +old_source=$(dpkg-parsechangelog -SSource)
# +old_version=${old_source##ruby}
# +
# +new_version="$1"
# +new_source="ruby${new_version}"
# +new_api_version="${new_version}.0"
# +
# +files_to_change=$(grep -rl "${old_source}" debian/ | grep -v changelog)
# +
# +set -x
# +sed -i -e "s/${old_source}/${new_source}/g; s/${old_version}.\[0-9]/${new_api_version}/g; s/${old_version}/${new_version}/g" $files_to_change
# +
# +rename "s/${old_source}/${new_source}/" debian/*${old_source}*
# +
# +# manpages
# +sed -i -e "s/\(gem\|rdoc\)${old_version}/\1${new_version}/gi" \
# +	debian/manpages/* debian/*.manpages
# +rename "s/${old_version}/${new_version}/g" debian/manpages/*
# +
# +dch --package "${new_source}" --newversion "${new_version}.0-1" "Ruby $new_version"
# diff -Nru debian~/openssl.cnf debian/openssl.cnf
# --- debian~/openssl.cnf	1969-12-31 19:00:00.000000000 -0500
# +++ debian/openssl.cnf	2021-01-25 23:37:04.806005435 -0500
# @@ -0,0 +1,7 @@
# +openssl_conf = default_conf
# +[default_conf]
# +ssl_conf = ssl_sect
# +[ssl_sect]
# +system_default = system_default_sect
# +[system_default_sect]
# +CipherString = DEFAULT@SECLEVEL=1
# diff -Nru debian~/patches/0001-rdoc-build-reproducible-documentation.patch debian/patches/0001-rdoc-build-reproducible-documentation.patch
# --- debian~/patches/0001-rdoc-build-reproducible-documentation.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0001-rdoc-build-reproducible-documentation.patch	2021-01-25 23:37:04.806005435 -0500
# @@ -0,0 +1,49 @@
# +From: Christian Hofstaedtler <zeha@debian.org>
# +Date: Tue, 10 Oct 2017 15:04:34 -0300
# +Subject: rdoc: build reproducible documentation
# +
# +- sort input filenames
# +- provide a fixed timestamp to the gzip compression
# +
# +Signed-off-by: Antonio Terceiro <terceiro@debian.org>
# +Signed-off-by: Christian Hofstaedtler <zeha@debian.org>
# +---
# + lib/rdoc/generator/json_index.rb | 4 ++--
# + lib/rdoc/rdoc.rb                 | 2 +-
# + 2 files changed, 3 insertions(+), 3 deletions(-)
# +
# +diff --git a/lib/rdoc/generator/json_index.rb b/lib/rdoc/generator/json_index.rb
# +index 3a10000..f40bb37 100644
# +--- a/lib/rdoc/generator/json_index.rb
# ++++ b/lib/rdoc/generator/json_index.rb
# +@@ -178,7 +178,7 @@ class RDoc::Generator::JsonIndex
# +     debug_msg "Writing gzipped search index to %s" % outfile
# +
# +     Zlib::GzipWriter.open(outfile) do |gz|
# +-      gz.mtime = File.mtime(search_index_file)
# ++      gz.mtime = -1
# +       gz.orig_name = search_index_file.basename.to_s
# +       gz.write search_index
# +       gz.close
# +@@ -196,7 +196,7 @@ class RDoc::Generator::JsonIndex
# +         debug_msg "Writing gzipped file to %s" % outfile
# +
# +         Zlib::GzipWriter.open(outfile) do |gz|
# +-          gz.mtime = File.mtime(dest)
# ++          gz.mtime = -1
# +           gz.orig_name = dest.basename.to_s
# +           gz.write data
# +           gz.close
# +diff --git a/lib/rdoc/rdoc.rb b/lib/rdoc/rdoc.rb
# +index c60e017..368c9dc 100644
# +--- a/lib/rdoc/rdoc.rb
# ++++ b/lib/rdoc/rdoc.rb
# +@@ -312,7 +312,7 @@ option)
# +       end
# +     end
# +
# +-    file_list.flatten
# ++    file_list.flatten.sort
# +   end
# +
# +   ##
# diff -Nru debian~/patches/0002-lib-mkmf.rb-sort-list-of-object-files-in-generated-M.patch debian/patches/0002-lib-mkmf.rb-sort-list-of-object-files-in-generated-M.patch
# --- debian~/patches/0002-lib-mkmf.rb-sort-list-of-object-files-in-generated-M.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0002-lib-mkmf.rb-sort-list-of-object-files-in-generated-M.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,28 @@
# +From: Reiner Herrmann <reiner@reiner-h.de>
# +Date: Tue, 10 Oct 2017 15:06:13 -0300
# +Subject: lib/mkmf.rb: sort list of object files in generated Makefile
# +
# +Without sorting the list explicitly, its order is indeterministic,
# +because readdir() is also not deterministic.
# +When the list of object files varies between builds, they are linked
# +in a different order, which results in an unreproducible build.
# +
# +Signed-off-by: Antonio Terceiro <terceiro@debian.org>
# +Signed-off-by: Reiner Herrmann <reiner@reiner-h.de>
# +---
# + lib/mkmf.rb | 2 +-
# + 1 file changed, 1 insertion(+), 1 deletion(-)
# +
# +diff --git a/lib/mkmf.rb b/lib/mkmf.rb
# +index eabccd4..ce18e82 100644
# +--- a/lib/mkmf.rb
# ++++ b/lib/mkmf.rb
# +@@ -2315,7 +2315,7 @@ LOCAL_LIBS = #{$LOCAL_LIBS}
# + LIBS = #{$LIBRUBYARG} #{$libs} #{$LIBS}
# + ORIG_SRCS = #{orig_srcs.collect(&File.method(:basename)).join(' ')}
# + SRCS = $(ORIG_SRCS) #{(srcs - orig_srcs).collect(&File.method(:basename)).join(' ')}
# +-OBJS = #{$objs.join(" ")}
# ++OBJS = #{$objs.sort.join(" ")}
# + HDRS = #{hdrs.map{|h| '$(srcdir)/' + File.basename(h)}.join(' ')}
# + LOCAL_HDRS = #{$headers.join(' ')}
# + TARGET = #{target}
# diff -Nru debian~/patches/0003-Mark-Gemspec-reproducible-change-fixing-784225-too.patch debian/patches/0003-Mark-Gemspec-reproducible-change-fixing-784225-too.patch
# --- debian~/patches/0003-Mark-Gemspec-reproducible-change-fixing-784225-too.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0003-Mark-Gemspec-reproducible-change-fixing-784225-too.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,28 @@
# +From: Christian Hofstaedtler <zeha@debian.org>
# +Date: Tue, 10 Oct 2017 15:07:11 -0300
# +Subject: Mark Gemspec-reproducible change fixing #784225, too
# +
# +I think the UTC date change will fix the Multi-Arch not-same file issue,
# +too.
# +
# +Signed-off-by: Antonio Terceiro <terceiro@debian.org>
# +Signed-off-by: Christian Hofstaedtler <zeha@debian.org>
# +---
# + lib/rubygems/specification.rb | 4 +++-
# + 1 file changed, 3 insertions(+), 1 deletion(-)
# +
# +diff --git a/lib/rubygems/specification.rb b/lib/rubygems/specification.rb
# +index f925480..e737586 100644
# +--- a/lib/rubygems/specification.rb
# ++++ b/lib/rubygems/specification.rb
# +@@ -1702,7 +1702,9 @@ class Gem::Specification < Gem::BasicSpecification
# +                 raise(Gem::InvalidSpecificationException,
# +                       "invalid date format in specification: #{date.inspect}")
# +               end
# +-            when Time, DateLike then
# ++            when Time then
# ++              Time.utc(date.utc.year, date.utc.month, date.utc.day)
# ++            when DateLike then
# +               Time.utc(date.year, date.month, date.day)
# +             else
# +               TODAY
# diff -Nru debian~/patches/0004-Disable-tests-failing-on-Ubuntu-builders.patch debian/patches/0004-Disable-tests-failing-on-Ubuntu-builders.patch
# --- debian~/patches/0004-Disable-tests-failing-on-Ubuntu-builders.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0004-Disable-tests-failing-on-Ubuntu-builders.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,25 @@
# +From: Chris Hofstaedtler <zeha@debian.org>
# +Date: Sat, 6 Oct 2018 11:43:33 -0300
# +Subject: Disable tests failing on Ubuntu builders
# +
# +---
# + test/excludes/TestFileUtils.rb | 1 +
# + test/excludes/TestProcess.rb   | 1 +
# + 2 files changed, 2 insertions(+)
# + create mode 100644 test/excludes/TestFileUtils.rb
# + create mode 100644 test/excludes/TestProcess.rb
# +
# +diff --git a/test/excludes/TestFileUtils.rb b/test/excludes/TestFileUtils.rb
# +new file mode 100644
# +index 0000000..ee8b15c
# +--- /dev/null
# ++++ b/test/excludes/TestFileUtils.rb
# +@@ -0,0 +1 @@
# ++exclude :test_chown, "fails on Launchpad builders"
# +diff --git a/test/excludes/TestProcess.rb b/test/excludes/TestProcess.rb
# +new file mode 100644
# +index 0000000..37b406e
# +--- /dev/null
# ++++ b/test/excludes/TestProcess.rb
# +@@ -0,0 +1 @@
# ++exclude :test_execopts_gid, "fails on Launchpad builders"
# diff -Nru debian~/patches/0005-Make-gemspecs-reproducible.patch debian/patches/0005-Make-gemspecs-reproducible.patch
# --- debian~/patches/0005-Make-gemspecs-reproducible.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0005-Make-gemspecs-reproducible.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,75 @@
# +From: Lucas Kanashiro <kanashiro@debian.org>
# +Date: Fri, 1 Nov 2019 15:25:17 -0300
# +Subject: Make gemspecs reproducible
# +
# +Without an explicit date, they will get the current date and make the
# +build unreproducible
# +---
# + ext/bigdecimal/bigdecimal.gemspec | 1 +
# + ext/fiddle/fiddle.gemspec         | 1 +
# + ext/io/console/io-console.gemspec | 2 +-
# + lib/ipaddr.gemspec                | 1 +
# + lib/rdoc/rdoc.gemspec             | 1 +
# + 5 files changed, 5 insertions(+), 1 deletion(-)
# +
# +diff --git a/ext/bigdecimal/bigdecimal.gemspec b/ext/bigdecimal/bigdecimal.gemspec
# +index 7d767f5..26de3e0 100644
# +--- a/ext/bigdecimal/bigdecimal.gemspec
# ++++ b/ext/bigdecimal/bigdecimal.gemspec
# +@@ -6,6 +6,7 @@ Gem::Specification.new do |s|
# +   s.name          = "bigdecimal"
# +   s.version       = bigdecimal_version
# +   s.authors       = ["Kenta Murata", "Zachary Scott", "Shigeo Kobayashi"]
# ++  s.date          = RUBY_RELEASE_DATE
# +   s.email         = ["mrkn@mrkn.jp"]
# +
# +   s.summary       = "Arbitrary-precision decimal floating-point number library."
# +diff --git a/ext/fiddle/fiddle.gemspec b/ext/fiddle/fiddle.gemspec
# +index b29f4ec..36ed213 100644
# +--- a/ext/fiddle/fiddle.gemspec
# ++++ b/ext/fiddle/fiddle.gemspec
# +@@ -2,6 +2,7 @@
# + Gem::Specification.new do |spec|
# +   spec.name          = "fiddle"
# +   spec.version       = '1.0.0'
# ++  spec.date          = RUBY_RELEASE_DATE
# +   spec.authors       = ["Aaron Patterson", "SHIBATA Hiroshi"]
# +   spec.email         = ["aaron@tenderlovemaking.com", "hsbt@ruby-lang.org"]
# +
# +diff --git a/ext/io/console/io-console.gemspec b/ext/io/console/io-console.gemspec
# +index 814bd4e..2e50587 100644
# +--- a/ext/io/console/io-console.gemspec
# ++++ b/ext/io/console/io-console.gemspec
# +@@ -5,7 +5,7 @@ date = %w$Date::                           $[1]
# + Gem::Specification.new do |s|
# +   s.name = "io-console"
# +   s.version = _VERSION
# +-  s.date = date
# ++  s.date = RUBY_RELEASE_DATE
# +   s.summary = "Console interface"
# +   s.email = "nobu@ruby-lang.org"
# +   s.description = "add console capabilities to IO instances."
# +diff --git a/lib/ipaddr.gemspec b/lib/ipaddr.gemspec
# +index 2de9ef4..4f8072a 100644
# +--- a/lib/ipaddr.gemspec
# ++++ b/lib/ipaddr.gemspec
# +@@ -6,6 +6,7 @@ $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# + Gem::Specification.new do |spec|
# +   spec.name          = "ipaddr"
# +   spec.version       = "1.2.2"
# ++  spec.date          = RUBY_RELEASE_DATE
# +   spec.authors       = ["Akinori MUSHA", "Hajimu UMEMOTO"]
# +   spec.email         = ["knu@idaemons.org", "ume@mahoroba.org"]
# +
# +diff --git a/lib/rdoc/rdoc.gemspec b/lib/rdoc/rdoc.gemspec
# +index 9b274c7..eb7a47e 100644
# +--- a/lib/rdoc/rdoc.gemspec
# ++++ b/lib/rdoc/rdoc.gemspec
# +@@ -7,6 +7,7 @@ end
# +
# + Gem::Specification.new do |s|
# +   s.name = "rdoc"
# ++  s.date = RUBY_RELEASE_DATE
# +   s.version = RDoc::VERSION
# +
# +   s.authors = [
# diff -Nru debian~/patches/0006-Fix-FTBS-on-hurd.patch debian/patches/0006-Fix-FTBS-on-hurd.patch
# --- debian~/patches/0006-Fix-FTBS-on-hurd.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0006-Fix-FTBS-on-hurd.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,29 @@
# +From: Lucas Kanashiro <kanashiro@debian.org>
# +Date: Fri, 1 Nov 2019 15:41:55 -0300
# +Subject: Fix FTBS on hurd
# +
# +Closes: #896509
# +
# +Signed-off-by: Antonio Terceiro <terceiro@debian.org>
# +Signed-off-by: Samuel Thibault <samuel.thibault@ens-lyon.org>
# +---
# + io.c | 6 +++++-
# + 1 file changed, 5 insertions(+), 1 deletion(-)
# +
# +diff --git a/io.c b/io.c
# +index 868756f..fc00ed0 100644
# +--- a/io.c
# ++++ b/io.c
# +@@ -1753,7 +1753,11 @@ io_writev(int argc, VALUE *argv, VALUE io)
# +
# +     for (i = 0; i < argc; i += cnt) {
# + #ifdef HAVE_WRITEV
# +-	if ((fptr->mode & (FMODE_SYNC|FMODE_TTY)) && iovcnt_ok(cnt = argc - i)) {
# ++        if ((fptr->mode & (FMODE_SYNC|FMODE_TTY))
# ++# ifdef IOV_MAX
# ++               && ((cnt = argc - i) < IOV_MAX)
# ++# endif
# ++               ) {
# +         n = io_fwritev(cnt, &argv[i], fptr);
# +     }
# +     else
# diff -Nru debian~/patches/0007-Port-to-kfreebsd-amd64.patch debian/patches/0007-Port-to-kfreebsd-amd64.patch
# --- debian~/patches/0007-Port-to-kfreebsd-amd64.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0007-Port-to-kfreebsd-amd64.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,109 @@
# +From: Lucas Kanashiro <kanashiro@debian.org>
# +Date: Fri, 1 Nov 2019 16:07:51 -0300
# +Subject: Port to kfreebsd-amd64
# +
# +Closes: #899267
# +
# +Signed-off-by: Antonio Terceiro <terceiro@debian.org>
# +Signed-off-by: Svante Signell <svante.signell@gmail.com>
# +---
# + ext/socket/option.c        |  1 +
# + ext/socket/raddrinfo.c     | 22 ++++++++++++++++++++++
# + test/fiddle/test_handle.rb |  3 ++-
# + test/socket/test_socket.rb |  2 +-
# + 4 files changed, 26 insertions(+), 2 deletions(-)
# +
# +diff --git a/ext/socket/option.c b/ext/socket/option.c
# +index 5ad44cd..87ddbc9 100644
# +--- a/ext/socket/option.c
# ++++ b/ext/socket/option.c
# +@@ -10,6 +10,7 @@ VALUE rb_cSockOpt;
# + #if defined(__linux__) || \
# +     defined(__GNU__) /* GNU/Hurd */ || \
# +     defined(__FreeBSD__) || \
# ++    defined(__FreeBSD_kernel__) || \
# +     defined(__DragonFly__) || \
# +     defined(__APPLE__) || \
# +     defined(_WIN32) || \
# +diff --git a/ext/socket/raddrinfo.c b/ext/socket/raddrinfo.c
# +index 9ec2fdc..2e3eeb5 100644
# +--- a/ext/socket/raddrinfo.c
# ++++ b/ext/socket/raddrinfo.c
# +@@ -1788,10 +1788,21 @@ addrinfo_mload(VALUE self, VALUE ary)
# +         INIT_SOCKADDR_UN(&uaddr, sizeof(struct sockaddr_un));
# +
# +         StringValue(v);
# ++#ifdef __FreeBSD_kernel__
# ++       /* sys/un.h defines struct sockaddr_un as:
# ++          char sun_path[104];
# ++          char __sun_user_compat[4];
# ++       */
# ++        if (sizeof(uaddr.sun_path) + 4 < (size_t)RSTRING_LEN(v))
# ++            rb_raise(rb_eSocket,
# ++                "too long AF_UNIX path (%"PRIuSIZE" bytes given but %"PRIuSIZE" bytes max)",
# ++                (size_t)RSTRING_LEN(v), sizeof(uaddr.sun_path) + 4);
# ++#else
# +         if (sizeof(uaddr.sun_path) < (size_t)RSTRING_LEN(v))
# +             rb_raise(rb_eSocket,
# +                 "too long AF_UNIX path (%"PRIuSIZE" bytes given but %"PRIuSIZE" bytes max)",
# +                 (size_t)RSTRING_LEN(v), sizeof(uaddr.sun_path));
# ++#endif
# +         memcpy(uaddr.sun_path, RSTRING_PTR(v), RSTRING_LEN(v));
# +         len = (socklen_t)sizeof(uaddr);
# +         memcpy(&ss, &uaddr, len);
# +@@ -2435,10 +2446,21 @@ addrinfo_unix_path(VALUE self)
# +     if (n < 0)
# +         rb_raise(rb_eSocket, "too short AF_UNIX address: %"PRIuSIZE" bytes given for minimum %"PRIuSIZE" bytes.",
# +                  (size_t)rai->sockaddr_len, offsetof(struct sockaddr_un, sun_path));
# ++#ifdef __FreeBSD_kernel__
# ++       /* sys/un.h defines struct sockaddr_un as:
# ++          char sun_path[104];
# ++          char __sun_user_compat[4];
# ++       */
# ++    if ((long)sizeof(addr->sun_path) + 4 < n)
# ++        rb_raise(rb_eSocket,
# ++            "too long AF_UNIX path (%"PRIuSIZE" bytes given but %"PRIuSIZE" bytes max)",
# ++            (size_t)n, sizeof(addr->sun_path) + 4);
# ++#else
# +     if ((long)sizeof(addr->sun_path) < n)
# +         rb_raise(rb_eSocket,
# +             "too long AF_UNIX path (%"PRIuSIZE" bytes given but %"PRIuSIZE" bytes max)",
# +             (size_t)n, sizeof(addr->sun_path));
# ++#endif
# +     return rb_str_new(addr->sun_path, n);
# + }
# + #endif
# +diff --git a/test/fiddle/test_handle.rb b/test/fiddle/test_handle.rb
# +index 17f9c92..2862585 100644
# +--- a/test/fiddle/test_handle.rb
# ++++ b/test/fiddle/test_handle.rb
# +@@ -150,6 +150,7 @@ module Fiddle
# +     end unless /mswin|mingw/ =~ RUBY_PLATFORM
# +
# +     def test_dlerror
# ++      return if /kfreebsd/ =~ RUBY_PLATFORM
# +       # FreeBSD (at least 7.2 to 7.2) calls nsdispatch(3) when it calls
# +       # getaddrinfo(3). And nsdispatch(3) doesn't call dlerror(3) even if
# +       # it calls _nss_cache_cycle_prevention_function with dlsym(3).
# +@@ -158,7 +159,7 @@ module Fiddle
# +       require 'socket'
# +       Socket.gethostbyname("localhost")
# +       Fiddle.dlopen("/lib/libc.so.7").sym('strcpy')
# +-    end if /freebsd/=~ RUBY_PLATFORM
# ++    end if /freebsd/ =~ RUBY_PLATFORM
# +
# +     def test_no_memory_leak
# +       assert_no_memory_leak(%w[-W0 -rfiddle.so], '', '100_000.times {Fiddle::Handle.allocate}; GC.start', rss: true)
# +diff --git a/test/socket/test_socket.rb b/test/socket/test_socket.rb
# +index f1ec927..4d22a3c 100644
# +--- a/test/socket/test_socket.rb
# ++++ b/test/socket/test_socket.rb
# +@@ -530,7 +530,7 @@ class TestSocket < Test::Unit::TestCase
# +   end
# +
# +   def test_bintime
# +-    return if /freebsd/ !~ RUBY_PLATFORM
# ++    return if /freebsd/ !~ RUBY_PLATFORM || /kfreebsd/ =~ RUBY_PLATFORM
# +     t1 = Time.now.strftime("%Y-%m-%d")
# +     stamp = nil
# +     Addrinfo.udp("127.0.0.1", 0).bind {|s1|
# diff -Nru debian~/patches/0008-Fix-priority-order-of-paths-in-I-option.patch debian/patches/0008-Fix-priority-order-of-paths-in-I-option.patch
# --- debian~/patches/0008-Fix-priority-order-of-paths-in-I-option.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0008-Fix-priority-order-of-paths-in-I-option.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,43 @@
# +From: =?utf-8?q?C=C3=A9dric_Boutillier?= <boutil@debian.org>
# +Date: Tue, 4 Feb 2020 18:55:42 +0100
# +Subject: Fix priority order of paths in -I option
# +
# +Origin: https://github.com/rubygems/rubygems/pull/3124
# +Author: deivid <deivid.rodriguez@riseup.net>
# +---
# + lib/rubygems/core_ext/kernel_require.rb | 20 ++++++++++----------
# + 1 file changed, 10 insertions(+), 10 deletions(-)
# +
# +diff --git a/lib/rubygems/core_ext/kernel_require.rb b/lib/rubygems/core_ext/kernel_require.rb
# +index 60f4d18..3828338 100644
# +--- a/lib/rubygems/core_ext/kernel_require.rb
# ++++ b/lib/rubygems/core_ext/kernel_require.rb
# +@@ -43,18 +43,18 @@ module Kernel
# +     # https://github.com/rubygems/rubygems/pull/1868
# +     resolved_path = begin
# +       rp = nil
# +-      $LOAD_PATH[0...Gem.load_path_insert_index || -1].each do |lp|
# +-        safe_lp = lp.dup.tap(&Gem::UNTAINT)
# +-        begin
# +-          if File.symlink? safe_lp # for backward compatibility
# +-            next
# ++      Gem.suffixes.each do |s|
# ++        $LOAD_PATH[0...Gem.load_path_insert_index || -1].each do |lp|
# ++          safe_lp = lp.dup.tap(&Gem::UNTAINT)
# ++          begin
# ++            if File.symlink? safe_lp # for backward compatibility
# ++              next
# ++            end
# ++          rescue SecurityError
# ++            RUBYGEMS_ACTIVATION_MONITOR.exit
# ++            raise
# +           end
# +-        rescue SecurityError
# +-          RUBYGEMS_ACTIVATION_MONITOR.exit
# +-          raise
# +-        end
# +
# +-        Gem.suffixes.each do |s|
# +           full_path = File.expand_path(File.join(safe_lp, "#{path}#{s}"))
# +           if File.file?(full_path)
# +             rp = full_path
# diff -Nru debian~/patches/0009-Fix-FTBFS-on-x32-misdetected-as-i386-or-amd64.patch debian/patches/0009-Fix-FTBFS-on-x32-misdetected-as-i386-or-amd64.patch
# --- debian~/patches/0009-Fix-FTBFS-on-x32-misdetected-as-i386-or-amd64.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0009-Fix-FTBFS-on-x32-misdetected-as-i386-or-amd64.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,24 @@
# +From: Lucas Kanashiro <kanashiro@debian.org>
# +Date: Mon, 13 Apr 2020 14:40:16 -0300
# +Subject: Fix FTBFS on x32: misdetected as i386 or amd64
# +
# +Author: Thorsten Glaser <t.glaser@tarent.de>
# +Bug: #954293
# +---
# + configure.ac | 3 +++
# + 1 file changed, 3 insertions(+)
# +
# +diff --git a/configure.ac b/configure.ac
# +index 6766df2..429c35b 100644
# +--- a/configure.ac
# ++++ b/configure.ac
# +@@ -2312,6 +2312,9 @@ AS_CASE([$rb_cv_coroutine], [yes|''], [
# +         [arm64-darwin*], [
# +             rb_cv_coroutine=arm64
# +         ],
# ++        [x86_64-linux-gnux32], [
# ++            rb_cv_coroutine=ucontext
# ++        ],
# +         [x*64-linux*], [
# +             AS_CASE(["$ac_cv_sizeof_voidp"],
# +                 [8], [ rb_cv_coroutine=amd64 ],
# diff -Nru debian~/patches/0010-Fix-IRBTestIRBHistory-tests.patch debian/patches/0010-Fix-IRBTestIRBHistory-tests.patch
# --- debian~/patches/0010-Fix-IRBTestIRBHistory-tests.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0010-Fix-IRBTestIRBHistory-tests.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,237 @@
# +From: aycabta <aycabta@gmail.com>
# +Date: Mon, 5 Oct 2020 18:57:47 +0900
# +Subject: [PATCH] Remove system method for E2E testing because depends on ruby
# + command
# +
# +---
# + test/irb/test_history.rb | 146 +++++++++++++++++++++++++++--------------------
# + 1 file changed, 83 insertions(+), 63 deletions(-)
# +
# +diff --git a/test/irb/test_history.rb b/test/irb/test_history.rb
# +index 3591f88..392a6af 100644
# +--- a/test/irb/test_history.rb
# ++++ b/test/irb/test_history.rb
# +@@ -1,6 +1,7 @@
# + # frozen_string_literal: false
# + require 'test/unit'
# + require 'irb'
# ++require 'irb/ext/save-history'
# + require 'readline'
# +
# + module TestIRB
# +@@ -13,133 +14,152 @@ module TestIRB
# +       IRB.conf[:RC_NAME_GENERATOR] = nil
# +     end
# +
# ++    class TestInputMethod < ::IRB::InputMethod
# ++      HISTORY = Array.new
# ++
# ++      include IRB::HistorySavingAbility
# ++
# ++      attr_reader :list, :line_no
# ++
# ++      def initialize(list = [])
# ++        super("test")
# ++        @line_no = 0
# ++        @list = list
# ++      end
# ++
# ++      def gets
# ++        @list[@line_no]&.tap {@line_no += 1}
# ++      end
# ++
# ++      def eof?
# ++        @line_no >= @list.size
# ++      end
# ++
# ++      def encoding
# ++        Encoding.default_external
# ++      end
# ++
# ++      def reset
# ++        @line_no = 0
# ++      end
# ++
# ++      def winsize
# ++        [10, 20]
# ++      end
# ++    end
# ++
# +     def test_history_save_1
# +       omit "Skip Editline" if /EditLine/n.match(Readline::VERSION)
# +-      _result_output, result_history_file = launch_irb_with_irbrc_and_irb_history(<<~IRBRC, <<~IRB_HISTORY) do |stdin|
# +-        IRB.conf[:USE_READLINE] = true
# +-        IRB.conf[:SAVE_HISTORY] = 1
# +-        IRB.conf[:USE_READLINE] = true
# +-      IRBRC
# ++      IRB.conf[:SAVE_HISTORY] = 1
# ++      assert_history(<<~EXPECTED_HISTORY, <<~INITIAL_HISTORY, <<~INPUT)
# ++        exit
# ++      EXPECTED_HISTORY
# +         1
# +         2
# +         3
# +         4
# +-      IRB_HISTORY
# +-        stdin.write("5\nexit\n")
# +-      end
# +-
# +-      assert_equal(<<~HISTORY_FILE, result_history_file)
# ++      INITIAL_HISTORY
# ++        5
# +         exit
# +-      HISTORY_FILE
# ++      INPUT
# +     end
# +
# +     def test_history_save_100
# +       omit "Skip Editline" if /EditLine/n.match(Readline::VERSION)
# +-      _result_output, result_history_file = launch_irb_with_irbrc_and_irb_history(<<~IRBRC, <<~IRB_HISTORY) do |stdin|
# +-        IRB.conf[:USE_READLINE] = true
# +-        IRB.conf[:SAVE_HISTORY] = 100
# +-        IRB.conf[:USE_READLINE] = true
# +-      IRBRC
# ++      IRB.conf[:SAVE_HISTORY] = 100
# ++      assert_history(<<~EXPECTED_HISTORY, <<~INITIAL_HISTORY, <<~INPUT)
# +         1
# +         2
# +         3
# +         4
# +-      IRB_HISTORY
# +-        stdin.write("5\nexit\n")
# +-      end
# +-
# +-      assert_equal(<<~HISTORY_FILE, result_history_file)
# ++        5
# ++        exit
# ++      EXPECTED_HISTORY
# +         1
# +         2
# +         3
# +         4
# ++      INITIAL_HISTORY
# +         5
# +         exit
# +-      HISTORY_FILE
# ++      INPUT
# +     end
# +
# +     def test_history_save_bignum
# +       omit "Skip Editline" if /EditLine/n.match(Readline::VERSION)
# +-      _result_output, result_history_file = launch_irb_with_irbrc_and_irb_history(<<~IRBRC, <<~IRB_HISTORY) do |stdin|
# +-        IRB.conf[:USE_READLINE] = true
# +-        IRB.conf[:SAVE_HISTORY] = 10 ** 19
# +-        IRB.conf[:USE_READLINE] = true
# +-      IRBRC
# ++      IRB.conf[:SAVE_HISTORY] = 10 ** 19
# ++      assert_history(<<~EXPECTED_HISTORY, <<~INITIAL_HISTORY, <<~INPUT)
# +         1
# +         2
# +         3
# +         4
# +-      IRB_HISTORY
# +-        stdin.write("5\nexit\n")
# +-      end
# +-
# +-      assert_equal(<<~HISTORY_FILE, result_history_file)
# ++        5
# ++        exit
# ++      EXPECTED_HISTORY
# +         1
# +         2
# +         3
# +         4
# ++      INITIAL_HISTORY
# +         5
# +         exit
# +-      HISTORY_FILE
# ++      INPUT
# +     end
# +
# +     def test_history_save_minus_as_infinity
# +       omit "Skip Editline" if /EditLine/n.match(Readline::VERSION)
# +-      _result_output, result_history_file = launch_irb_with_irbrc_and_irb_history(<<~IRBRC, <<~IRB_HISTORY) do |stdin|
# +-        IRB.conf[:USE_READLINE] = true
# +-        IRB.conf[:SAVE_HISTORY] = -1 # infinity
# +-        IRB.conf[:USE_READLINE] = true
# +-      IRBRC
# ++      IRB.conf[:SAVE_HISTORY] = -1 # infinity
# ++      assert_history(<<~EXPECTED_HISTORY, <<~INITIAL_HISTORY, <<~INPUT)
# +         1
# +         2
# +         3
# +         4
# +-      IRB_HISTORY
# +-        stdin.write("5\nexit\n")
# +-      end
# +-
# +-      assert_equal(<<~HISTORY_FILE, result_history_file)
# ++        5
# ++        exit
# ++      EXPECTED_HISTORY
# +         1
# +         2
# +         3
# +         4
# ++      INITIAL_HISTORY
# +         5
# +         exit
# +-      HISTORY_FILE
# ++      INPUT
# +     end
# +
# +     private
# +
# +-    def launch_irb_with_irbrc_and_irb_history(irbrc, irb_history)
# +-      result = nil
# +-      result_history = nil
# +-      backup_irbrc = ENV.delete("IRBRC")
# ++    def assert_history(expected_history, initial_irb_history, input)
# ++      backup_verbose, $VERBOSE = $VERBOSE, nil
# +       backup_home = ENV["HOME"]
# ++      IRB.conf[:LC_MESSAGES] = IRB::Locale.new
# ++      actual_history = nil
# +       Dir.mktmpdir("test_irb_history_#{$$}") do |tmpdir|
# +         ENV["HOME"] = tmpdir
# +-        open(IRB.rc_file, "w") do |f|
# +-          f.write(irbrc)
# +-        end
# +         open(IRB.rc_file("_history"), "w") do |f|
# +-          f.write(irb_history)
# ++          f.write(initial_irb_history)
# +         end
# +
# +-        with_temp_stdio do |stdin, stdout|
# +-          yield(stdin, stdout)
# +-          stdin.close
# +-          stdout.flush
# +-          system('ruby', '-Ilib', '-Itest', '-W0', '-rirb', '-e', 'IRB.start(__FILE__)', in: stdin.path, out: stdout.path)
# +-          result = stdout.read
# +-          stdout.close
# +-        end
# ++        io = TestInputMethod.new
# ++        io.class::HISTORY.clear
# ++        io.load_history
# ++        io.class::HISTORY.concat(input.split)
# ++        io.save_history
# ++
# ++        io.load_history
# +         open(IRB.rc_file("_history"), "r") do |f|
# +-          result_history = f.read
# ++          actual_history = f.read
# +         end
# +       end
# +-      [result, result_history]
# ++      assert_equal(expected_history, actual_history, <<~MESSAGE)
# ++        expected:
# ++        #{expected_history}
# ++        but actual:
# ++        #{actual_history}
# ++      MESSAGE
# +     ensure
# ++      $VERBOSE = backup_verbose
# +       ENV["HOME"] = backup_home
# +-      ENV["IRBRC"] = backup_irbrc
# +     end
# +
# +     def with_temp_stdio
# diff -Nru debian~/patches/0011-Dont-use-relative-path.patch debian/patches/0011-Dont-use-relative-path.patch
# --- debian~/patches/0011-Dont-use-relative-path.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0011-Dont-use-relative-path.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,59 @@
# +From: =?utf-8?q?David_Rodr=C3=ADguez?= <deivid.rodriguez@riseup.net>
# +Date: Tue, 6 Oct 2020 19:11:05 +0200
# +Subject: [PATCH] Make lib/ and test/ more independent from each other
# +
# +---
# + lib/rubygems/test_case.rb                        | 2 --
# + test/rubygems/test_gem_commands_build_command.rb | 2 +-
# + test/rubygems/test_gem_stub_specification.rb     | 8 ++++----
# + 3 files changed, 5 insertions(+), 7 deletions(-)
# +
# +diff --git a/lib/rubygems/test_case.rb b/lib/rubygems/test_case.rb
# +index 8940320..53ba84a 100644
# +--- a/lib/rubygems/test_case.rb
# ++++ b/lib/rubygems/test_case.rb
# +@@ -96,8 +96,6 @@ class Gem::TestCase < (defined?(Minitest::Test) ? Minitest::Test : MiniTest::Uni
# +
# +   TEST_PATH = ENV.fetch('RUBYGEMS_TEST_PATH', File.expand_path('../../../test/rubygems', __FILE__))
# +
# +-  SPECIFICATIONS = File.expand_path(File.join(TEST_PATH, "specifications"), __FILE__)
# +-
# +   def assert_activate(expected, *specs)
# +     specs.each do |spec|
# +       case spec
# +diff --git a/test/rubygems/test_gem_commands_build_command.rb b/test/rubygems/test_gem_commands_build_command.rb
# +index 309e15f..aaca54f 100644
# +--- a/test/rubygems/test_gem_commands_build_command.rb
# ++++ b/test/rubygems/test_gem_commands_build_command.rb
# +@@ -123,7 +123,7 @@ class TestGemCommandsBuildCommand < Gem::TestCase
# +   end
# +
# +   def test_execute_rubyforge_project_warning
# +-    rubyforge_gemspec = File.join SPECIFICATIONS, "rubyforge-0.0.1.gemspec"
# ++    rubyforge_gemspec = File.expand_path File.join("specifications", "rubyforge-0.0.1.gemspec"), __dir__
# +
# +     @cmd.options[:args] = [rubyforge_gemspec]
# +
# +diff --git a/test/rubygems/test_gem_stub_specification.rb b/test/rubygems/test_gem_stub_specification.rb
# +index 91a46d7..2579f8a 100644
# +--- a/test/rubygems/test_gem_stub_specification.rb
# ++++ b/test/rubygems/test_gem_stub_specification.rb
# +@@ -4,14 +4,14 @@ require "rubygems/stub_specification"
# +
# + class TestStubSpecification < Gem::TestCase
# +
# +-  FOO = File.join SPECIFICATIONS, "foo-0.0.1-x86-mswin32.gemspec"
# +-  BAR = File.join SPECIFICATIONS, "bar-0.0.2.gemspec"
# ++  FOO = File.expand_path File.join("specifications", "foo-0.0.1-x86-mswin32.gemspec"), __dir__
# ++  BAR = File.expand_path File.join("specifications", "bar-0.0.2.gemspec"), __dir__
# +
# +   def setup
# +     super
# +
# +-    @base_dir = File.dirname(SPECIFICATIONS)
# +-    @gems_dir = File.join File.dirname(SPECIFICATIONS), 'gem'
# ++    @base_dir = __dir__
# ++    @gems_dir = File.join __dir__, 'gem'
# +     @foo = Gem::StubSpecification.gemspec_stub FOO, @base_dir, @gems_dir
# +   end
# +
# diff -Nru debian~/patches/0012-Fix-getcwd-ENOENT.patch debian/patches/0012-Fix-getcwd-ENOENT.patch
# --- debian~/patches/0012-Fix-getcwd-ENOENT.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0012-Fix-getcwd-ENOENT.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,46 @@
# +From: Antoni Villalonga <antoni@friki.cat>
# +Date: Fri, 28 Aug 2020 02:09:42 +0200
# +Subject: Rescue getcwd ENOENT error
# +MIME-Version: 1.0
# +Content-Type: text/plain; charset="utf-8"
# +Content-Transfer-Encoding: 8bit
# +
# +Forwarded: not-needed
# +Bug-Debian: http://bugs.debian.org/969130
# +Upstream-Author: David Rodríguez
# +
# +Rescue ENOENT error allowing run ruby scripts when cwd does not exists.
# +Cherry-pick from upstream 96064e6f1ce100a37680dc8f9509f06b3350e9c8
# +---
# + lib/rubygems/bundler_version_finder.rb | 17 ++++++++++++-----
# + 1 file changed, 12 insertions(+), 5 deletions(-)
# +
# +diff --git a/lib/rubygems/bundler_version_finder.rb b/lib/rubygems/bundler_version_finder.rb
# +index 38da773..ea6698f 100644
# +--- a/lib/rubygems/bundler_version_finder.rb
# ++++ b/lib/rubygems/bundler_version_finder.rb
# +@@ -82,12 +82,19 @@ To install the missing version, run `gem install bundler:#{vr.first}`
# +   def self.lockfile_contents
# +     gemfile = ENV["BUNDLE_GEMFILE"]
# +     gemfile = nil if gemfile && gemfile.empty?
# +-    Gem::Util.traverse_parents Dir.pwd do |directory|
# +-      next unless gemfile = Gem::GEM_DEP_FILES.find { |f| File.file?(f.tap(&Gem::UNTAINT)) }
# +
# +-      gemfile = File.join directory, gemfile
# +-      break
# +-    end unless gemfile
# ++    unless gemfile
# ++      begin
# ++        Gem::Util.traverse_parents(Dir.pwd) do |directory|
# ++          next unless gemfile = Gem::GEM_DEP_FILES.find { |f| File.file?(f.tap(&Gem::UNTAINT)) }
# ++
# ++          gemfile = File.join directory, gemfile
# ++          break
# ++        end
# ++      rescue Errno::ENOENT
# ++        return
# ++      end
# ++    end
# +
# +     return unless gemfile
# +
# diff -Nru debian~/patches/0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch debian/patches/0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch
# --- debian~/patches/0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,172 @@
# +From: AGSaidi <AGSaidi@users.noreply.github.com>
# +Date: Thu, 13 Aug 2020 12:15:54 -0500
# +Subject: Enable arm64 optimizations that exist for power/x86 (#3393)
# +
# +* Enable unaligned accesses on arm64
# +
# +64-bit Arm platforms support unaligned accesses.
# +
# +Running the string benchmarks this change improves performance
# +by an average of 1.04x, min .96x, max 1.21x, median 1.01x
# +
# +* arm64 enable gc optimizations
# +
# +Similar to x86 and powerpc optimizations.
# +
# +|       |compare-ruby|built-ruby|
# +|:------|-----------:|---------:|
# +|hash1  |       0.225|     0.237|
# +|       |           -|     1.05x|
# +|hash2  |       0.110|     0.110|
# +|       |       1.00x|         -|
# +
# +* vm_exec.c: improve performance for arm64
# +
# +|                               |compare-ruby|built-ruby|
# +|:------------------------------|-----------:|---------:|
# +|vm_array                       |     26.501M|   27.959M|
# +|                               |           -|     1.06x|
# +|vm_attr_ivar                   |     21.606M|   31.429M|
# +|                               |           -|     1.45x|
# +|vm_attr_ivar_set               |     21.178M|   26.113M|
# +|                               |           -|     1.23x|
# +|vm_backtrace                   |       6.621|     6.668|
# +|                               |           -|     1.01x|
# +|vm_bigarray                    |     26.205M|   29.958M|
# +|                               |           -|     1.14x|
# +|vm_bighash                     |    504.155k|  479.306k|
# +|                               |       1.05x|         -|
# +|vm_block                       |     16.692M|   21.315M|
# +|                               |           -|     1.28x|
# +|block_handler_type_iseq        |       5.083|     7.004|
# +|                               |           -|     1.38x|
# +
# +Origin: upstream, https://github.com/ruby/ruby/commit/511b55bcefc81c03
# +Bug-Ubuntu: https://bugs.launchpad.net/ubuntu/+source/ruby2.7/+bug/1901074
# +Reviewed-By: Lucas Kanashiro <kanashiro@debian.org>
# +Last-Updated: 2020-10-30
# +---
# + gc.c                   | 13 +++++++++++++
# + gc.h                   |  2 ++
# + include/ruby/defines.h |  2 +-
# + regint.h               |  2 +-
# + siphash.c              |  2 +-
# + st.c                   |  2 +-
# + vm_exec.c              |  8 ++++++++
# + 7 files changed, 27 insertions(+), 4 deletions(-)
# +
# +diff --git a/gc.c b/gc.c
# +index 73faf46..b06fdc5 100644
# +--- a/gc.c
# ++++ b/gc.c
# +@@ -1153,6 +1153,19 @@ tick(void)
# +     return val;
# + }
# +
# ++#elif defined(__aarch64__) &&  defined(__GNUC__)
# ++typedef unsigned long tick_t;
# ++#define PRItick "lu"
# ++
# ++static __inline__ tick_t
# ++tick(void)
# ++{
# ++    unsigned long val;
# ++    __asm__ __volatile__ ("mrs %0, cntvct_el0", : "=r" (val));
# ++    return val;
# ++}
# ++
# ++
# + #elif defined(_WIN32) && defined(_MSC_VER)
# + #include <intrin.h>
# + typedef unsigned __int64 tick_t;
# +diff --git a/gc.h b/gc.h
# +index cf794fa..72e3935 100644
# +--- a/gc.h
# ++++ b/gc.h
# +@@ -8,6 +8,8 @@
# + #define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("movl\t%%esp, %0" : "=r" (*(p)))
# + #elif defined(__powerpc64__) && defined(__GNUC__)
# + #define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("mr\t%0, %%r1" : "=r" (*(p)))
# ++#elif defined(__aarch64__) && defined(__GNUC__)
# ++#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("mov\t%0, sp" : "=r" (*(p)))
# + #else
# + NOINLINE(void rb_gc_set_stack_end(VALUE **stack_end_p));
# + #define SET_MACHINE_STACK_END(p) rb_gc_set_stack_end(p)
# +diff --git a/include/ruby/defines.h b/include/ruby/defines.h
# +index 5e03d49..e953b05 100644
# +--- a/include/ruby/defines.h
# ++++ b/include/ruby/defines.h
# +@@ -485,7 +485,7 @@ void rb_sparc_flush_register_windows(void);
# + #ifndef UNALIGNED_WORD_ACCESS
# + # if defined(__i386) || defined(__i386__) || defined(_M_IX86) || \
# +      defined(__x86_64) || defined(__x86_64__) || defined(_M_AMD64) || \
# +-     defined(__powerpc64__) || \
# ++     defined(__powerpc64__) || defined(__aarch64__) || \
# +      defined(__mc68020__)
# + #   define UNALIGNED_WORD_ACCESS 1
# + # else
# +diff --git a/regint.h b/regint.h
# +index a2f5bbb..0740429 100644
# +--- a/regint.h
# ++++ b/regint.h
# +@@ -52,7 +52,7 @@
# + #ifndef UNALIGNED_WORD_ACCESS
# + # if defined(__i386) || defined(__i386__) || defined(_M_IX86) || \
# +      defined(__x86_64) || defined(__x86_64__) || defined(_M_AMD64) || \
# +-     defined(__powerpc64__) || \
# ++     defined(__powerpc64__) || defined(__aarch64__) || \
# +      defined(__mc68020__)
# + #  define UNALIGNED_WORD_ACCESS 1
# + # else
# +diff --git a/siphash.c b/siphash.c
# +index 153d2c6..ddf8ee2 100644
# +--- a/siphash.c
# ++++ b/siphash.c
# +@@ -30,7 +30,7 @@
# + #ifndef UNALIGNED_WORD_ACCESS
# + # if defined(__i386) || defined(__i386__) || defined(_M_IX86) || \
# +      defined(__x86_64) || defined(__x86_64__) || defined(_M_AMD64) || \
# +-     defined(__powerpc64__) || \
# ++     defined(__powerpc64__) || defined(__aarch64__) || \
# +      defined(__mc68020__)
# + #   define UNALIGNED_WORD_ACCESS 1
# + # endif
# +diff --git a/st.c b/st.c
# +index 2b973ea..4258f93 100644
# +--- a/st.c
# ++++ b/st.c
# +@@ -1815,7 +1815,7 @@ st_values_check(st_table *tab, st_data_t *values, st_index_t size,
# + #ifndef UNALIGNED_WORD_ACCESS
# + # if defined(__i386) || defined(__i386__) || defined(_M_IX86) || \
# +      defined(__x86_64) || defined(__x86_64__) || defined(_M_AMD64) || \
# +-     defined(__powerpc64__) || \
# ++     defined(__powerpc64__) || defined(__aarch64__) || \
# +      defined(__mc68020__)
# + #   define UNALIGNED_WORD_ACCESS 1
# + # endif
# +diff --git a/vm_exec.c b/vm_exec.c
# +index 0adaa7b..cb09738 100644
# +--- a/vm_exec.c
# ++++ b/vm_exec.c
# +@@ -27,6 +27,9 @@ static void vm_analysis_insn(int insn);
# + #elif defined(__GNUC__) && defined(__powerpc64__)
# + #define DECL_SC_REG(type, r, reg) register type reg_##r __asm__("r" reg)
# +
# ++#elif defined(__GNUC__) && defined(__aarch64__)
# ++#define DECL_SC_REG(type, r, reg) register type reg_##r __asm__("x" reg)
# ++
# + #else
# + #define DECL_SC_REG(type, r, reg) register type reg_##r
# + #endif
# +@@ -74,6 +77,11 @@ vm_exec_core(rb_execution_context_t *ec, VALUE initial)
# +     DECL_SC_REG(rb_control_frame_t *, cfp, "15");
# + #define USE_MACHINE_REGS 1
# +
# ++#elif defined(__GNUC__) && defined(__aarch64__)
# ++    DECL_SC_REG(const VALUE *, pc, "19");
# ++    DECL_SC_REG(rb_control_frame_t *, cfp, "20");
# ++#define USE_MACHINE_REGS 1
# ++
# + #else
# +     register rb_control_frame_t *reg_cfp;
# +     const VALUE *reg_pc;
# diff -Nru debian~/patches/series debian/patches/series
# --- debian~/patches/series	1969-12-31 19:00:00.000000000 -0500
# +++ debian/patches/series	2021-01-25 23:43:14.982605931 -0500
# @@ -0,0 +1,12 @@
# +0001-rdoc-build-reproducible-documentation.patch
# +0002-lib-mkmf.rb-sort-list-of-object-files-in-generated-M.patch
# +0003-Mark-Gemspec-reproducible-change-fixing-784225-too.patch
# +0004-Disable-tests-failing-on-Ubuntu-builders.patch
# +0005-Make-gemspecs-reproducible.patch
# +0006-Fix-FTBS-on-hurd.patch
# +0007-Port-to-kfreebsd-amd64.patch
# +0008-Fix-priority-order-of-paths-in-I-option.patch
# +0009-Fix-FTBFS-on-x32-misdetected-as-i386-or-amd64.patch
# +0011-Dont-use-relative-path.patch
# +0012-Fix-getcwd-ENOENT.patch
# +0013-Enable-arm64-optimizations-that-exist-for-power-x86-.patch
# diff -Nru debian~/quick-build.sh debian/quick-build.sh
# --- debian~/quick-build.sh	1969-12-31 19:00:00.000000000 -0500
# +++ debian/quick-build.sh	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1 @@
# +DEB_BUILD_OPTIONS="parallel=$(nproc) nocheck" git buildpackage -us -uc -B "$@"
# diff -Nru debian~/README.porting debian/README.porting
# --- debian~/README.porting	1969-12-31 19:00:00.000000000 -0500
# +++ debian/README.porting	2021-01-25 23:37:04.794005674 -0500
# @@ -0,0 +1,15 @@
# +Porting Notes
# +=============
# +
# +Ruby 1.9 and newer need a working Ruby interpreter to configure/build
# +(see debian/rules calling ./configure with --with-baseruby).
# +Ruby 1.8 does NOT need Ruby to build, just gcc-4.6.
# +
# +This packages will build against ruby1.8 if available (and there is not a
# +actually supported Ruby installed), so you need a ruby1.8 package. If needed,
# +build one from archive.debian.org.
# +
# +Good luck!
# +
# +  -- Christian Hofstaedtler <zeha@debian.org>  Tue, 14 Jan 2014 20:03:27 +0100
# +  -- Antonio Terceiro <terceiro@debian.org>  Thu, 15 May 2014 22:33:17 -0300
# diff -Nru debian~/README.source debian/README.source
# --- debian~/README.source	1969-12-31 19:00:00.000000000 -0500
# +++ debian/README.source	2021-01-25 23:37:04.794005674 -0500
# @@ -0,0 +1,10 @@
# +Additional sources
# +==================
# +
# +Source for lib/rdoc/generator/template/darkfish/js/jquery.js (which is minified
# +and thus cannot be properly modified as is) is available at
# +debian/missing-sources/jquery.js.
# +
# +When libruby* is installed, however,
# +/usr/lib/ruby/*/rdoc/generator/template/darkfish/js/jquery.js is a symlink
# +to jquery.js provided by the libjs-jquery package.
# diff -Nru debian~/ruby2.7-dev.install debian/ruby2.7-dev.install
# --- debian~/ruby2.7-dev.install	1969-12-31 19:00:00.000000000 -0500
# +++ debian/ruby2.7-dev.install	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,3 @@
# +/usr/include
# +/usr/lib/*/*.so
# +/usr/lib/*/pkgconfig
# diff -Nru debian~/ruby2.7.install debian/ruby2.7.install
# --- debian~/ruby2.7.install	1969-12-31 19:00:00.000000000 -0500
# +++ debian/ruby2.7.install	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,3 @@
# +/usr/bin
# +/usr/share/man
# +/var/lib/gems
# diff -Nru debian~/ruby2.7.manpages debian/ruby2.7.manpages
# --- debian~/ruby2.7.manpages	1969-12-31 19:00:00.000000000 -0500
# +++ debian/ruby2.7.manpages	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,2 @@
# +debian/manpages/gem2.7.1
# +debian/manpages/rdoc2.7.1
# diff -Nru debian~/rules debian/rules
# --- debian~/rules	1969-12-31 19:00:00.000000000 -0500
# +++ debian/rules	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,159 @@
# +#!/usr/bin/make -f
# +# -*- makefile -*-
# +
# +export DH_VERBOSE=1
# +
# +export DEBIAN_DISABLE_RUBYGEMS_INTEGRATION = 1
# +
# +# This has to be exported to make some magic below work.
# +export DH_OPTIONS
# +TESTOPTS += -v
# +export TESTOPTS
# +
# +DEB_BUILD_OPTIONS = nocheck
# +DEB_BUILD_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_TYPE)
# +DEB_HOST_ARCH ?= $(shell dpkg-architecture -qDEB_HOST_ARCH)
# +DEB_HOST_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)
# +DEB_HOST_MULTIARCH ?= $(shell dpkg-architecture -qDEB_HOST_MULTIARCH)
# +
# +include /usr/share/dpkg/pkg-info.mk
# +
# +export RUBY_VERSION       := $(patsubst ruby%,%,$(DEB_SOURCE))
# +export RUBY_API_VERSION   := $(RUBY_VERSION).0
# +
# +configure_options += --prefix=/usr
# +configure_options += --enable-multiarch
# +configure_options += --target=$(DEB_HOST_MULTIARCH)
# +configure_options += --program-suffix=$(RUBY_VERSION)
# +configure_options += --with-soname=ruby-$(RUBY_VERSION)
# +configure_options += --enable-shared
# +configure_options += --disable-rpath
# +configure_options += --with-sitedir='/usr/local/lib/site_ruby'
# +configure_options += --with-sitearchdir="/usr/local/lib/$(DEB_HOST_MULTIARCH)/site_ruby"
# +configure_options += --runstatedir=/var/run
# +configure_options += --localstatedir=/var
# +configure_options += --sysconfdir=/etc
# +
# +# These are embedded in rbconfig.rb and should be triplet-prefixed for
# +# cross compilation.
# +configure_options += AS=$(DEB_HOST_GNU_TYPE)-as
# +configure_options += CC=$(DEB_HOST_GNU_TYPE)-gcc
# +configure_options += CXX=$(DEB_HOST_GNU_TYPE)-g++
# +configure_options += LD=$(DEB_HOST_GNU_TYPE)-ld
# +
# +ifneq ($(DEB_BUILD_GNU_TYPE), $(DEB_HOST_GNU_TYPE))
# +# Cross-building. This is the same logic that debhelper's
# +# lib/Debian/Debhelper/Buildsystem/autoconf.pm uses.
# +# note that you also need --with-baseruby, so use the "cross" build-profile.
# +configure_options += --build=$(DEB_BUILD_GNU_TYPE)
# +configure_options += --host=$(DEB_HOST_GNU_TYPE)
# +endif
# +ifneq ($(filter cross,$(DEB_BUILD_PROFILES)),)
# +configure_options += --with-baseruby=/usr/bin/ruby
# +endif
# +
# +# the following are ignored by ./configure, but used by some extconf.rb scripts
# +configure_options += --enable-ipv6
# +configure_options += --with-dbm-type=gdbm_compat
# +
# +# do not compress debug sections for arch-dep Ruby packages with dh_compat 12
# +configure_options += --with-compress-debug-sections=no
# +
# +# hardening and other standard Debian build flags
# +export DEB_BUILD_MAINT_OPTIONS = hardening=+bindnow
# +configure_options += $(shell dpkg-buildflags --export=configure)
# +
# +# See: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=93808
# +ifneq (,$(filter $(DEB_HOST_ARCH),sh3 sh4))
# +export DEB_CFLAGS_MAINT_APPEND += -fno-crossjumping
# +endif
# +
# +# Always build with /bin/bash, to get consistent rbconfig.rb (which embeds SHELL).
# +export SHELL := /bin/bash
# +
# +# Some tests rely on $HOME
# +export HOME := $(shell mktemp -d)
# +export LANG := C.UTF-8
# +
# +%:
# +	dh $@
# +
# +override_dh_auto_configure:
# +	cp /usr/share/misc/config.guess tool
# +	cp /usr/share/misc/config.sub tool
# +ifeq (riscv64,$(DEB_HOST_ARCH))
# +	LIBS="-latomic" ./configure $(configure_options)
# +else
# +	./configure $(configure_options)
# +endif
# +
# +override_dh_auto_clean:
# +	$(MAKE) clean || true
# +	$(MAKE) distclean-ext || true
# +	rm -f tool/config.guess tool/config.sub
# +	$(RM) test/excludes/$(DEB_HOST_ARCH)
# +	$(RM) -r .ext
# +	$(RM) -r doc/capi
# +	$(RM) .installed.list GNUmakefile Makefile builtin_binary.inc \
# +		config.status enc.mk uncommon.mk verconf.h
# +
# +override_dh_auto_build-arch:
# +	dh_auto_build -- main V=1
# +
# +# see full list in common.mk (search for /^check:/)
# +TEST_TARGETS := test test-tool test-all # missing test-spec
# +
# +excludes =
# +excludes += --excludes-dir=debian/tests/excludes/any/
# +excludes += --excludes-dir=debian/tests/excludes/$(DEB_HOST_ARCH)/
# +ifneq (,$(DEBIAN_RUBY_EXTRA_TEST_EXCLUDES))
# +	excludes += --excludes-dir=debian/tests/excludes/$(DEBIAN_RUBY_EXTRA_TEST_EXCLUDES)/
# +endif
# +override_dh_auto_test-arch:
# +ifeq (,$(filter nocheck,$(DEB_BUILD_OPTIONS)))
# +	$(MAKE) $(TEST_TARGETS) V=1 RUBY_TESTOPTS=-v TESTS="$(excludes)" OPENSSL_CONF=$(CURDIR)/debian/openssl.cnf
# +endif
# +
# +override_dh_auto_install-arch:
# +	$(MAKE) install-nodoc V=1 DESTDIR=$(CURDIR)/debian/tmp
# +	# handle embedded copy of jquery
# +	$(RM) $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/js/jquery.js
# +	dh_link -plibruby$(RUBY_VERSION) /usr/share/javascript/jquery/jquery.min.js /usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/js/jquery.js
# +	# handle embedded copy of Lato (font)
# +	$(RM) $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-Regular.ttf
# +	dh_link -plibruby$(RUBY_VERSION) /usr/share/fonts/truetype/lato/Lato-Regular.ttf /usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-Regular.ttf
# +	$(RM) $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-RegularItalic.ttf
# +	dh_link -plibruby$(RUBY_VERSION) /usr/share/fonts/truetype/lato/Lato-Italic.ttf /usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-RegularItalic.ttf
# +	$(RM) $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-Light.ttf
# +	dh_link -plibruby$(RUBY_VERSION) /usr/share/fonts/truetype/lato/Lato-Light.ttf /usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-Light.ttf
# +	$(RM) $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-LightItalic.ttf
# +	dh_link -plibruby$(RUBY_VERSION) /usr/share/fonts/truetype/lato/Lato-LightItalic.ttf /usr/lib/ruby/$(RUBY_API_VERSION)/rdoc/generator/template/darkfish/fonts/Lato-LightItalic.ttf
# +	# remove embedded SSL certificates (replaced using ca-certificates via rubygems-integration)
# +	$(RM) -r $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/rubygems/ssl_certs/*
# +	$(RM) -r $(CURDIR)/debian/tmp/usr/lib/ruby/$(RUBY_API_VERSION)/bundler/ssl_certs/*
# +	# ship rubygems system install directory
# +	mkdir -p $(CURDIR)/debian/tmp/var/lib/gems/$(RUBY_API_VERSION)
# +	# fix pkg-config
# +	# FIXME there is probably less brutal way of doing this
# +	sed -i -e 's/^DLDFLAGS=.*/DLDFLAGS=/' \
# +		$(CURDIR)/debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/ruby-$(RUBY_VERSION).pc
# +	# sanity check
# +	debian/sanity_check
# +
# +override_dh_auto_build-indep:
# +	$(MAKE) docs V=1
# +
# +override_dh_auto_install-indep:
# +	$(MAKE) install-doc V=1 DESTDIR=$(CURDIR)/debian/ruby$(RUBY_VERSION)-doc
# +	find $(CURDIR)/debian/ruby$(RUBY_VERSION)-doc -name created.rid -delete
# +
# +override_dh_install-arch:
# +	# install SystemTap tapfile
# +	mkdir -p $(CURDIR)/debian/tmp/usr/share/systemtap/tapset
# +	sed 's|@LIBRARY_PATH@|/usr/lib/$(DEB_HOST_MULTIARCH)/libruby-$(RUBY_VERSION).so|g' $(CURDIR)/debian/libruby.stp > $(CURDIR)/debian/tmp/usr/share/systemtap/tapset/libruby$(RUBY_VERSION)-$(DEB_HOST_MULTIARCH).stp
# +	dh_install
# +
# +override_dh_gencontrol:
# +	./debian/genprovides $(CURDIR)/debian/libruby2.7/usr/lib/ruby/gems/2.7.0/specifications/default/ \
# +		>> debian/libruby2.7.substvars
# +	dh_gencontrol
# diff -Nru debian~/salsa-ci.yml debian/salsa-ci.yml
# --- debian~/salsa-ci.yml	1969-12-31 19:00:00.000000000 -0500
# +++ debian/salsa-ci.yml	2021-01-25 23:37:04.810005355 -0500
# @@ -0,0 +1,7 @@
# +---
# +include:
# +  - https://salsa.debian.org/salsa-ci-team/pipeline/raw/master/salsa-ci.yml
# +  - https://salsa.debian.org/salsa-ci-team/pipeline/raw/master/pipeline-jobs.yml
# +
# +variables:
# +  DEBIAN_RUBY_EXTRA_TEST_EXCLUDES: salsa
# diff -Nru debian~/sanity_check debian/sanity_check
# --- debian~/sanity_check	1969-12-31 19:00:00.000000000 -0500
# +++ debian/sanity_check	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,17 @@
# +#!/bin/sh
# +
# +set -eu
# +
# +# test multi-arch support
# +arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
# +libdir=usr/lib
# +archlibdir=usr/lib/${arch}
# +
# +# files that should NOT exist
# +test '!' -f  debian/tmp/${libdir}/libruby-${RUBY_VERSION}.so.${RUBY_VERSION}
# +test '!' -f  debian/tmp/${libdir}/pkgconfig/ruby-${RUBY_VERSION}.pc
# +
# +# files that should exist
# +ls -1 debian/tmp/${archlibdir}/libruby-${RUBY_VERSION}.so.${RUBY_VERSION}
# +ls -1 debian/tmp/${archlibdir}/pkgconfig/ruby-${RUBY_VERSION}.pc
# +ls -1 debian/tmp/${libdir}/ruby/gems/${RUBY_API_VERSION}/specifications/default/json-*.gemspec
# diff -Nru debian~/source/format debian/source/format
# --- debian~/source/format	1969-12-31 19:00:00.000000000 -0500
# +++ debian/source/format	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +3.0 (quilt)
# diff -Nru debian~/tests/builtin-extensions debian/tests/builtin-extensions
# --- debian~/tests/builtin-extensions	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/builtin-extensions	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,22 @@
# +#!/bin/sh
# +
# +set -e
# +
# +extensions='
# +dbm
# +fiddle
# +gdbm
# +openssl
# +psych
# +sdbm
# +zlib
# +'
# +
# +rc=0
# +for ext in $extensions; do
# +  if ! ruby2.7 -r"$ext" -e "puts 'Extension $ext: OK'"; then
# +    rc=1
# +  fi
# +done
# +
# +exit "$rc"
# diff -Nru debian~/tests/bundled-gems debian/tests/bundled-gems
# --- debian~/tests/bundled-gems	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/bundled-gems	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,20 @@
# +#!/bin/sh
# +
# +set -e
# +
# +rc=0
# +while read gem version repository; do
# +  if ruby2.7 -e "gem '${gem}'" 2>/dev/null; then
# +    if ruby2.7 -e "gem '${gem}', '>= ${version}'" 2>/dev/null; then
# +      echo "I: ${gem} (>= ${version}) OK"
# +    else
# +      found=$(ruby2.7 -S gem list --exact "${gem}" | grep "^${gem}\s")
# +      echo "W: ${found} found, but not new enough (expected >= ${version})."
# +    fi
# +  else
# +    echo "E: ${gem} not found"
# +    rc=1
# +  fi
# +done < gems/bundled_gems
# +
# +exit $rc
# diff -Nru debian~/tests/control debian/tests/control
# --- debian~/tests/control	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/control	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,3 @@
# +Tests: run-all bundled-gems builtin-extensions rubyconfig
# +Depends: @
# +Restrictions: allow-stderr
# diff -Nru debian~/tests/excludes/any/Rinda/TestRingFinger.rb debian/tests/excludes/any/Rinda/TestRingFinger.rb
# --- debian~/tests/excludes/any/Rinda/TestRingFinger.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/Rinda/TestRingFinger.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,3 @@
# +reason = "Network access not allowed during build in Debian"
# +exclude :test_make_socket_ipv4_multicast, reason
# +exclude :test_make_socket_ipv4_multicast_hops, reason
# diff -Nru debian~/tests/excludes/any/Rinda/TestRingServer.rb debian/tests/excludes/any/Rinda/TestRingServer.rb
# --- debian~/tests/excludes/any/Rinda/TestRingServer.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/Rinda/TestRingServer.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,3 @@
# +reason = "Network access not allowed during build in Debian"
# +exclude :test_make_socket_ipv4_multicast, reason
# +exclude :test_ring_server_ipv4_multicast, reason
# diff -Nru debian~/tests/excludes/any/TestArray.rb debian/tests/excludes/any/TestArray.rb
# --- debian~/tests/excludes/any/TestArray.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestArray.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_permutation_stack_error, "too expensive, will timeout on some Debian architectures"
# diff -Nru debian~/tests/excludes/any/TestBeginEndBlock.rb debian/tests/excludes/any/TestBeginEndBlock.rb
# --- debian~/tests/excludes/any/TestBeginEndBlock.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestBeginEndBlock.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_propagate_signaled, "FIXME: investigate failure"
# diff -Nru debian~/tests/excludes/any/TestDir.rb debian/tests/excludes/any/TestDir.rb
# --- debian~/tests/excludes/any/TestDir.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestDir.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_home, "fails under sbuild"
# diff -Nru debian~/tests/excludes/any/TestFileExhaustive.rb debian/tests/excludes/any/TestFileExhaustive.rb
# --- debian~/tests/excludes/any/TestFileExhaustive.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestFileExhaustive.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_expand_path_for_existent_username, "fails under sbuild"
# diff -Nru debian~/tests/excludes/any/TestFile.rb debian/tests/excludes/any/TestFile.rb
# --- debian~/tests/excludes/any/TestFile.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestFile.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_open_tempfile_path, "fails under sbuild"
# diff -Nru debian~/tests/excludes/any/TestGc.rb debian/tests/excludes/any/TestGc.rb
# --- debian~/tests/excludes/any/TestGc.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestGc.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_gc_parameter, "too expensive, timesout on some Debian architectures"
# diff -Nru debian~/tests/excludes/any/TestGemExtExtConfBuilder.rb debian/tests/excludes/any/TestGemExtExtConfBuilder.rb
# --- debian~/tests/excludes/any/TestGemExtExtConfBuilder.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestGemExtExtConfBuilder.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_class_build, "tries to skip ~ in version string"
# +exclude :test_class_build_extconf_fail, "tries to skip ~ in version string"
# diff -Nru debian~/tests/excludes/any/TestGemExtRakeBuilder.rb debian/tests/excludes/any/TestGemExtRakeBuilder.rb
# --- debian~/tests/excludes/any/TestGemExtRakeBuilder.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestGemExtRakeBuilder.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1,3 @@
# +exclude :test_class_build_no_mkrf_passes_args,  "tries to skip ~ in version string"
# +exclude :test_class_build,  "tries to skip ~ in version string"
# +exclude :test_class_build_with_args,  "tries to skip ~ in version string"
# diff -Nru debian~/tests/excludes/any/TestGemRemoteFetcher.rb debian/tests/excludes/any/TestGemRemoteFetcher.rb
# --- debian~/tests/excludes/any/TestGemRemoteFetcher.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestGemRemoteFetcher.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_do_not_allow_invalid_client_cert_auth_connection, "fails with openssl 1.1.1"
# diff -Nru debian~/tests/excludes/any/TestIO.rb debian/tests/excludes/any/TestIO.rb
# --- debian~/tests/excludes/any/TestIO.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestIO.rb	2021-01-25 23:37:04.814005275 -0500
# @@ -0,0 +1 @@
# +exclude :test_pid, "fails under sbuild"
# diff -Nru debian~/tests/excludes/any/TestMkmf/TestConfig.rb debian/tests/excludes/any/TestMkmf/TestConfig.rb
# --- debian~/tests/excludes/any/TestMkmf/TestConfig.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestMkmf/TestConfig.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_dir_config, "fails for some reason"
# diff -Nru debian~/tests/excludes/any/TestNetHTTPS.rb debian/tests/excludes/any/TestNetHTTPS.rb
# --- debian~/tests/excludes/any/TestNetHTTPS.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestNetHTTPS.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_session_reuse, "fails with openssl 1.1.1"
# +exclude :test_session_reuse_but_expire, "fails with openssl 1.1.1"
# diff -Nru debian~/tests/excludes/any/TestProcess.rb debian/tests/excludes/any/TestProcess.rb
# --- debian~/tests/excludes/any/TestProcess.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestProcess.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,6 @@
# +exclude :test_exec_wordsplit, "fails under sbuild"
# +exclude :test_popen_wordsplit, "fails under sbuild"
# +exclude :test_popen_wordsplit_beginning_and_trailing_spaces, "fails under sbuild"
# +exclude :test_spawn_wordsplit, "fails under sbuild"
# +exclude :test_status_quit, "fails under sbuild"
# +exclude :test_system_wordsplit, "fails under sbuild"
# diff -Nru debian~/tests/excludes/any/TestRefinement.rb debian/tests/excludes/any/TestRefinement.rb
# --- debian~/tests/excludes/any/TestRefinement.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestRefinement.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,2 @@
# +# Found on Debian arm*, powerpc buildds
# +exclude :test_prepend_after_refine_wb_miss, "time consuming test"
# diff -Nru debian~/tests/excludes/any/TestResolvMDNS.rb debian/tests/excludes/any/TestResolvMDNS.rb
# --- debian~/tests/excludes/any/TestResolvMDNS.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestResolvMDNS.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude /.*/, 'too slow, and fails on some of the Debian buildds'
# diff -Nru debian~/tests/excludes/any/TestRubyOptimization.rb debian/tests/excludes/any/TestRubyOptimization.rb
# --- debian~/tests/excludes/any/TestRubyOptimization.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestRubyOptimization.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_tailcall_interrupted_by_sigint, "hangs under sbuild"
# diff -Nru debian~/tests/excludes/any/TestTimeTZ.rb debian/tests/excludes/any/TestTimeTZ.rb
# --- debian~/tests/excludes/any/TestTimeTZ.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/any/TestTimeTZ.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,4 @@
# +exclude :test_gen_Pacific_Kiritimati_71, "https://bugs.ruby-lang.org/issues/14655"
# +exclude :test_gen_Pacific_Kiritimati_89, "https://bugs.ruby-lang.org/issues/14655"
# +exclude :test_gen_lisbon_99, "https://bugs.ruby-lang.org/issues/14655"
# +exclude :test_pacific_kiritimati, "https://bugs.ruby-lang.org/issues/14655"
# diff -Nru debian~/tests/excludes/arm64/TestBugReporter.rb debian/tests/excludes/arm64/TestBugReporter.rb
# --- debian~/tests/excludes/arm64/TestBugReporter.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/arm64/TestBugReporter.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_bug_reporter_add, 'fails ~4% of the time'
# diff -Nru debian~/tests/excludes/arm64/TestRubyOptimization.rb debian/tests/excludes/arm64/TestRubyOptimization.rb
# --- debian~/tests/excludes/arm64/TestRubyOptimization.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/arm64/TestRubyOptimization.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,2 @@
# +# this test hands on the arm64 buildd, but passes just fine on the porterbox
# +exclude :test_clear_unreachable_keyword_args, 'hangs on arm64 buildd'
# diff -Nru debian~/tests/excludes/arm64/TestRubyOptions.rb debian/tests/excludes/arm64/TestRubyOptions.rb
# --- debian~/tests/excludes/arm64/TestRubyOptions.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/arm64/TestRubyOptions.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_segv_loaded_features, 'fails ~3% of the time'
# diff -Nru debian~/tests/excludes/autopkgtest/Racc/TestRaccCommand.rb debian/tests/excludes/autopkgtest/Racc/TestRaccCommand.rb
# --- debian~/tests/excludes/autopkgtest/Racc/TestRaccCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/Racc/TestRaccCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude /./, 'do not use racc2.7 installed on the system'
# diff -Nru debian~/tests/excludes/autopkgtest/TestErbCommand.rb debian/tests/excludes/autopkgtest/TestErbCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestErbCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestErbCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,3 @@
# +exclude :test_template_file_encoding, 'depends on source tree'
# +exclude :test_var, 'depends on source tree'
# +exclude :test_deprecated_option, 'do not use erb installed in the system'
# diff -Nru debian~/tests/excludes/autopkgtest/TestException.rb debian/tests/excludes/autopkgtest/TestException.rb
# --- debian~/tests/excludes/autopkgtest/TestException.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestException.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_nomethod_error_new_receiver, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/autopkgtest/TestFiber.rb debian/tests/excludes/autopkgtest/TestFiber.rb
# --- debian~/tests/excludes/autopkgtest/TestFiber.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestFiber.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_fatal_in_fiber, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemCommandsBuildCommand.rb debian/tests/excludes/autopkgtest/TestGemCommandsBuildCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestGemCommandsBuildCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemCommandsBuildCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,3 @@
# +exclude :test_build_signed_gem, 'depends on source tree'
# +exclude :test_build_auto_resign_cert, 'failure against ruby2.7, needs further investigation'
# +exclude :test_build_signed_gem_with_cert_expiration_length_days, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemCommandsEnvironmentCommand.rb debian/tests/excludes/autopkgtest/TestGemCommandsEnvironmentCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestGemCommandsEnvironmentCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemCommandsEnvironmentCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1 @@
# +exclude :test_execute, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemCommandsSetupCommand.rb debian/tests/excludes/autopkgtest/TestGemCommandsSetupCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestGemCommandsSetupCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemCommandsSetupCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,11 @@
# +exclude :test_execute_regenerate_binstubs, 'depends on source tree'
# +exclude :test_remove_old_lib_files, 'depends on source tree'
# +exclude :test_execute_no_regenerate_binstubs, 'depends on source tree'
# +exclude :test_pem_files_in, 'depends on source tree'
# +exclude :test_show_release_notes, 'depends on source tree'
# +exclude :test_install_lib, 'depends on source tree'
# +exclude :test_rb_files_in, 'depends on source tree'
# +exclude :test_execute_informs_about_installed_executables, 'needs root to install a gem in the system'
# +exclude :test_install_default_bundler_gem_with_force_flag, 'needs root to install a gem in the system'
# +exclude :test_install_default_bundler_gem, 'needs root to install a gem in the system'
# +exclude :test_env_shebang_flag, 'needs root to install a gem in the system'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemCommandsUninstallCommand.rb debian/tests/excludes/autopkgtest/TestGemCommandsUninstallCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestGemCommandsUninstallCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemCommandsUninstallCommand.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_execute_removes_executable, 'depends on source tree'
# +exclude :test_execute_prerelease, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemCommandsUpdateCommand.rb debian/tests/excludes/autopkgtest/TestGemCommandsUpdateCommand.rb
# --- debian~/tests/excludes/autopkgtest/TestGemCommandsUpdateCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemCommandsUpdateCommand.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_update_rubygems_arguments_1_8_x, 'depends on source tree'
# +exclude :test_update_rubygems_arguments, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemExtRakeBuilder.rb debian/tests/excludes/autopkgtest/TestGemExtRakeBuilder.rb
# --- debian~/tests/excludes/autopkgtest/TestGemExtRakeBuilder.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemExtRakeBuilder.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_class_build, 'depends on source tree'
# +exclude :test_class_build_with_args, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemInstaller.rb debian/tests/excludes/autopkgtest/TestGemInstaller.rb
# --- debian~/tests/excludes/autopkgtest/TestGemInstaller.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemInstaller.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,11 @@
# +exclude :test_default_gem, 'depends on source tree'
# +exclude :test_check_executable_overwrite_default_bin_dir, 'depends on source tree'
# +exclude :test_install_creates_working_binstub, 'depends on source tree'
# +exclude :test_conflicting_binstubs, 'depends on source tree'
# +exclude :test_install_with_no_prior_files, 'depends on source tree'
# +exclude :test_install, 'depends on source tree'
# +exclude :test_install_creates_binstub_that_understand_version, 'depends on source tree'
# +exclude :test_install_creates_binstub_that_dont_trust_encoding, 'depends on source tree'
# +exclude :test_default_gem_without_wrappers, 'failure against ruby2.7, expects path /var/lib/gems/2.7.0/specifications/default to exist'
# +exclude :test_default_gem_with_exe_as_bindir, 'failure against ruby2.7, expects path /var/lib/gems/2.7.0/specifications/default to exist'
# +exclude :test_install_creates_binstub_that_prefers_user_installed_gem_to_default, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemPackage.rb debian/tests/excludes/autopkgtest/TestGemPackage.rb
# --- debian~/tests/excludes/autopkgtest/TestGemPackage.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemPackage.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,6 @@
# +exclude :test_verify_security_policy_low_security, 'depends on source tree'
# +exclude :test_build_auto_signed_encrypted_key, 'depends on source tree'
# +exclude :test_verify_security_policy_checksum_missing, 'depends on source tree'
# +exclude :test_build_auto_signed, 'depends on source tree'
# +exclude :test_build_signed_encrypted_key, 'depends on source tree'
# +exclude :test_build_signed, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemPackageTarWriter.rb debian/tests/excludes/autopkgtest/TestGemPackageTarWriter.rb
# --- debian~/tests/excludes/autopkgtest/TestGemPackageTarWriter.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemPackageTarWriter.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude :test_add_file_signer, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGem.rb debian/tests/excludes/autopkgtest/TestGem.rb
# --- debian~/tests/excludes/autopkgtest/TestGem.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGem.rb	2021-01-25 23:37:04.818005195 -0500
# @@ -0,0 +1,12 @@
# +exclude :test_self_prefix, 'depends on source tree'
# +exclude :test_default_path_missing_vendor, 'depends on source tree'
# +exclude :test_default_path, 'depends on source tree'
# +exclude :test_default_path_user_home, 'depends on source tree'
# +exclude :test_default_path_vendor_dir, 'depends on source tree'
# +exclude :test_use_gemdeps, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_self_find_files_with_gemfile, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_auto_activation_of_used_gemdeps_file, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_auto_activation_of_specific_gemdeps_file, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_use_gemdeps_automatic, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_self_use_gemdeps, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# +exclude :test_use_gemdeps_specific, 'failure against ruby2.7, cant find gem bundler (= 2.1.2)'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemRequire.rb debian/tests/excludes/autopkgtest/TestGemRequire.rb
# --- debian~/tests/excludes/autopkgtest/TestGemRequire.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemRequire.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,4 @@
# +exclude :test_no_other_behavioral_changes_with_Kernel_warn, 'failure against ruby2.7, depends on source tree'
# +exclude :test_no_other_behavioral_changes_with_warn, 'failure against ruby2.7, depends on source tree'
# +exclude :test_no_kernel_require_in_warn_with_uplevel, 'failure against ruby2.7, depends on source tree'
# +exclude :test_no_kernel_require_in_Kernel_warn_with_uplevel, 'failure against ruby2.7, depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestGemSpecification.rb debian/tests/excludes/autopkgtest/TestGemSpecification.rb
# --- debian~/tests/excludes/autopkgtest/TestGemSpecification.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestGemSpecification.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude :test_base_dir_default, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestIO.rb debian/tests/excludes/autopkgtest/TestIO.rb
# --- debian~/tests/excludes/autopkgtest/TestIO.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestIO.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_seek, 'depends on source tree'
# +exclude :test_seek_symwhence, 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestJIT.rb debian/tests/excludes/autopkgtest/TestJIT.rb
# --- debian~/tests/excludes/autopkgtest/TestJIT.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestJIT.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude /./, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/autopkgtest/TestRDocGeneratorJsonIndex.rb debian/tests/excludes/autopkgtest/TestRDocGeneratorJsonIndex.rb
# --- debian~/tests/excludes/autopkgtest/TestRDocGeneratorJsonIndex.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestRDocGeneratorJsonIndex.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude :test_generate, 'failure against ruby2.7, depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestRDocRIDriver.rb debian/tests/excludes/autopkgtest/TestRDocRIDriver.rb
# --- debian~/tests/excludes/autopkgtest/TestRDocRIDriver.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestRDocRIDriver.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude :test_display_name_not_found_class, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/autopkgtest/TestRipper/Generic.rb debian/tests/excludes/autopkgtest/TestRipper/Generic.rb
# --- debian~/tests/excludes/autopkgtest/TestRipper/Generic.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestRipper/Generic.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,3 @@
# +exclude :'test_parse_files:ext', 'depends on source tree'
# +exclude :'test_parse_files:lib', 'depends on source tree'
# +exclude :'test_parse_files:sample', 'depends on source tree'
# diff -Nru debian~/tests/excludes/autopkgtest/TestRubyVMMJIT.rb debian/tests/excludes/autopkgtest/TestRubyVMMJIT.rb
# --- debian~/tests/excludes/autopkgtest/TestRubyVMMJIT.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/autopkgtest/TestRubyVMMJIT.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,5 @@
# +exclude :test_pause, 'failure against ruby2.7, needs further investigation'
# +exclude :test_pause_does_not_hang_on_full_units, 'failure against ruby2.7, needs further investigation'
# +exclude :test_pause_wait_false, 'failure against ruby2.7, needs further investigation'
# +exclude :test_pause_waits_until_compaction, 'failure against ruby2.7, needs further investigation'
# +exclude :test_resume, 'failure against ruby2.7, needs further investigation'
# diff -Nru debian~/tests/excludes/i386/DRbTests/TestDRbUNIXCore.rb debian/tests/excludes/i386/DRbTests/TestDRbUNIXCore.rb
# --- debian~/tests/excludes/i386/DRbTests/TestDRbUNIXCore.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/i386/DRbTests/TestDRbUNIXCore.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1 @@
# +exclude :test_02_basic_object, 'flaky test'
# diff -Nru debian~/tests/excludes/kfreebsd-amd64/TestGemSpecification.rb debian/tests/excludes/kfreebsd-amd64/TestGemSpecification.rb
# --- debian~/tests/excludes/kfreebsd-amd64/TestGemSpecification.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-amd64/TestGemSpecification.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +# Actual is one day earlier than Expected
# +exclude :test_date_equals_time, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/kfreebsd-amd64/TestRubyOptions.rb debian/tests/excludes/kfreebsd-amd64/TestRubyOptions.rb
# --- debian~/tests/excludes/kfreebsd-amd64/TestRubyOptions.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-amd64/TestRubyOptions.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,3 @@
# +# Output format of ps is different?
# +exclude :test_set_program_name, 'fails on kFreeBSD'
# +exclude :test_setproctitle, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/kfreebsd-amd64/TestSocket_UNIXSocket.rb debian/tests/excludes/kfreebsd-amd64/TestSocket_UNIXSocket.rb
# --- debian~/tests/excludes/kfreebsd-amd64/TestSocket_UNIXSocket.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-amd64/TestSocket_UNIXSocket.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +# Output format of socket:LOCAL_CREDS differs?
# +exclude :test_sendcred_sockcred, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/kfreebsd-i386/TestGemSpecification.rb debian/tests/excludes/kfreebsd-i386/TestGemSpecification.rb
# --- debian~/tests/excludes/kfreebsd-i386/TestGemSpecification.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-i386/TestGemSpecification.rb	2021-01-25 23:37:04.822005115 -0500
# @@ -0,0 +1,2 @@
# +# Actual is one day earlier than Expected
# +exclude :test_date_equals_time, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/kfreebsd-i386/TestIO.rb debian/tests/excludes/kfreebsd-i386/TestIO.rb
# --- debian~/tests/excludes/kfreebsd-i386/TestIO.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-i386/TestIO.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,8 @@
# +# pid 46356 killed by SIGABRT (signal 6)
# +# | -:8: [BUG] rb_maygvl_fd_fix_cloexec: fcntl(-1, F_GETFD) failed: Bad file descriptor
# +# | ruby 2.7.1p57 (2018-03-29 revision 63029) [i386-kfreebsd-gnu]
# +# | [NOTE]
# +# | You may have encountered a bug in the Ruby interpreter or extension libraries.
# +# | Bug reports are welcome.
# +# | For details: http://www.ruby-lang.org/bugreport.html
# +exclude :test_dup_many, 'fails on kfreebsd-i386'
# diff -Nru debian~/tests/excludes/kfreebsd-i386/TestProcess.rb debian/tests/excludes/kfreebsd-i386/TestProcess.rb
# --- debian~/tests/excludes/kfreebsd-i386/TestProcess.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-i386/TestProcess.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,2 @@
# +# FIXME: pid 61155 SIGABRT (signal 6). <0> expected but was <6>.
# +exclude :test_rlimit_nofile, 'fails on kfreebsd-i386'
# diff -Nru debian~/tests/excludes/kfreebsd-i386/TestRubyOptions.rb debian/tests/excludes/kfreebsd-i386/TestRubyOptions.rb
# --- debian~/tests/excludes/kfreebsd-i386/TestRubyOptions.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-i386/TestRubyOptions.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,3 @@
# +# Output format of ps is different?
# +exclude :test_set_program_name, 'fails on kFreeBSD'
# +exclude :test_setproctitle, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/kfreebsd-i386/TestSocket_UNIXSocket.rb debian/tests/excludes/kfreebsd-i386/TestSocket_UNIXSocket.rb
# --- debian~/tests/excludes/kfreebsd-i386/TestSocket_UNIXSocket.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/kfreebsd-i386/TestSocket_UNIXSocket.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,2 @@
# +# Output format of socket:LOCAL_CREDS differs?
# +exclude :test_sendcred_sockcred, 'fails on kFreeBSD'
# diff -Nru debian~/tests/excludes/mips/TestModule.rb debian/tests/excludes/mips/TestModule.rb
# --- debian~/tests/excludes/mips/TestModule.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/mips/TestModule.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude :test_prepend_gc, 'fails on buildd'
# diff -Nru debian~/tests/excludes/mipsel/OpenSSL/TestSSL.rb debian/tests/excludes/mipsel/OpenSSL/TestSSL.rb
# --- debian~/tests/excludes/mipsel/OpenSSL/TestSSL.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/mipsel/OpenSSL/TestSSL.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,4 @@
# +# these timeout frequently on the Debian buildds
# +exclude :test_dh_callback, 'times out'
# +exclude :test_get_ephemeral_key, 'times out'
# +exclude :test_post_connect_check_with_anon_ciphers, 'times out'
# diff -Nru debian~/tests/excludes/mipsel/TestFiber.rb debian/tests/excludes/mipsel/TestFiber.rb
# --- debian~/tests/excludes/mipsel/TestFiber.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/mipsel/TestFiber.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude :test_fork_from_fiber, 'fails on buildd'
# diff -Nru debian~/tests/excludes/mipsel/TestNum2int.rb debian/tests/excludes/mipsel/TestNum2int.rb
# --- debian~/tests/excludes/mipsel/TestNum2int.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/mipsel/TestNum2int.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,4 @@
# +exclude :test_num2int, 'fails on buildd'
# +exclude :test_num2long, 'fails on buildd'
# +exclude :test_num2uint, 'fails on buildd'
# +exclude :test_num2ulong, 'fails on buildd'
# diff -Nru debian~/tests/excludes/riscv64/Racc/TestRaccCommand.rb debian/tests/excludes/riscv64/Racc/TestRaccCommand.rb
# --- debian~/tests/excludes/riscv64/Racc/TestRaccCommand.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/riscv64/Racc/TestRaccCommand.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude :test_riml, "times out"
# diff -Nru debian~/tests/excludes/riscv64/TestBugReporter.rb debian/tests/excludes/riscv64/TestBugReporter.rb
# --- debian~/tests/excludes/riscv64/TestBugReporter.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/riscv64/TestBugReporter.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude :test_bug_reporter_add, "times out"
# diff -Nru debian~/tests/excludes/riscv64/TestFiber.rb debian/tests/excludes/riscv64/TestFiber.rb
# --- debian~/tests/excludes/riscv64/TestFiber.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/riscv64/TestFiber.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude :test_many_fibers_with_threads, "times out"
# diff -Nru debian~/tests/excludes/riscv64/TestRubyOptions.rb debian/tests/excludes/riscv64/TestRubyOptions.rb
# --- debian~/tests/excludes/riscv64/TestRubyOptions.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/riscv64/TestRubyOptions.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,3 @@
# +exclude :test_segv_loaded_features, "times out"
# +exclude :test_segv_setproctitle, "times out"
# +exclude :test_segv_test, "times out"
# diff -Nru debian~/tests/excludes/salsa/Net/TestSMTP.rb debian/tests/excludes/salsa/Net/TestSMTP.rb
# --- debian~/tests/excludes/salsa/Net/TestSMTP.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/salsa/Net/TestSMTP.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,3 @@
# +exclude :test_eof_error_backtrace, 'fails on salsa ci'
# +exclude :test_tls_connect,         'fails on salsa ci'
# +exclude :test_tls_connect_timeout, 'fails on salsa ci'
# diff -Nru debian~/tests/excludes/salsa/TestJIT.rb debian/tests/excludes/salsa/TestJIT.rb
# --- debian~/tests/excludes/salsa/TestJIT.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/salsa/TestJIT.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1 @@
# +exclude /./, 'fails on salsa ci'
# diff -Nru debian~/tests/excludes/salsa/TestNetHTTPLocalBind.rb debian/tests/excludes/salsa/TestNetHTTPLocalBind.rb
# --- debian~/tests/excludes/salsa/TestNetHTTPLocalBind.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/salsa/TestNetHTTPLocalBind.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,2 @@
# +exclude :test_bind_to_local_host, 'fails on salsa ci'
# +exclude :test_bind_to_local_port, 'fails on salsa ci'
# diff -Nru debian~/tests/excludes/salsa/TestRubyVMMJIT.rb debian/tests/excludes/salsa/TestRubyVMMJIT.rb
# --- debian~/tests/excludes/salsa/TestRubyVMMJIT.rb	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/excludes/salsa/TestRubyVMMJIT.rb	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,5 @@
# +exclude  :test_pause,                              'fails on salsa ci'
# +exclude  :test_pause_does_not_hang_on_full_units,  'fails on salsa ci'
# +exclude  :test_pause_wait_false,                   'fails on salsa ci'
# +exclude  :test_pause_waits_until_compaction,       'fails on salsa ci'
# +exclude  :test_resume,                             'fails on salsa ci'
# diff -Nru debian~/tests/rubyconfig debian/tests/rubyconfig
# --- debian~/tests/rubyconfig	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/rubyconfig	2021-01-25 23:37:04.826005035 -0500
# @@ -0,0 +1,56 @@
# +#!/bin/sh
# +
# +set -eu
# +
# +ruby="${1:-ruby2.7}"
# +apiversion="${ruby##ruby}.0"
# +arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
# +
# +failed=0
# +
# +checkdir() {
# +    key="$1"
# +    expected_value="$2"
# +    value="$($ruby -e "puts RbConfig::CONFIG['$key']")"
# +    if [ "$value" = "$expected_value" ]; then
# +        echo "OK: $key = $value"
# +    else
# +        echo "NOT OK: $key = $value (expected: $expected_value)"
# +        failed=$((failed+1))
# +    fi
# +}
# +
# +checkdir vendorarchhdrdir   /usr/include/$arch/ruby-$apiversion/vendor_ruby
# +checkdir sitearchhdrdir     /usr/include/$arch/ruby-$apiversion/site_ruby
# +checkdir rubyarchhdrdir     /usr/include/$arch/ruby-$apiversion
# +checkdir vendorhdrdir       /usr/include/ruby-$apiversion/vendor_ruby
# +checkdir sitehdrdir         /usr/include/ruby-$apiversion/site_ruby
# +checkdir rubyhdrdir         /usr/include/ruby-$apiversion
# +checkdir vendorarchdir      /usr/lib/$arch/ruby/vendor_ruby/$apiversion
# +checkdir vendorlibdir       /usr/lib/ruby/vendor_ruby/$apiversion
# +checkdir vendordir          /usr/lib/ruby/vendor_ruby
# +checkdir sitearchdir        /usr/local/lib/$arch/site_ruby
# +checkdir sitelibdir         /usr/local/lib/site_ruby/$apiversion
# +checkdir sitedir            /usr/local/lib/site_ruby
# +checkdir rubyarchdir        /usr/lib/$arch/ruby/$apiversion
# +checkdir rubylibdir         /usr/lib/ruby/$apiversion
# +checkdir sitearchincludedir /usr/include/$arch
# +checkdir archincludedir     /usr/include/$arch
# +checkdir sitearchlibdir     /usr/lib/$arch
# +checkdir archlibdir         /usr/lib/$arch
# +checkdir ridir              /usr/share/ri
# +checkdir mandir             /usr/share/man
# +checkdir localedir          /usr/share/locale
# +checkdir libdir             /usr/lib
# +checkdir includedir         /usr/include
# +checkdir runstatedir        /var/run
# +checkdir localstatedir      /var
# +checkdir sysconfdir         /etc
# +checkdir datadir            /usr/share
# +checkdir datarootdir        /usr/share
# +checkdir sbindir            /usr/sbin
# +checkdir bindir             /usr/bin
# +checkdir archdir            /usr/lib/$arch/ruby/$apiversion
# +checkdir topdir             /usr/lib/$arch/ruby/$apiversion
# +
# +[ "$failed" -eq 0 ]
# diff -Nru debian~/tests/run-all debian/tests/run-all
# --- debian~/tests/run-all	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/run-all	2021-01-25 23:37:04.830004955 -0500
# @@ -0,0 +1,44 @@
# +#!/bin/sh
# +
# +exec 2>&1
# +set -e
# +#set -x
# +
# +# test against the default OpenSSL settings and not the Debian-specific ones
# +export OPENSSL_CONF=`pwd`/debian/openssl.cnf
# +
# +tests="$@"
# +
# +cleanup() {
# +  rm -rf "$AUTOPKGTEST_TMP"
# +}
# +if [ -z "$AUTOPKGTEST_TMP" ]; then
# +  AUTOPKGTEST_TMP=$(mktemp -d)
# +  trap cleanup INT TERM EXIT
# +fi
# +
# +skiplist=$(readlink -f $(dirname $0))/skiplist
# +excludedir=$(readlink -f $(dirname $0))/excludes
# +cp -r 'test/' $AUTOPKGTEST_TMP
# +cp -r 'tool/' $AUTOPKGTEST_TMP
# +cd $AUTOPKGTEST_TMP
# +
# +if [ -z "$tests" ]; then
# +  # FIXME for now, we are excluding the tests for C extensions; couldn't figure
# +  # out how to properly build them without building everything else
# +  tests=$(find 'test/' -name 'test_*.rb' -and -not -path '*-ext-*' | sort)
# +fi
# +
# +excludes="--excludes-dir=test/excludes/"
# +excludes="$excludes --excludes-dir=${excludedir}/any/"
# +excludes="$excludes --excludes-dir=${excludedir}/$(dpkg-architecture -qDEB_HOST_ARCH)/"
# +excludes="$excludes --excludes-dir=${excludedir}/autopkgtest/"
# +
# +run_tests=''
# +for t in $tests; do
# +  if ! grep -q "^$t$" "$skiplist"; then
# +    run_tests="$run_tests $t"
# +  fi
# +done
# +
# +ruby2.7 test/runner.rb -v $excludes --name='!/memory_leak/' $run_tests
# diff -Nru debian~/tests/skiplist debian/tests/skiplist
# --- debian~/tests/skiplist	1969-12-31 19:00:00.000000000 -0500
# +++ debian/tests/skiplist	2021-01-25 23:37:04.830004955 -0500
# @@ -0,0 +1,19 @@
# +test/mkmf/test_libs.rb
# +test/mkmf/test_have_macro.rb
# +test/mkmf/test_flags.rb
# +test/mkmf/test_sizeof.rb
# +test/mkmf/test_convertible.rb
# +test/mkmf/test_have_func.rb
# +test/mkmf/test_framework.rb
# +test/mkmf/test_find_executable.rb
# +test/mkmf/test_config.rb
# +test/mkmf/test_have_library.rb
# +test/mkmf/base.rb
# +test/mkmf/test_signedness.rb
# +test/mkmf/test_constant.rb
# +test/rubygems/test_gem_commands_cert_command.rb
# +test/rubygems/test_gem_request.rb
# +test/rubygems/test_gem_security.rb
# +test/rubygems/test_gem_security_policy.rb
# +test/rubygems/test_gem_security_signer.rb
# +test/rubygems/test_gem_security_trust_dir.rb
# diff -Nru debian~/TODO debian/TODO
# --- debian~/TODO	1969-12-31 19:00:00.000000000 -0500
# +++ debian/TODO	2021-01-25 23:37:04.794005674 -0500
# @@ -0,0 +1,48 @@
# +# Multiarch
# +
# +- ruby2.0 packages for different architectures are not co-installable because
# +  the generated .gemspec files might differ between architectures (tested with
# +  i386 and amd64)
# +
# +
# +# Problems indicated by Lintian
# +
# +W: ruby2.0: manpage-has-errors-from-man usr/share/man/man1/ri2.0.1.gz  .Nm name ... (#88)
# +W: ruby2.0: binary-without-manpage usr/bin/gem2.0
# +W: ruby2.0: binary-without-manpage usr/bin/rdoc2.0
# +W: ruby2.0: binary-without-manpage usr/bin/testrb2.0
# +W: ruby2.0: binary-without-manpage usr/bin/x86_64-linux-gnu-ruby2.0
# +W: libruby2.0: package-name-doesnt-match-sonames libruby-2.0-2.0
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/libruby-2.0.so.2.0.0
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/digest/md5.so
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/digest/rmd160.so
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/digest/sha1.so
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/digest/sha2.so
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/fiddle.so
# +W: libruby2.0: hardening-no-relro usr/lib/x86_64-linux-gnu/ruby/2.0.0/openssl.so
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/add.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/arrow_up.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/brick.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/brick_link.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/bug.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/bullet_black.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/bullet_toggle_minus.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/bullet_toggle_plus.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/date.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/delete.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/find.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/loadingAnimation.gif
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/macFFBgHack.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/package.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/page_green.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/page_white_text.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/page_white_width.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/plugin.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/ruby.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/tag_blue.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/tag_green.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/transparent.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/wrench.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/wrench_orange.png
# +W: libruby2.0: image-file-in-usr-lib usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/images/zoom.png
# +W: libruby2.0: embedded-javascript-library usr/lib/ruby/2.0.0/rdoc/generator/template/darkfish/js/jquery.js
# diff -Nru debian~/upstream-changes debian/upstream-changes
# --- debian~/upstream-changes	1969-12-31 19:00:00.000000000 -0500
# +++ debian/upstream-changes	2021-01-25 23:37:04.830004955 -0500
# @@ -0,0 +1,9 @@
# +#!/bin/sh
# +
# +set -e
# +
# +version=$(dpkg-parsechangelog -SVersion | cut -d - -f 1)
# +
# +files=$(git diff --name-only upstream/${version}.. | grep -v ^debian)
# +
# +git log -p --no-merges --cherry-pick upstream/${version}.. -- $files
# diff -Nru debian~/upstream-changes.blacklist debian/upstream-changes.blacklist
# --- debian~/upstream-changes.blacklist	1969-12-31 19:00:00.000000000 -0500
# +++ debian/upstream-changes.blacklist	2021-01-25 23:37:04.830004955 -0500
# @@ -0,0 +1,11 @@
# +Commit: f8e19f34f0cb8b1c0de4a510f1d34d5c8b8d1b3e
# +Reason: changed non-Debian files by mistake
# +
# +Commit: b4c901d9ea3a91ae659392de626fcd39292b0b4d
# +Reason: changed non-Debian files by mistake
# +
# +Commit: d0a9a906dac008be59ba24565bd2634dba5fb78a
# +Commit: a94981bb5fc2be374a8921543446d911896c48c8
# +Commit: 1fbbc109d2285bef91ae028f6f2fd46b170527d8
# +Commit: 8d35c5a6f180aa064fc74149f9eab660873e7e5d
# +Reason: commits that were ultimately wrong, and were already reverted
# diff -Nru debian~/watch debian/watch
# --- debian~/watch	1969-12-31 19:00:00.000000000 -0500
# +++ debian/watch	2021-01-25 23:37:04.830004955 -0500
# @@ -0,0 +1,3 @@
# +version=3
# +opts="uversionmangle=s/-rc/~rc/;s/-preview/~preview/;s/_/./g" \
# +  https://cache.ruby-lang.org/pub/ruby/2.7/ ruby-(.*)\.tar\.gz
