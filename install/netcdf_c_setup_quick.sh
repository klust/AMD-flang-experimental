#!/bin/bash


if [[ -z $netcdf_c_therock_version ]]; then
        echo "Error: NetCDF C version name has not been set."
        exit 1
fi
INSTALL_DIR="${BASE_PREFIX}/netcdf_c/${netcdf_c_therock_version}-${version_name}"
mkdir -p ${INSTALL_DIR}
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory '${INSTALL_DIR}'."
        exit 1
fi

mkdir -p $TMPDIR/tmp.netcdf_c && cd $TMPDIR/tmp.netcdf_c
tar -xf $CACHE_DIR/$NETCDF_C_RELEASE
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to extract '$NETCDF_C_RELEASE'."
        exit 1
fi
cd $TMPDIR/tmp.netcdf_c/$netcdf_c_release_dir
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to change directory to '$netcdf_c_release_dir'."
        exit 1
fi

CONFIG_OPTIONS="  --prefix=${INSTALL_DIR} --enable-pnetcdf --enable-shared --disable-static --enable--disable-examples --disable-testsets --disable-byterange "
CC=mpicc FC=mpifort F77=mpif77 CXX=mpicxx CPPFLAGS=-I${HDF5_DIR}/include LDFLAGS=-L${HDF5_DIR}/lib ./configure ${CONFIG_OPTIONS}
sed -i 's/wl=""/wl="-Wl,"/g;s/pic_flag=""/pic_flag=" -fPIC -DPIC"/g' libtool
make -j12 && make install

MODULE_DIR="${BASE_PREFIX}/modulefiles/${release_name}/netcdf_c"
mkdir -p ${MODULE_DIR}
MODULE_FILE="${MODULE_DIR}/${netcdf_c_therock_version}.lua"
echo "whatis(\"Name: netcdf\")"                                          > $MODULE_FILE
echo "whatis(\"Version: ${netcdf_c_therock_version}\")"                     >> $MODULE_FILE
echo "whatis(\"Category: library\")"                                     >> $MODULE_FILE
echo "whatis(\"Description: High-performance data management and storage suite\")"  >> $MODULE_FILE
echo "whatis(\"URL: https://www.hdfgroup.org/solutions/hdf5/\")"         >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "local base = \"${INSTALL_DIR}\""                                   >> $MODULE_FILE
echo ""                                                                  >> $MODULE_FILE
echo "prepend_path(\"LD_LIBRARY_PATH\", pathJoin(base, \"lib\"))"        >> $MODULE_FILE
echo "prepend_path(\"LIBRARY_PATH\", pathJoin(base, \"lib\"))"           >> $MODULE_FILE
echo "prepend_path(\"C_INCLUDE_PATH\", pathJoin(base, \"include\"))"     >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include\"))" >> $MODULE_FILE
echo "prepend_path(\"CPATH\", pathJoin(base, \"include\"))"              >> $MODULE_FILE
echo "prepend_path(\"INCLUDE\", pathJoin(base, \"include\"))"            >> $MODULE_FILE
echo "prepend_path(\"PATH\", pathJoin(base, \"bin\"))"                   >> $MODULE_FILE
echo "setenv(\"NETCDF_DIR\",base)"                                       >> $MODULE_FILE
