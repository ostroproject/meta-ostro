FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS_append = " systemd"

SRC_URI += " file://config"

# Restore "no strip, no debug split" behavior after
# recent OE-core packaging change. See https://github.com/solettaproject/meta-soletta/issues/88
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

INSANE_SKIP_${PN}-dev += "dev-elf"

do_configure_prepend() {
    cp ${WORKDIR}/config ${S}/.config
}
