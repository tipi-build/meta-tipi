SUMMARY = "Simple example of a project built with tipi"
DESCRIPTION = "A tipi built project"
HOMEPAGE = "https://github.com/tipi-build/simple-example"
BUGTRACKER = "https://github.com/tipi-build/simple-example/issues"
LICENSE = "CLOSED"

SECTION = "console/utils"

SRC_URI = " \
  https://github.com/tipi-build/simple-example/archive/0e529c75e983c0b03eac1c5fa63e810c3c451f3d.zip  \
"
S = "${WORKDIR}/simple-example-0e529c75e983c0b03eac1c5fa63e810c3c451f3d"

# https://github.com/${BPN}/${BPN}/releases/download/v${PV}/${BP}.tar.gz
SRC_URI[sha256sum] = "cf4973ed9be15d0704c62262d498d2f0931c8ca629ce5de0d9050764c74cfd95"
UPSTREAM_CHECK_URI = "https://github.com/tipi-build/simple-example/releases"

inherit tipi

do_install_append() {
  install -d ${D}${bindir}
  install -m 0755 ${B}/build/linux-${HOST_SYS}/bin/simple-app ${D}${bindir} 
}
