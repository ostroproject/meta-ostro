.. _software-update-server:

Software Update: Building an Ostro |trade| OS  Repository
#########################################################

This technical note provides instructions to help you build a repository 
used to make software updates work with the Ostro OS.

Prerequisites
=============

- additional (fast) disk space: the tool is provide das additional layer, therefore it doesn't
  require any additional element, however the process is quite disk intensive
  and can greatly benefit from a faster disk. It will also produce various rootfs
  directory as intermediate artefacts. The actual disk footprint depends on the bundles
  selected/defined, but it will be definitely larger.
- signing keys (alternatively testing keys from the :file:`swupd-server` project can
  be used).

Bundles definition
==================

The extensive documentation can be found in the swupd layer_ and will not be replicated here.
These instructions are based on the assumption that the work will happen on top of an image
flavor that has swupd enabled.
These are the main steps:

- set the `OS_VERSION` variable to assigned an integer value matching `VERSION_ID` in the
  os-release recipe. This this number must be increased before each build which should 
  generate swupd update artefacts
- assign a list of bundle names to `SWUPD_BUNDLES` i.e:

    ```SWUPD_BUNDLES = "feature_one feature_two"```

- for each named bundle, assign a list of packages for which their content should be
  included in the bundle to a varflag of `BUNDLE_CONTENTS` which matches the bundle name i.e:

    ```BUNDLE_CONTENTS[feature_one] = "package_one package_three package_six"```


Creating a Software Update Repo
===============================

[Pending: To be filled based on the final setup]

.. _layer: http://git.yoctoproject.org/cgit/cgit.cgi/meta-swupd/tree/docs/GUIDE.md
