# Alternative method of building recoveryfs

The script, *express-recoveryfs.sh*, processes two filesystems -
*rootfs* and *recoveryfs* - to produce a list of packages to remove
from *rootfs* in order to re-create *recoveryfs*. The generated list,
*pkgs-to-remove.list*, is incomplete. A second list of residual
packages to remove must be manually curated.

After the combined lists of packages are purged from *rootfs*, minor
adjustments are still needed to produce a filesystem that is functionally
equivalent to the original *recoveryfs*.

For an example of a script derived from these steps,
see
[alt-recoveryfs.sh](https://github.com/revolution-robotics/roadrunner-debian/blob/debian_buster_rr01/revo/alt-recoveryfs.sh).
Provided the lists of packages are up to date, this script may be used
to expedite building *recoveryfs*. To enable this, in top-level build script,
*revo_make_debian.sh*, set varialble USE_ALT_RECOVERYFS to `true`.
