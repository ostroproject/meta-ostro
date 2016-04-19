FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS_append = " systemd"

SRC_URI += " \
           file://config \
           file://0001-sol-oic-gen.py-fix-missing-argument-TypeError.patch \
"

INSANE_SKIP_${PN}-dev += "dev-elf"

do_configure_prepend() {
    cp ${WORKDIR}/config ${S}/.config
}
