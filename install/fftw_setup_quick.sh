#!/bin/bash


if [[ -z $fftw_therock_version ]]; then
    echo "Error: FFTW version name has not been set."
    exit 1
fi

if [[ -z $mpich_therock_version ]]; then
        echo "Error: MPICH version name has not been set, needed to create the hdf5-parallel module."
        exit 1
fi

INSTALL_DIR="${BASE_PREFIX}/fftw/${fftw_therock_version}-${version_name}"
mkdir -p ${INSTALL_DIR}
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory '${INSTALL_DIR}'."
        exit 1
fi

CONFIG_OPTIONS=" --prefix=${INSTALL_DIR} --enable-shared -disable-static --enable-threads --enable-openmp --enable-mpi --enable-sse2 --enable-avx --enable-avx2 "
mkdir -p $TMPDIR/tmp.fftw
rm -rf $TMPDIR/tmp.fftw/build-fftw
mkdir $TMPDIR/tmp.fftw/build-fftw && cd $TMPDIR/tmp.fftw/build-fftw
tar -xvf $CACHE_DIR/${FFTW_RELEASE}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract '${FFTW_RELEASE}'."
    exit 1
fi
cd ${fftw_release_dir}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to change directory to '${fftw_release_dir}'."
    exit 1
fi

CC=mpicc FC=mpifort CXX=mpic++ F77=mpif77 ./configure ${CONFIG_OPTIONS}
# Workaround for bugfix in libtool: https://github.com/HDFGroup/hdf5/issues/366
sed -i 's/wl=""/wl="-Wl,"/g;s/pic_flag=""/pic_flag=" -fPIC -DPIC"/g' libtool
make -j12 && make install


MODULE_DIR="${BASE_PREFIX}/modulefiles/${release_name}/fftw"
if [[ -z $MODULE_DIR ]]; then
    echo "Error: Module directory for FFTW has not been set."
    exit 1
fi
mkdir -p ${MODULE_DIR}
MODULE_FILE="${MODULE_DIR}/${fftw_therock_version}.lua"
echo "whatis(\"Name: fftw\")"                                             > $MODULE_FILE
echo "whatis(\"Version: ${FFTW_VERSION}\")"                              >> $MODULE_FILE
echo "whatis(\"Category: library\")"                                     >> $MODULE_FILE
echo "whatis(\"Description: High-performance data management and storage suite\")"  >> $MODULE_FILE
echo "whatis(\"URL: https://www.hdfgroup.org/solutions/hdf5/\")"         >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "local base = \"${INSTALL_DIR}\""                                   >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "depends_on(\"mpich/${mpich_therock_version}\")"                    >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "prepend_path(\"LD_LIBRARY_PATH\", pathJoin(base, \"lib\"))"        >> $MODULE_FILE
echo "prepend_path(\"LIBRARY_PATH\", pathJoin(base, \"lib\"))"           >> $MODULE_FILE
echo "prepend_path(\"C_INCLUDE_PATH\", pathJoin(base, \"include\"))"     >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include\"))" >> $MODULE_FILE
echo "prepend_path(\"CPATH\", pathJoin(base, \"include\"))"              >> $MODULE_FILE
echo "prepend_path(\"INCLUDE\", pathJoin(base, \"include\"))"            >> $MODULE_FILE
echo "prepend_path(\"PATH\", pathJoin(base, \"bin\"))"                   >> $MODULE_FILE
echo "setenv(\"FFTW_DIR\",base)"                                         >> $MODULE_FILE
