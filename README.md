Overview
========

This repository contains:

1) Profile hooks in hooks/

   TKLBAM supports profile level hook scripts which live inside the profile.
   They work just like the hooks in /etc/tklbam/hooks.d except that they need
   to be cryptographically signed by the TurnKey release key for security
   reasons.

   The idea is to use this to build up a library of hooks that are
   useful during migration (e.g., stopping/starting services to prevent
   serialization issues, tweaking a configuration file or upgrading a
   database schema, etc.)

   We don't use this enough yet, but the infrastructure is there ready to use
   and contributions are welcome.

2) Path includes/excludes configurations in the top-level

   These are the plain text top-level configuration files which we use
   to determine which paths to index changes when appliance specific TKLBAM
   profiles are generated. The tklbam-profile configurations are essentially
   a base /etc/tklbam/overrides file which ships with TKLBAM.

   Each TurnKey app has its own configuration file that includes or excludes
   filesystem paths. You may notice that most of the app specific profiles are
   empty. This is because all appliance specific tklbam-profile config files
   depend on the 'core' profile. The 'core' profile is quite extensive so
   most appliances do not need any additional TKLBAM backup paths. When no
   additional paths are required, an empty file is all that is needed.

What paths are we scanning changes to?
======================================

As per the embedded documentation from tklbam internal create-profile
command, in principle, we want to track changes to the user-servicable,
customizable parts of the filesystem. E.g.:

- /etc
- /root
- /home
- /usr/local
- /var/www
- /opt
- /srv

And ignore common cache & temp paths and areas maintained by the package
management system.

- /tmp
- /run
- /var/run (symlink to /run in modern Debian)

FYI general filesystem paths are described by the "Filesystem Hierarchy
Standard".

Why not backup everything?

TKLBAM was originally designed to make it easy for users to only backup the
delta (i.e., changes) from a known/fixed installation base (i.e. changes made
to a TurnKey appliance). Despite this, with a custom profile it should be
useful for backups on vanilla Debian and other Debian based systems.

By default a backup only includes your data and configurations, plus a list of
new packages you've installed. Later when you restore these will be overlaid on
top of the new appliance's filesystem and the package management system will be
asked to install the missing packages. This minimizes the size of the backup,
while ensuring your important data is included.

By contrast, If you backup the entire filesystem TKLBAM won't be able to help
you migrate your data and configurations to a newer version of an appliance.
The restore will just run everything over. At best you'll end up with the old
appliance in a new location. But more likely you'll end up mixing the old and
new filesystems and break things.

Limitations
-----------

- Migrating data to newer major version TurnKey appliance (e.g. v18.2 => v19.0)
  may require some manual adjustment, most likely updated config in /etc.
  We suggest that you try a restore to a new server first and test. If there
  are problems, it is often better to do a 2-stage restore; first download your
  backup, then only restore specific paths. See tklbam-restore docs for more
  details.

- Most Debian packages use /var/lib/PKG_NAME as a user data store. If you
  install additional packages it is important to be aware that occasionally
  that dir may contain data you may want to backup. Testing by a backup restore
  to a "clean" TurnKey server of the same version will assist you to confirm
  whether you need to add a path to your /etc/tklbam/overrides file or not.

More detail
===========

```
$ tklbam internal create-profile --help
Syntax: create-profile [ -options ] output/profile/ <conf>
Create custom backup profile

What is a backup profile?

A backup profile is used to calculate the list of system changes that need to
be backed up (e.g., new files and packages). It typically describes the
installation state of the system and includes 3 files:

* dirindex.conf: list of filesystem paths to scan for changes
* dirindex: index of timestamps, ownership and permissions for dirindex.conf paths
* packages: list of currently installed packages.

[ .. snip ..]
```

See also `./bin/make-profile --help`
(a copy of buildtasks/bin/generate-tklbam-profile)
