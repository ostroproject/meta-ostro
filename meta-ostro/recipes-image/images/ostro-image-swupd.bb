SUMMARY = "Ostro image with swupd enabled."

# Image configuration changes cannot be done using the
# _pn-ostro-image-swupd notation, because then the configuration of
# this base image and the virtual images created from it would be
# different.
#
# Instead extend these variables.
OSTRO_IMAGE_SWUPD_EXTRA_FEATURES ?= ""
OSTRO_IMAGE_SWUPD_EXTRA_INSTALL ?= ""
OSTRO_IMAGE_EXTRA_FEATURES += "${OSTRO_IMAGE_SWUPD_EXTRA_FEATURES}"
OSTRO_IMAGE_EXTRA_INSTALL += "${OSTRO_IMAGE_SWUPD_EXTRA_INSTALL}"

# Enable swupd.
OSTRO_IMAGE_EXTRA_FEATURES += "swupd"

# Define os-core content and additional bundles. Which bundles are
# useful depends on the use cases. For Ostro OS example images, all we
# care about at the moment is
# a) to demonstrate that bundles can be added and removed
# b) build two different images (minimal and for on-target development)
#
# This can be achieved with just the os-core bundle (defined by the
# content of this image recipe here) and one additional bundle
# with the development tools and files.
#
# Keeping the number of bundles as low as possible is good for build
# performance, too.
#
# Beware that removing bundles (and thus renaming) is currently
# not supported by swupd client. When the need arises, the old
# bundle has to be kept with some minimal content (see also
# https://bugzilla.yoctoproject.org/show_bug.cgi?id=9493).
SWUPD_BUNDLES ?= " \
    world-dev \
    qa-bundle-a \
    qa-bundle-b \
"

# os-core defined via additional image features maintained in ostro-image.bbclass.
OSTRO_IMAGE_EXTRA_FEATURES += "${OSTRO_IMAGE_FEATURES_REFERENCE}"
OSTRO_IMAGE_EXTRA_INSTALL += "${OSTRO_IMAGE_INSTALL_REFERENCE}"

# One additional bundle for on-target development.
# Must contain all of the Ostro OS components because
# otherwise they would not be available via swupd.
#
# Developers are able to tweak this bundle by modifying the variables in
# their local.conf (BUNDLE_CONTENTS_WORLD_append = " perf") or
# overridding it entirely (BUNDLE_CONTENTS_WORLD = "iotivity",
# BUNDLE_FEATURES_WORLD = "").
#
# Features already added to the os-core are listed here again
# for the sake of simplicity. To remove them, both BUNDLE_FEATURES_WORLD
# and OSTRO_IMAGE_EXTRA_FEATURES need to be modified.
BUNDLE_CONTENTS_WORLD ?= " \
    ${OSTRO_IMAGE_INSTALL_DEV} \
"
BUNDLE_FEATURES_WORLD ?= " \
    ${OSTRO_IMAGE_PKG_FEATURES} \
"

# The additional features automatically add development and
# ptest packages for everything that gets installed in the
# bundle.
#
# It would be useful to also add debug packages (via dbg-pkgs),
# but that increases the size too much (ostro-image-swupd-dev content
# no longer fits for Edison and has very little free space left
# in the 4GB images used elsewhere).
BUNDLE_CONTENTS[world-dev] = " \
    ${BUNDLE_CONTENTS_WORLD} \
"
BUNDLE_FEATURES[world-dev] = " \
    ${BUNDLE_FEATURES_WORLD} \
    dev-pkgs \
    ptest-pkgs \
"
BUNDLE_CONTENTS[qa-bundle-a] = " \
    hello-bundle-a \
    hello-bundle-s \
"
BUNDLE_CONTENTS[qa-bundle-b] = " \
    hello-bundle-b \
    hello-bundle-s \
"

# When swupd bundles are enabled, choose explicitly which images
# are created. The base image will only have the core-os bundle.
#
# The additional images will be called <base image recipe>-<name in SWUPD_IMAGES>,
# for example ostro-image-swupd-dev in this case.
#
# Taking all this into account, we end up with the following images:
# ostro-image-swupd -
#    Base image plus login via getty and ssh, plus connectivity.
#    This is what developers are expected to start with when
#    building their first image.
# ostro-image-swupd-dev -
#    Image used for testing Ostro OS. Contains most of the software
#    pre-installed, including the corresponding development files
#    for on-target compilation.
# ostro-image-swupd-all -
#    Contains all defined bundles. Useful as meta target, but not
#    guaranteed to build images successfully, for example because
#    the content might get too large for machines with a fixed image
#    size.
SWUPD_IMAGES ?= " \
    dev \
    all \
"

#add qa-bundle-a in swupd-dev image for QA testing.
SWUPD_IMAGES[dev] = " \
    world-dev \
    qa-bundle-a \
"
SWUPD_IMAGES[all] = " \
    ${SWUPD_BUNDLES} \
"

# Inherit the base class after changing relevant settings like
# the image features, because the class looks at them at the time
# when it gets inherited.
inherit ostro-image
