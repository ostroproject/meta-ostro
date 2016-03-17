.. _booting-and-installation:

Booting and Installing an Ostro |trade| OS Image
#################################################

This technical note explains the basic procedures for taking an Ostro OS image that was downloaded
or built from source (using instructions in :ref:`Building Images`), and installing and 
running that image one of the :ref:`platforms`.

Two images are of interest for this process (depending if you're using real hardware or a VM):

:file:`.dsk.xz`
    A compressed raw disk image in GPT format and contains at least one UEFI bootable partition
    and at least one ext4 partition (rootfs).  For details on disk layout
    see the associated :file:`.json` file in the same directory as the image file.

:file:`.vdi`
    A :file:`.dsk` image converted to VirtualBox\* format (with no other differences).


Ostro OS Images
===============

As explained in the :ref:`Building Images` tech note, there are several image variants available
depending on your need.  For simplicity and the needs of this tech note, we'll use the dev image that includes
additional build and debugging tools that wouldn't typically be included in a production device image. This
dev image also will auto-login as ``root`` at the console, something that normally would not be available
in a production device image but is quite useful during development.

Using dd to Create Bootable Media
=================================

Once you have the :file:`.dsk.xz` Ostro OS image you need to get it
onto your hardware platform, typically by using removable media such as a 
USB thumb drive or SD card.  The usual way to do this is with the :command:`dd` command.

#. Connect your USB thumb drive or SD card to your Linux-based development system
   (minimum 8 GB card required).
#. If you're not sure about your media device name, use the :command:`dmesg` command to view the system log 
   and see which device the USB thumb drive or SD card was assigned (e.g. :file:`/dev/sdb`)::

     $ dmesg 

   or you can use the :command:`lsblk` command to show the block-level devices; a USB drive usually 
   shows up as ``/sdb`` or ``/sdc``
   (almost never as ``/sda``) and an SD card would usually show up as :file:`/dev/mmcblk0`.  
   
   Note: You should specify the whole device you're writing to with 
   :command:`dd`:  (e.g., :file:`/dev/sdb` or
   :file:`/dev/mmcblk0`) and **not** just a partition on that device (e.g., :file:`/dev/sdb1` or
   :file:`/dev/mmcblk0p1`) on that device. 

#. The :command:`dd` command will overwrite all content on the device so be careful specifying 
   the correct media device. In the example below, :file:`/dev/sdb` is the 
   destination USB device on our development machine::

      $ sudo umount /dev/sdb*
      $ xzcat <ostro-os-image.dsk.xz> | sudo dd of=/dev/sdb bs=512k
      $ sync

Unplug the removable media from your development system and you're ready to plug 
it into your target system.


MinnowBoard Turbot - a MinnowBoard MAX Compatible
=================================================

The `MinnowBoard Turbot`_ is a small form-factor board with an Intel |reg| Atom |trade| E3826 dual-core processor.  
Once you have the Ostro OS image on a USB thumb drive (or SD card), you can use this to boot your MinnowBoard MAX compatible board as you would
most any Intel UEFI-based system.  The procedure will be similar for other boards so we’ll use this as an example.  
See http://wiki.minnowboard.org for additional information about setting up the MinnowBoard hardware. 

.. note::

    It's important to use a current version of firmware on your board, so we recommend checking this 
    first and updating the firmware if needed using the instructions 
    at http://wiki.minnowboard.org/MinnowBoard_MAX_HW_Setup.  Ostro OS releases are built and tested
    with 64-bit support, so you should make sure that the firmware is also setup for 64-bit support.  

Here are the basic steps for booting the Ostro OS:

#. Connect an HDMI monitor, USB keyboard, and network cable. Alternatively you can connect the serial 
   FTDI cable from the MinnowBoard to a USB port on your host computer and use a terminal emulator 
   to communicate with the MinnowBoard.)
#. Plug in the USB thumb drive with your Ostro OS image to your MinnowBoard
#. Power the board on
#. Wait for the system to enter the EFI shell where you can set the system date and time with the :command:`date` and :command:`time`
   (Because the MinnowBoard MAX does not have a battery for the clock (RTC), the system date and time revert to the date and time
   when the firmware was created.)
#. Enter :command:`exit` to return to the boot option screen
#. Use the arrow keys to select Boot Manager, press return, then select EFI USB Device, and press return
#. The Ostro OS will begin booting and debug messages will appear on the terminal
#. A warning will appear indicating this is a development image and you will be automatically logged in as ``root`` (no password)

.. _MinnowBoard Turbot: http://wiki.minnowboard.org


Gigabyte
========

The `GigaByte GB-BXBT-3825 <http://iotsolutionsalliance.intel.com/solutions-directory/gb-bxbt-3825-iot-gateway-solution>`_
is a gateway solution powered by an Intel |reg| Atom |trade| E3825 dual-core processor 
(64-bit images are supported). Booting is similar to booting a 
MinnowBoard MAX from the USB thumbdrive described above. 

Galileo Gen 2
=============

The `Intel Galileo Gen 2`_ is an Intel® Quark x1000 32-bit, single core, Intel Pentium |reg| Processor class SOC-based board, pin-compatible with shields designed for the Arduino Uno R3. 

Flashing an `Intel Galileo Gen 2`_ requires use of a microSD card (booting off USB is not supported).

Here are the basic steps for booting the Ostro OS:

