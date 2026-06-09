#!/bin/bash

if [[ -z $pnetcdf_therock_version ]]; then
    echo "Error: PnetCDF version name has not been set."
    exit 1
fi

if [[ -z $hdf5_therock_version ]]; then
        echo "Error: HDF5 version name has not been set, needed for the pnetcdf module file."
        exit 1
fi

INSTALL_DIR="${BASE_PREFIX}/pnetcdf/${pnetcdf_therock_version}-${version_name}"
if [[ -z $fftw_therock_version ]]; then
    echo "Error: FFTW version name has not been set."
    exit 1
fi

CONFIG_OPTIONS=" --prefix=${INSTALL_DIR} --enable-shared --disable-static "
mkdir -p $TMPDIR/tmp.pnetcdf
rm -rf $TMPDIR/tmp.pnetcdf/build-pnetcdf
mkdir $TMPDIR/tmp.pnetcdf/build-pnetcdf && cd $TMPDIR/tmp.pnetcdf/build-pnetcdf
tar -xvf $CACHE_DIR/${PNETCDF_RELEASE}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract ${PNETCDF_RELEASE}."
    exit 1
fi
cd ${pnetcdf_release_dir}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to change directory to '${pnetcdf_release_dir}'."
    exit 1
fi

CC=mpicc FC=mpifort F77=mpif77 CXX=mpicxx ./configure ${CONFIG_OPTIONS}
## Workaround for bugfix in libtool: https://github.com/HDFGroup/hdf5/issues/366
sed -i 's/wl=""/wl="-Wl,"/g;s/pic_flag=""/pic_flag=" -fPIC -DPIC"/g' libtool
make -j12 && make install

MODULE_DIR="${BASE_PREFIX}/modulefiles/${release_name}/pnetcdf"
mkdir -p ${MODULE_DIR}
MODULE_FILE="${MODULE_DIR}/${pnetcdf_therock_version}.lua"
echo "whatis(\"Name: pnetcdf\")"                                          > $MODULE_FILE
echo "whatis(\"Version: ${pnetcdf_therock_version}\")"                      >> $MODULE_FILE
echo "whatis(\"Category: library\")"                                     >> $MODULE_FILE
echo "whatis(\"Description: High-performance data management and storage suite\")"  >> $MODULE_FILE
echo "whatis(\"URL: https://www.hdfgroup.org/solutions/hdf5/\")"         >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "local base = \"${INSTALL_DIR}\""                                   >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "depends_on(\"hdf5-parallel/${hdf5_therock_version}\")"             >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "prepend_path(\"LD_LIBRARY_PATH\", pathJoin(base, \"lib\"))"        >> $MODULE_FILE
echo "prepend_path(\"LIBRARY_PATH\", pathJoin(base, \"lib\"))"           >> $MODULE_FILE
echo "prepend_path(\"C_INCLUDE_PATH\", pathJoin(base, \"include\"))"     >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include\"))" >> $MODULE_FILE
echo "prepend_path(\"CPATH\", pathJoin(base, \"include\"))"              >> $MODULE_FILE
echo "prepend_path(\"INCLUDE\", pathJoin(base, \"include\"))"            >> $MODULE_FILE
echo "prepend_path(\"PATH\", pathJoin(base, \"bin\"))"                   >> $MODULE_FILE
echo "setenv(\"PNETCDF_DIR\",base)"                                      >> $MODULE_FILE
