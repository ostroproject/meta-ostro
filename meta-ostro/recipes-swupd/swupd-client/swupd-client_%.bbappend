FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

inherit systemd

# Make swupd "stateful" by letting it update files in /etc.
PACKAGECONFIG_remove = "stateless"

SRC_URI_append = "file://0001-Disable-boot-file-heuristics.patch \
                  file://efi_combo_updater.sh \
                  file://ostroprojectorg.key \
                  ${@ 'file://efi-combo-trigger.service' if ${OSTRO_USE_DSK_IMAGES} else ''} \
                 "

RDEPENDS_${PN}_class-target_append = "${@ ' gptfdisk' if ${OSTRO_USE_DSK_IMAGES} else '' }"
DEPENDS_${PN}_append = " xattr-native"

# Get rid of check-update entirely, otherwise we cannot enable
# auto-activation.
SYSTEMD_SERVICE_${PN}_remove = "check-update.timer check-update.service"

# Optionally add our efi-combo-trigger.
SYSTEMD_SERVICE_${PN} += "${@ 'efi-combo-trigger.service' if ${OSTRO_USE_DSK_IMAGES} else ''}"

# And activate it.
SYSTEMD_AUTO_ENABLE_${PN} = "enable"

SWUPD_VERSION_URL ?= "https://download.ostroproject.org/updates/ostro-os/milestone/${MACHINE}/ostro-image-swupd"
SWUPD_CONTENT_URL ?= "https://download.ostroproject.org/updates/ostro-os/milestone/${MACHINE}/ostro-image-swupd"
SWUPD_PINNED_PUBKEY ?= "${datadir}/clear/update-ca/ostroproject.key"

do_install_append () {
    if [ "${OSTRO_USE_DSK_IMAGES}" = "True" ]; then
        install -m 0744 ${WORKDIR}/efi_combo_updater.sh ${D}/usr/bin/
        install -d ${D}/${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/efi-combo-trigger.service ${D}/${systemd_system_unitdir}
    fi

    # Don't install and enable check-update.timer by default
    rm -f ${D}/${systemd_system_unitdir}/check-update.* ${D}/${systemd_system_unitdir}/multi-user.target.wants/check-update.*

    install -d ${D}${datadir}/clear/update-ca
    install -m 0644 ${WORKDIR}/ostroprojectorg.key ${D}${datadir}/clear/update-ca/ostroproject.key
}

pkg_postinst_${PN}_append () {
    # Setting a label explicitly on the directory prevents it
    # from inheriting other undesired attributes like security.SMACK64TRANSMUTE
    # from upper folders (see xattr-images.bbclass for details).
    if ${@bb.utils.contains('DISTRO_FEATURES', 'smack', 'true', 'false', d)}; then
       install -d $D/var/lib/swupd
       setfattr -n security.SMACK64 -v "_" $D/var/lib/swupd
    fi
}