#. Flash the microSD card with the Ostro OS image as described in the `Using dd to Create Bootable Media`_ section above
#. Insert the microSD card in the Galileo Gen 2 board
#. Connect the serial FTDI cable from the `Intel Galileo Gen 2`_ to a USB port on your host computer and use a terminal emulator (settings: 115200 8N1)
#. Power the board on (using a 5V, 3A power supply)
#. Press [Enter] to directly boot
#. The Ostro OS will begin booting and debug messages will appear on the terminal
#. A warning will appear indicating this is a development image and you will be automatically logged in as ``root`` (no password)

.. _Intel Galileo Gen 2: http://www.intel.com/content/www/us/en/embedded/products/galileo/galileo-overview.html

Intel Edison
============

Flashing an Intel Edison requires use of a breakout board and two micro-USB cables:

#. Install the ``dfu-util`` package. (You may also need the ``xfstk`` utility from http://xfstk.sourceforge.net 
   for recovery cases.)
#. Plug in a micro-USB cable to the J3 connector on the board (corner next to the FTDI chip)
#. Flip the DIP switch towards jumper J16
#. Open :command:`minicom` or other terminal program on your host computer to attach to the serial console
#. Download the ``flashall`` folder from the Ostro OS download folder for edison (on https://download.ostroproject.org)
#. Copy the flashall script (``flashall.sh``) from the flashall folder to the Ostro OS image folder
#. Then in the image folder run:: 

    $ sudo ./flashall.sh

#. Plug in the second micro-USB cable to the J16 connector as instructed by the running flashall script
#. Wait for all the images to flash. You will see the progress on both the flasher and on the serial console
#. Once flashing is done, the image will automatically boot up and auto-login as ``root``, no password is required

BeagleBone
==========

BeagleBone is booted from a microSD card. Partitions are MSDOS, not GPT.

#. Create two partitions, 64 MB primary partition of type 6 (FAT16) and make it bootable, rest of the space as primary partition of type 83 (Linux)

   To make the partition bootable run the commands fdisk /dev/sdX (where X is your microSD card)::

    Command (m for help): p
    Device     Boot  Start      End  Sectors  Size Id Type
    /dev/sdd1  *      2048   133119   131072   64M  e W95 FAT16 (LBA)
    /dev/sdd2       133120 15523839 15390720  7.3G 83 Linux

   *NOTE:* The first partition needs an asterix boot flag set. If there is none, please run::

    Command (m for help): a
    Partition number (1,2, default 2): 1
    Command (m for help): w
    The partition table has been altered.
    Calling ioctl() to re-read partition table.
    Syncing disks.

#. Format the first FAT partition using ``mkfs.vfat -n BOOTFS -F 16``
#. Copy ``MLO`` and ``u-boot.img`` to the FAT16 partition
#. Format the second partition using ``mkfs.ext4 -L rootfs``
#. You may want to disable periodic filesystem check by using ``tune2fs -c0 -i0``
#. Extract ``iot-os-image-beaglebone.tar.bz2`` to the ext4 partition, using tar >= version 1.27 and ``--xattrs --xattrs-include=*`` (otherwise Smack labels and IMA xattrs get lost)
#. Copy ``zImage-am335x-boneblack.dtb`` as ``am335x-boneblack.dtb``, and ``zImage-am335x-bone.dtb`` as ``am335x-bone.dtb`` to ``boot/`` on this partition
#. Insert the SDcard and power up the device

Extra:

#. You may need to use the alternate boot button S2 by holding it down at power up to boot from microSD instead of eMMC
#. Once booted up from microSD you can prevent boot from eMMC by using ``dd if=/dev/zero of=/dev/mmcblk1 bs=4M count=1``

Running Ostro OS in a VirtualBox\* VM
======================================

You can run an Ostro OS image within a VirtualBox virtual machine by using the pre-built ``.vdi`` file found 
in the binary release directory (on https://download.ostroproject.org), or as the result of doing your 
own build from source.  As with the other examples above, we recommend you start with the "dev" image.

#. If you haven’t already done so, download and install VirtualBox (version 5.0.2 or later) 
   on your development system from https://www.virtualbox.org/wiki/Downloads. VirtualBox uses 
   VDI as its native disk image format so you’ll be using that file instead of the .dsk file used 
   with real hardware platforms. 
#. Open the VirtualBox program and start by creating a new machine, give it a name 
   (such as "Ostro OS build#"), select "Linux" for the VM type, and 
   "Fedora (64-bit)" for the version.  Click next.
#. Use a minimum of 256MB RAM for the memory configuration. You can increase this if your application needs more. Click next.
#. Select "Use an existing virtual hard disk file", click on the folder icon and select the ``.vdi`` file you downloaded 
   or created, and select "Create" to create the hard drive.
#. Click on the System options and remove all the boot order options other than the "Hard Disk", and check "Enable EFI (special OSes only)".
   While still on the system configuration, click on the "Acceleration" tab and verify that 
   "Enable VT-x/AMX-V" (HW virtualization support) is checked. Click OK.
#. Finally, click on the "Start" arrow button and your new virtual machine will start 
   booting the Ostro OS Dev image and auto-login as root, no password is required.

If booting fails with a kernel panic, verify you’re using VirtualBox version 5.0.2 or later.  You can shut the machine down 
by either using the :command:`shutdown now` within the running Ostro OS image, or by using the VirtualBox menu 
Machine/ACPI-shutdown.


