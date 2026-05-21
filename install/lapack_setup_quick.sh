#!/bin/bash

umask 0022
set -x

if [[ -z $lapack_therock_version ]]; then
    echo "Error: LAPACK version name has not been set."
    exit 1
fi

BASE_DIR=${BASE_PREFIX}
LAPACK_VERSION=${lapack_therock_version}
ROCM_VERSION=${version_name}
MODULE_DIR="${BASE_DIR}/modulefiles/${release_name}/lapack"
INSTALL_DIR="${BASE_DIR}/lapack/${lapack_therock_version}-${version_name}"

mkdir -p ${INSTALL_DIR}
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory '${INSTALL_DIR}'."
        exit 1
fi

mkdir -p ~/tmp/
mkdir -p ~/tmp/build-lapack
cd ~/tmp/build-lapack
# Download sources
#curl -L -O https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v${LAPACK_VERSION}.tar.gz
tar -xf ${BASE_DIR}/../cache/v${LAPACK_VERSION}.tar.gz
cd lapack-${LAPACK_VERSION}
mkdir build
cd build
# ATTENTION: We need to unset the PrgEnv env variable for THEROCK. Otherwise Lapack's build system will detect the CPE environment and
# pass the compiler flags matching the PrgEnv, which are wrong for THEROCK.
unset PE_ENV
VERBOSE=1 cmake \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
    -DCMAKE_C_COMPILER=mpicc \
    -DCMAKE_CXX_COMPILER=mpic++ \
    -DCMAKE_Fortran_COMPILER=mpifort \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=ON \
    -DBLAS++=OFF \
    -DCBLAS=ON \
    -DLAPACK++=OFF \
    -DLAPACKE=ON \
    -DLAPACKE_BUILD_COMPLEX=ON \
    -DLAPACKE_BUILD_COMPLEX16=ON \
    -DLAPACKE_BUILD_DOUBLE=ON \
    -DLAPACKE_BUILD_SINGLE=ON \
    -DBUILD_TESTING=OFF \
    ..
make -j12
make install

mkdir -p ${MODULE_DIR}
MODULE_FILE="${MODULE_DIR}/${LAPACK_VERSION}.lua"
echo "whatis(\"Name: lapack\")"                                              > $MODULE_FILE
echo "whatis(\"Version: ${LAPACK_VERSION}\")"                               >> $MODULE_FILE
echo "whatis(\"Category: library\")"                                        >> $MODULE_FILE
echo "whatis(\"Description: Library of Fortran subroutines for solving the most commonly occurring problems in numerical linear algebra.\")"  >> $MODULE_FILE
echo "whatis(\"URL: https://netlib.org/lapack/\")"                          >> $MODULE_FILE
echo ""                                                                     >> $MODULE_FILE
echo "local base = \"$(echo "$INSTALL_DIR" | sed 's|//|/|g')\""             >> $MODULE_FILE
echo ""                                                                     >> $MODULE_FILE
echo "prepend_path(\"LD_LIBRARY_PATH\", pathJoin(base, \"lib\"))"           >> $MODULE_FILE
echo "prepend_path(\"LIBRARY_PATH\", pathJoin(base, \"lib\"))"              >> $MODULE_FILE
echo "prepend_path(\"PKG_CONFIG_PATH\", pathJoin(base, \"lib/pkgconfig\"))" >> $MODULE_FILE
echo "setenv(\"LAPACK_DIR\",base)"                                          >> $MODULE_FILE
echo "setenv(\"LAPACK_ROOT\",base)"                                         >> $MODULE_FILE
echo "setenv(\"BLAS_DIR\",base)"                                            >> $MODULE_FILE
echo "setenv(\"BLAS_ROOT\",base)"                                           >> $MODULE_FILE
