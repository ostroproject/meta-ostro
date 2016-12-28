FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# Prefer systemd way of creating getty@.service symlinks using
# systemd-getty-generator (instead of the Yocto default
# systemd-serialgetty that creates everything in do_install).
PACKAGECONFIG_append = "serial-getty-generator"

# This .bbappend enables systemd-boot from systemd source similar
# to gummiboot_git.bb (in meta/) and .bbappend (in meta-ostro-fixes/).

DEPENDS += " ${@bb.utils.contains('MACHINE_FEATURES', 'efi', 'gnu-efi', '', d)}"

SRC_URI_append = " \
                  file://0001-Workaround-remove-handling-of-custom-cmdline.patch \
		  file://0002-Add-network.target-dependency-in-systemd-timesyncd.patch \
                 "

# Needed to be able to find gnu-efi headers/libs
EXTRA_OECONF += "--with-efi-includedir=${STAGING_INCDIR} \
                 --with-efi-ldsdir=${STAGING_LIBDIR} \
                 --with-efi-libdir=${STAGING_LIBDIR}"

inherit deploy

do_deploy() {
    if [ -f ${B}/linux*.efi.stub ] ; then
        install ${B}/linux*.efi.stub ${DEPLOYDIR}
    fi
}
addtask deploy before do_build after do_compile
