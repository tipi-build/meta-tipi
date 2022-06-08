# TODO: Set up the tipi HOME_DIR inside yocto
# TODO: Generate an environment for remote tipi build for yocto from the toolchain file + target name
# TODO: Provide chrpath, diffstat, gawk
# TODO: Provide a tipi yocto --install-layer feature
#
#
# Path to the tipi project 
OETIPI_SOURCEPATH ??= "${S}"

DEPENDS_prepend = "tipi-native "
B = "${S}"

python() {
    # C/C++ Compiler (without cpu arch/tune arguments)
    if not d.getVar('OETIPI_C_COMPILER'):
        cc_list = d.getVar('CC').split()
        if cc_list[0] == 'ccache':
            d.setVar('OETIPI_C_COMPILER_LAUNCHER', cc_list[0])
            d.setVar('OETIPI_C_COMPILER', cc_list[1])
        else:
            d.setVar('OETIPI_C_COMPILER', cc_list[0])

    if not d.getVar('OETIPI_CXX_COMPILER'):
        cxx_list = d.getVar('CXX').split()
        if cxx_list[0] == 'ccache':
            d.setVar('OETIPI_CXX_COMPILER_LAUNCHER', cxx_list[0])
            d.setVar('OETIPI_CXX_COMPILER', cxx_list[1])
        else:
            d.setVar('OETIPI_CXX_COMPILER', cxx_list[0])
}
OETIPI_AR ?= "${AR}"

# Compiler flags
OETIPI_HOME_DIR = "~"
OETIPI_C_FLAGS ?= "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS} ${CFLAGS}"
OETIPI_CXX_FLAGS ?= "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS} ${CXXFLAGS}"
OETIPI_C_FLAGS_RELEASE ?= "-DNDEBUG"
OETIPI_CXX_FLAGS_RELEASE ?= "-DNDEBUG"
OETIPI_C_LINK_FLAGS ?= "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS} ${CPPFLAGS} ${LDFLAGS}"
OETIPI_CXX_LINK_FLAGS ?= "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS} ${CXXFLAGS} ${LDFLAGS}"
CXXFLAGS += "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS}"
CFLAGS += "${HOST_CC_ARCH} ${TOOLCHAIN_OPTIONS}"

OETIPI_C_COMPILER_LAUNCHER ?= ""
OETIPI_CXX_COMPILER_LAUNCHER ?= ""

OETIPI_RPATH ?= ""
OETIPI_PERLNATIVE_DIR ??= ""
OETIPI_EXTRA_ROOT_PATH ?= ""

OETIPI_FIND_ROOT_PATH_MODE_PROGRAM = "ONLY"
OETIPI_FIND_ROOT_PATH_MODE_PROGRAM_class-native = "BOTH"

EXTRA_OETIPI_append = " ${PACKAGECONFIG_CONFARGS}"

#export CMAKE_BUILD_PARALLEL_LEVEL
#CMAKE_BUILD_PARALLEL_LEVEL_task-compile = "${@oe.utils.parallel_make(d, False)}"
#CMAKE_BUILD_PARALLEL_LEVEL_task-install = "${@oe.utils.parallel_make(d, True)}"

OETIPI_TARGET_COMPILE ?= "all"
OETIPI_TARGET_INSTALL ?= "install"

def map_host_os_to_system_name(host_os):
    if host_os.startswith('mingw'):
        return 'Windows'
    if host_os.startswith('linux'):
        return 'Linux'
    return host_os

# CMake expects target architectures in the format of uname(2),
# which do not always match TARGET_ARCH, so all the necessary
# conversions should happen here.
def map_host_arch_to_uname_arch(host_arch):
    if host_arch == "powerpc":
        return "ppc"
    if host_arch == "powerpc64":
        return "ppc64"
    return host_arch

