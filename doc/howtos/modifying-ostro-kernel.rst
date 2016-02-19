.. _modify_ostro_kernel:

How to modify the Ostro |trade| kernel
######################################

Pre-requisites
==============
This document assumes that you have successfully followed the instructions to set your development system up and are already able to generate Ostro |trade| images. Please refer to Getting Started Guide :ref:`quick_start` if you need help doing so.

The task at stake is to modify the Ostro kernel sources to add (or simply modify) a new driver. There are other ways of achieving that goal that are not described here and if you would like to read more on this topic, we recommend that you read the `Yocto Project Linux Kernel Development Manual`_.

Preparing the kernel source code
================================

Assuming the repository where you have cloned the Ostro source code is called ``ostro-os``:

.. code-block::

   cd ostro-os
   source oe-init-build-env
   bitbake linux-yocto


Modifying the kernel
====================

This will ensure you have built the kernel once and will have extracted the sources and generated a ``.config`` file. The source code is located in the Yocto `${WORKDIR}`_ which is: ``tmp-glibc/work/corei7-64-intel-common-iotos-linux/linux-yocto/<kernel-version>/linux-corei7-64-intel-common-standard-build/source``. Make all the changes that you need, source code modifications including ``Kconfig`` and ``Makefile`` files if relevant.

* If needed, modify the kernel configuration to enable your changes: :command:`bitbake linux-yocto -c menuconfig`
* Recompile the (modified) kernel: :command:`bitbake -f linux-yocto -c compile`

  * Note 1: using ``-c compile`` ensures that :command:`bitbake` will **not** re-fetch the sources and wipe all changes you've just made.
  * Note 2: you need to use the ``-f`` option to force the rebuild because :command:`bitbake` will not detect the changes in the Yocto `${WORKDIR}`_ and will think it's already successfully built the kernel.

* Compile all drivers (modules): :command:`bitbake -f linux-yocto -c compile_kernelmodules`

Generating an image with all the changes
========================================

* To build a full image with this new kernel: :command:`bitbake iot-os-image`
This will generate a complete image and re-use the kernel that you've just modified and subsequently successfully compiled.

Integrating the changes in your source tree
===========================================

Once you're happy with your new driver, the next step is to generate a patch and config fragment to be included in your source code so that your changes are always automatically applied.

.. _Yocto Project Linux Kernel Development Manual: http://www.yoctoproject.org/docs/2.0/kernel-dev/kernel-dev.html
.. _${WORKDIR}: http://www.yoctoproject.org/docs/2.0/ref-manual/ref-manual.html#var-WORKDIR
