#!/bin/bash

# GPU architecture is set by the orchestrator (install.therock.sh). Default
# to gfx90a if this script is sourced standalone, to preserve historical
# behaviour. Consumed by --offload-arch in the cxxflags written into the
# rocm-libs modulefile.
: "${GPU_ARCH:=gfx90a}"

INSTALL_DIR="${BASE_PREFIX}/therock/${version_name}"

cd ${INSTALL_DIR}
tar -xf ${CACHE_DIR}/${THRUST_RELEASE}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract ${THRUST_RELEASE}."
    exit 1
fi
tar -xf ${CACHE_DIR}/${ROCPRIM_RELEASE}
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract ${ROCPRIM_RELEASE}."
    exit 1
fi

cxxflags="-Wall -Wextra -O3 -std=c++20 --hipstdpar"
cxxflags="${cxxflags} --hipstdpar-path=$INSTALL_DIR/include/thrust/system/hip/hipstdpar"
cxxflags="${cxxflags} --hipstdpar-thrust-path=$INSTALL_DIR/include"
cxxflags="${cxxflags} --hipstdpar-prim-path=$INSTALL_DIR/include"
cxxflags="${cxxflags} --offload-arch=${GPU_ARCH}"

MODULE_DIR="${BASE_PREFIX}/modulefiles/${release_name}/rocm-libs"
mkdir -p ${MODULE_DIR}
MODULE_FILE="${MODULE_DIR}/${rocm_libs_version}.lua"


echo "whatis(\"Name: thrust and rocprim\")"                                          > $MODULE_FILE
echo "whatis(\"Version: ${rocm_libs_version}\")"                      >> $MODULE_FILE
echo "whatis(\"Category: library\")"                                     >> $MODULE_FILE

echo "local base = \"${INSTALL_DIR}\""                                   >> $MODULE_FILE
echo "local cxxflags = \"${cxxflags}\""                                   >> $MODULE_FILE

echo ""                                                                  >> $MODULE_FILE
echo "prepend_path(\"LD_LIBRARY_PATH\", pathJoin(base, \"lib\"))"        >> $MODULE_FILE
echo "prepend_path(\"LIBRARY_PATH\", pathJoin(base, \"lib\"))"           >> $MODULE_FILE
echo "prepend_path(\"C_INCLUDE_PATH\", pathJoin(base, \"include\"))"     >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include\"))" >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include/thrust\"))" >> $MODULE_FILE
echo "prepend_path(\"CPLUS_INCLUDE_PATH\", pathJoin(base, \"include/rocprim\"))" >> $MODULE_FILE
echo "prepend_path(\"CPATH\", pathJoin(base, \"include\"))"              >> $MODULE_FILE
echo "prepend_path(\"INCLUDE\", pathJoin(base, \"include\"))"            >> $MODULE_FILE
echo "prepend_path(\"PATH\", pathJoin(base, \"bin\"))"                   >> $MODULE_FILE
echo "setenv(\"CXXFLAGS\",cxxflags)"                                      >> $MODULE_FILE


