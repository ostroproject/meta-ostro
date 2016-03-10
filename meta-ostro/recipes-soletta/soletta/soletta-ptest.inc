inherit ptest

SRC_URI += "file://run-ptest \
            file://add-fbp-passfail-result.patch \
           "

do_compile_ptest() {
        oe_runmake CFLAGS="--sysroot=${STAGING_DIR_TARGET} -pthread -lpcre" TARGETCC="${CC}" TARGETAR="${AR}" "tests"

}
do_install_ptest () {
        mkdir -p ${D}/${PTEST_PATH}/src
        cp -rf ${S}/build/stage/test ${D}/${PTEST_PATH}/src/
        cp -f ${S}/data/scripts/suite.py ${D}/${PTEST_PATH}
        cp -rf ${S}/src/test-fbp ${D}/${PTEST_PATH}/src/
        cp -f ${S}/tools/run-fbp-tests ${D}/${PTEST_PATH}

}

