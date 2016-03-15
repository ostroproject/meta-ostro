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
#. Download the ``ostro-image`` or ``ostro-image-dev`` image from the Ostro OS download folder for edison (on https://download.ostroproject.org/releases/ostro-os/milestone/)
#. Extract the image using the command ``$ tar xf ostro-image-*-edison-*.toflash.tar.bz2`` archive
#. Change directory to the toFlash folder
#. Run the command ``$ sudo ./flashall.sh`` |BR|
   `NOTE:` If the script is unable to find the image please use the -i
   <imagename> argument. 
#. Plug in the second micro-USB cable to the J16 connector as instructed by the running flashall script
#. Wait for all the images to flash. You will see the progress on both the flasher and on the serial console
#. Once flashing is done, the image will automatically boot up and auto-login as ``root``, no password is required
     

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


