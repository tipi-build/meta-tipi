SUMMARY = "tipi.build"
DESCRIPTION ="This recipe provides the tipi.build local+remote compiler"
LICENSE = "CLOSED"
SRC_URI = "https://github.com/tipi-build/cli/releases/download/v0.0.31/tipi-v0.0.31-linux-x86_64.zip;subdir=${BP}"
SRC_URI[sha256sum] = "32881944d62876f13791bc56daffb9c4004ed7acc1951485733473fe7b5f9b91"

inherit native

do_configure[noexec] = "1"
do_compile[noexec] = "1"


FILES_${PN} = "/"

# Install the files to ${D}
do_install () {
  echo "Prefix is : ${prefix}" 
  chmod +x bin/tipi
    # Do it carefully
    [ -d "${S}" ] || exit 1
    if [ -z "$(ls -A ${S})" ]; then
        bbfatal bin_package has nothing to install. Be sure the SRC_URI unpacks into S.
    fi
    cd ${S}
    mkdir -p ${D}${prefix}
    tar --no-same-owner --exclude='./patches' --exclude='./.pc' -cpf - . \
        | tar --no-same-owner -xpf - -C ${D}${prefix}
}

