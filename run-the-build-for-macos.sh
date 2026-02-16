#!/usr/bin/env bash

this_dir=$(cd -P $(dirname $0) && pwd)
big-msg(){ printf "\033[1;37m==> %s\033[0m\n" "$*" ; }
big-msg "Checking CC is defined"
if [[ -z ${CC} ]] ; then
    echo "The environment variable CC must be define."
    echo "See perftools/src/Notes_MacOS.md"
    exit 1
fi

perftools_install_dir=${this_dir}/perftools_install_dir
perftools_LIBRARY_PATH=${perftools_install_dir}/lib
big-msg "Building libhpcoperf.a and s.jio-prof.a in ${perftools_LIBRARY_PATH}"
if ! make -C ./perftools/src INSTALL_DIR=${perftools_install_dir} install ; then
    echo "Failed to build and install perftools"
    exit 1
fi

big-msg "Checking spack env"
if [[ "${SPACK_ENV}" != */rpn-spack-env ]] ; then
    echo "The spack environment rpn-spack-env must be activated with \`spacktivate rpn-spack-env\`"
    exit 1
fi

midas_src_dir=${this_dir}/midas
midas_build_dir=${this_dir}/midas-build
midas_install_dir=${this_dir}/midas-install
big-msg "Checking if rttov_INSTALLDIR is set or if the rttov part of the CMakeLists.txt is commented"
if [[ -z ${rttov_INSTALLDIR} ]] ; then
    if ! grep '# set(rttov_LIBRARY_PATH ' ${midas_src_dir}/CMakeLists.txt >/dev/null ; then
        echo "You should go comment out lines 44 to 51 in ${midas_src_dir}/CMakeLists.txt"
        echo "Or delete this part of the script."
        exit 1
    fi
fi

export perftools_LIBRARY_PATH
cmd=(cmake -S ${midas_src_dir} -B ${midas_build_dir})
big-msg "${cmd[*]}"
if ! "${cmd[@]}" ; then
    echo "Failed to run cmake"
    exit 1
fi

cmd=(cmake --build ${midas_build_dir})
big-msg "${cmd[*]}"
if ! "${cmd[@]}" ; then
    echo "Failed to build"
    big-msg "If it stopped with
	   .../midas-benchmarks/midas/src/modules/rttovInterfaces_mod.F90:14:2:

	      14 | #include \"rttov_user_options_checkinput.interface\"
	         |  1~~~~~~~~~~~~~~~~~~~~~~~~~~
	   Fatal Error: rttov_coeffname.interface: No such file or directory
	Then you go as far as I did :)
        "

    exit 1
fi

cmd=(cmake --install ${midas_build_dir} --prefix ${midas_install_dir})
big-msg "${cmd[*]}"
if ! "${cmd[@]}" ; then
    echo "Failed to install"
    exit 1
fi
