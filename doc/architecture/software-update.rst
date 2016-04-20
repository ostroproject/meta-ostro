.. _software-update:

Software Update Mechanism for Ostro |trade| OS
##############################################

Introduction
============

Ostro OS based software can be deployed to a target device in two ways:

- Full Disk Flashing

  A new software image is built and installed, completely replacing
  what was previously present on the device.
  It can be useful for initializing a device with Ostro OS.

- Software Update

  This is a component that Ostro OS borrows from Clear Linux\* OS
  for Intel |reg| Architecture and consists of both a server and client
  component.


Software Update
===============
The main concept behind the Software Update tool_ is that it doesn't
rely on the target device to perform the installation of packages,
handle file conflicts, dependency and versioning check.
Instead, all of this happens a priori, on a build server.
And it happens only once, instead of trying to repeat the same
operations on each device.
All the device needs to do is to lookup a reference file (manifest)
for the list of files it must acquire, should they not be present locally.
The tool focuses on high level functionality (bundles), instead of
individual packages.
In detail, the Software Update functionality is comprised of a pair of
tools:

 - Software Update Server

   A back end tool which generates the bundle/update data stream.

 - Software Update Client

   A tool that resides on the device and consumes/applies the data
   from the bundle/update stream.


Software Update Server
======================

The software update server is a tool used to produce the stream of updates
that, later on, a device can consume, to upgrade itself.
It runs on the backend machine(s) producing the build artefacts.
For example, in the case of a large build infrastructure, it can run on
a CI (Continuous Integration) server.
For each build, the server generates information specific to that build
(in software update lingo, the delta from version 0) and related to
previous builds (deltas from a customizable number of previous versions).

The information produced by the server is then provided by an HTTP server
and consumed by the software update client running on supported devices.

Update information is secured by generating hashes of each file and then
signing the file containing the references to the hashes.
There is no need for a secure channel, for distributing the updates.
As long as the signature and integrity checks are satisfied, the software
update client will treat them as trusted.


Software Update Client
======================

The client runs on the device and is responsible of downloading, verifying
and applying the updates.
It can also restore modified files to their pristine state as then were in the
initial sw image.


SW Bundles
==========

The software update mechanism supports the concept of bundles_: groups of files
that provide one functionality.
It is similar to the concept of a package used in the vast majority of Linux distros,
but in general one software update bundle maps to several packages (ex: .rpm or .deb)

There is one main os-core bundle containing everything that is mandatory for having
a bare-bones working system.
Everything else is optional and can be either deployed or removed by using the
software update client program.

Ostro OS developers can also use bundles by following the rule that each application is
contained in its own bundle.

As said earlier, bundles differ from traditional packages, because they are simply
a mechanism to deliver files to the device.
Any possible conflict that might appear when attempting to deploy software components
will happen on the build servers and will be solved there.

Bundles are therefore produced from a rootfs context that has been already vetted.

.. _tool: https://clearlinux.org/documentation/index_sw_update.html

.. _bundles: https://clearlinux.org/documentation/bundles_overview.html