tipi_do_generate_toolchain_file() {
  current_environments_dir=$(ls -td ${OETIPI_HOME_DIR}/.tipi/environments/*/ | head -1)
	if [ "${BUILD_SYS}" = "${HOST_SYS}" ]; then
		tipi_crosscompiling="set( CMAKE_CROSSCOMPILING FALSE )"
	fi
	cat > ${current_environments_dir}/linux-${HOST_SYS}.cmake <<EOF
# CMake system name must be something like "Linux".
# This is important for cross-compiling.
$tipi_crosscompiling
set( CMAKE_SYSTEM_NAME ${@map_host_os_to_system_name(d.getVar('HOST_OS'))} )
set( CMAKE_SYSTEM_PROCESSOR ${@map_host_arch_to_uname_arch(d.getVar('HOST_ARCH'))} )
set( CMAKE_C_COMPILER ${OETIPI_C_COMPILER} )
set( CMAKE_CXX_COMPILER ${OETIPI_CXX_COMPILER} )
set( CMAKE_C_COMPILER_LAUNCHER ${OETIPI_C_COMPILER_LAUNCHER} )
set( CMAKE_CXX_COMPILER_LAUNCHER ${OETIPI_CXX_COMPILER_LAUNCHER} )
set( CMAKE_ASM_COMPILER ${OETIPI_C_COMPILER} )
find_program( CMAKE_AR ${OETIPI_AR} DOC "Archiver" REQUIRED )

set( CMAKE_C_FLAGS "${OETIPI_C_FLAGS}" CACHE STRING "CFLAGS" )
set( CMAKE_CXX_FLAGS "${OETIPI_CXX_FLAGS}" CACHE STRING "CXXFLAGS" )
set( CMAKE_ASM_FLAGS "${OETIPI_C_FLAGS}" CACHE STRING "ASM FLAGS" )
set( CMAKE_C_FLAGS_RELEASE "${OETIPI_C_FLAGS_RELEASE}" CACHE STRING "Additional CFLAGS for release" )
set( CMAKE_CXX_FLAGS_RELEASE "${OETIPI_CXX_FLAGS_RELEASE}" CACHE STRING "Additional CXXFLAGS for release" )
set( CMAKE_ASM_FLAGS_RELEASE "${OETIPI_C_FLAGS_RELEASE}" CACHE STRING "Additional ASM FLAGS for release" )
set( CMAKE_C_LINK_FLAGS "${OETIPI_C_LINK_FLAGS}" CACHE STRING "LDFLAGS" )
set( CMAKE_CXX_LINK_FLAGS "${OETIPI_CXX_LINK_FLAGS}" CACHE STRING "LDFLAGS" )

# only search in the paths provided so cmake doesnt pick
# up libraries and tools from the native build machine
set( CMAKE_FIND_ROOT_PATH ${STAGING_DIR_HOST} ${STAGING_DIR_NATIVE} ${CROSS_DIR} ${OETIPI_PERLNATIVE_DIR} ${OETIPI_EXTRA_ROOT_PATH} ${EXTERNAL_TOOLCHAIN} ${HOSTTOOLS_DIR})
set( CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ${OETIPI_FIND_ROOT_PATH_MODE_PROGRAM} )
set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
set( CMAKE_PROGRAM_PATH "/" )

# Use qt.conf settings
set( ENV{QT_CONF_PATH} ${WORKDIR}/qt.conf )

# We need to set the rpath to the correct directory as cmake does not provide any
# directory as rpath by default
set( CMAKE_INSTALL_RPATH ${OETIPI_RPATH} )

# Use RPATHs relative to build directory for reproducibility
set( CMAKE_BUILD_RPATH_USE_ORIGIN ON )

# Use our cmake modules
list(APPEND CMAKE_MODULE_PATH "${STAGING_DATADIR}/cmake/Modules/")

# add for non /usr/lib libdir, e.g. /usr/lib64
set( CMAKE_LIBRARY_PATH ${libdir} ${base_libdir})

# add include dir to implicit includes in case it differs from /usr/include
list(APPEND CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES ${includedir})
list(APPEND CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES ${includedir})

EOF
}

addtask generate_toolchain_file after do_patch before do_configure

tipi_do_configure() {
	if [ "${OETIPI_BUILDPATH}" ]; then
		bbnote "cmake.bbclass no longer uses OETIPI_BUILDPATH.  The default behaviour is now out-of-tree builds with B=WORKDIR/build."
	fi

	if [ "${S}" != "${B}" ]; then
		rm -rf ${B}
		mkdir -p ${B}
		cd ${B}
#else
#		find ${S}/build/linux-${HOST_SYS}/bin -name CMakeFiles -or -name Makefile -or -name tipi_install.cmake -or -name CMakeCache.txt -delete
	fi

	tipi --verbose \
    --target linux-${HOST_SYS} \
	  ${OETIPI_SOURCEPATH} \
    -- \
	  -DCMAKE_INSTALL_PREFIX:PATH=${D}${prefix} \
	  -DCMAKE_INSTALL_BINDIR:PATH=${@os.path.relpath(d.getVar('bindir'), d.getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_SBINDIR:PATH=${@os.path.relpath(d.getVar('sbindir'), d.getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_LIBEXECDIR:PATH=${@os.path.relpath(d.getVar('libexecdir'), d.getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_SYSCONFDIR:PATH=${sysconfdir} \
	  -DCMAKE_INSTALL_SHAREDSTATEDIR:PATH=${@os.path.relpath(d.getVar('sharedstatedir'), d.  getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_LOCALSTATEDIR:PATH=${localstatedir} \
	  -DCMAKE_INSTALL_LIBDIR:PATH=${@os.path.relpath(d.getVar('libdir'), d.getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_INCLUDEDIR:PATH=${@os.path.relpath(d.getVar('includedir'), d.getVar('prefix') + '/')} \
	  -DCMAKE_INSTALL_DATAROOTDIR:PATH=${@os.path.relpath(d.getVar('datadir'), d.getVar('prefix') + '/')} \
	  -DPYTHON_EXECUTABLE:PATH=${PYTHON} \
	  -DPython_EXECUTABLE:PATH=${PYTHON} \
	  -DPython3_EXECUTABLE:PATH=${PYTHON} \
	  -DLIB_SUFFIX=${@d.getVar('baselib').replace('lib', '')} \
	  -DCMAKE_INSTALL_SO_NO_EXE=0 \
	  -DCMAKE_TOOLCHAIN_FILE=${WORKDIR}/${HOST_SYS}.cmake \
	  -DCMAKE_NO_SYSTEM_FROM_IMPORTED=1 \
	  ${EXTRA_OETIPI} \
	  -Wno-dev
}

# Then run do_compile again
#tipi_runtipi_build() {
#	bbnote ${DESTDIR:+DESTDIR=${DESTDIR} } tipi --build '${B}' "$@" -- ${EXTRA_OETIPI_BUILD}
#	eval ${DESTDIR:+DESTDIR=${DESTDIR} } tipi --build '${B}' "$@" -- ${EXTRA_OETIPI_BUILD}
#}

#tipi_do_compile()  {
#	tipi_runtipi_build --target ${OETIPI_TARGET_COMPILE}
#}

do_compile[noexec] = "1"

tipi_do_install() {
	DESTDIR='${D}' oe_runmake -C ${S}/build/linux-${HOST_SYS}/bin install
}

EXPORT_FUNCTIONS do_configure do_install do_generate_toolchain_file
