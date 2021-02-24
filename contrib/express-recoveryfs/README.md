# Alternative method of building recoveryfs
The script, *express-recoveryfs.sh*, processes two filesystems -
*rootfs* and *recoveryfs* - to produce a list of packages  to remove
from *rootfs* in order to re-create *recoveryfs*.  The generated list,
*pkgs-to-remove.list*, is incomplete.  Additional packages need to be
removed.  This additional list of packages is manually curated.

After the combined lists packages are purged from *rootfs*, minor
adjustments are still needed to produce a filesystem that is functionally
equivalent to the original *recoveryfs*.

The two lists of packages to remove from *rootfs* and the sequence of
commands that complement them can then be bundled into a new script,
*alt-recoveryfs.sh* which may be used to expedite building
*recoveryfs*.
