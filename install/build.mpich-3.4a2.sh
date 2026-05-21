#!/bin/bash
#set -x

if [[ -z $mpich_therock_version ]]; then
        echo "Error: MPICH version name has not been set."
        exit 1
fi
# GPU architecture is set by the orchestrator (install.therock.sh). Default
# to gfx90a if this script is sourced standalone, to preserve historical
# behaviour. Consumed by --with-hip-sm below.
: "${GPU_ARCH:=gfx90a}"
mpich_dest_dir="${BASE_PREFIX}/mpich/${mpich_therock_version}-${version_name}"
mkdir -p ${mpich_dest_dir}
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory '${mpich_dest_dir}'."
        exit 1
fi

libfabric_dir=$(pkg-config --variable=prefix libfabric)
mpich_dir=${MPICH_DIR_CCE}
if [[ -z $libfabric_dir || -z $mpich_dir ]]; then
        echo "Error: cannot find libfabric or mpich directories"
        exit 1
fi

## set up modules and frankenstein the environment
cd ${TMPDIR}/tmp.therock/template/lmod/modulefiles/core
if [[ ! -f  mpich-3.4a2.lua ]]; then
        echo "Error: mpich-3.4a2.lua does not exist."
        exit 1
fi

CRAY_MPICH_PREFIX=$MPICH_DIR_CCE
MPICH_CCE=$(dirname $CRAY_MPICH_PREFIX)
CRAY_MPICH_BASEDIR=$(dirname $MPICH_CCE)
CRAY_MPICH_ROOTDIR=$(dirname $CRAY_MPICH_BASEDIR)
CRAY_MPICH_VERSION=$(basename $CRAY_MPICH_ROOTDIR)

sed -i "s%__CRAY_MPICH_VER__%${CRAY_MPICH_VERSION}%g" mpich-3.4a2.lua
sed -i "s%__CRAY_MPICH_VERSION__%${CRAY_MPICH_VERSION}%g" mpich-3.4a2.lua
sed -i "s%__CRAY_MPICH_ROOTDIR__%${CRAY_MPICH_ROOTDIR}%g" mpich-3.4a2.lua
sed -i "s%__CRAY_MPICH_BASEDIR__%${CRAY_MPICH_BASEDIR}%g" mpich-3.4a2.lua
sed -i "s%__CRAY_MPICH_DIR__%${MPICH_DIR_CCE}%g" mpich-3.4a2.lua
sed -i "s%__CRAY_MPICH_PREFIX__%${MPICH_DIR_CCE}%g" mpich-3.4a2.lua
sed -i "s%__MPICH_DIR__%${MPICH_DIR_CCE}%g" mpich-3.4a2.lua
sed -i "s%__MPICH_DEST_DIR__%${mpich_dest_dir}%g" mpich-3.4a2.lua
sed -i "s%__THEROCK_VERSION__%${version_name}%g" mpich-3.4a2.lua
mv mpich-3.4a2.lua mpich-3.4a2-${version_name}.lua
mkdir -p ${BASE_PREFIX}/modulefiles/${release_name}/mpich
cp mpich-3.4a2-${version_name}.lua ${BASE_PREFIX}/modulefiles/${release_name}/mpich/${mpich_therock_version}.lua

cd ${TMPDIR}/tmp.therock/template/bin
sed -i "s%__LIBFABRIC_DIR__%${libfabric_dir}%g" mpifort mpicc mpicxx
sed -i "s%__MPICH_DIR__%${mpich_dir}%g" mpifort mpicc mpicxx
sed -i "s%__MPICH_DEST_DIR__%${mpich_dest_dir}%g" mpifort mpicc mpicxx
sed -i "s%__THEROCK_DEST_DIR__%${therock_dest_dir}%g" mpifort mpicc mpicxx
mkdir -p ${mpich_dest_dir}/bin
cp ${TMPDIR}/tmp.therock/template/bin/* ${mpich_dest_dir}/bin

cd ${TMPDIR}/tmp.therock/template/lib/pkgconfig
sed -i "s%__MPICH_DIR__%${mpich_dir}%g" *.pc
sed -i "s%__MPICH_DEST_DIR__%${mpich_dest_dir}%g" *.pc
mkdir -p ${mpich_dest_dir}/lib/pkgconfig
cp -r ${TMPDIR}/tmp.therock/template/lib ${mpich_dest_dir}

#export LD_LIBRARY_PATH=${ROCM_PATH}/lib:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=${mpich_dest_dir}/lib:$LD_LIBRARY_PATH

mkdir -p ${TMPDIR}/tmp.therock/src && cd ${TMPDIR}/tmp.therock/src
tar -xf $CACHE_DIR/mpich-3.4a2.tar.gz
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to extract 'mpich-3.4a2.tar.gz'."
        exit 1
fi
cd ${TMPDIR}/tmp.therock/src/mpich-3.4a2
if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory '${TMPDIR}/tmp.therock/src/mpich-3.4a2'."
        exit 1
fi

export CC=$(which amdclang)
export CXX=$(which amdclang++)
export FC=$(which amdflang)
export F77=$(which amdflang)
#export F90=$(which amdflang)
#export F08=$(which amdflang)


mkdir -p build
cd build
rm -rf *

#fix to compile libtool test: set flags
#
# We disable the process manager entirely with --with-pm=no.
#
# Rationale: this install only ships the MPICH headers and libmpifort to
# ${mpich_dest_dir}; mpiexec / hydra_pmi_proxy are never copied into the final
# tree (see the cp commands below). The mpicc/mpifort/... wrappers (from
# template/bin) link against Cray MPICH (libmpi_cray) at runtime, and launching
# is done with srun (Cray PMI), not Hydra. So hydra is dead weight here.
#
# Skipping hydra also avoids a build failure on systems with modern Slurm
# headers (e.g. LUMI / Cray nodes). The top-level --without-slurm flag does
# NOT propagate to hydra's sub-configure (src/pm/hydra/configure), which
# autodetects /usr/include/slurm/slurm.h via AC_CHECK_HEADERS and then tries to
# build tools/bootstrap/external/slurm_query_node_list.c. That file declares
# `hostlist_t hostlist;` (an instance), but modern Slurm headers only
# forward-declare `struct hostlist` and define `typedef struct hostlist hostlist_t;`
# as an opaque type, so the variable has an incomplete type and the build fails:
#   error: variable has incomplete type 'hostlist_t' (aka 'struct hostlist')
#
# --with-pm=no tells MPICH to build no process manager at all, removing the
# src/pm/hydra subdir from the build and sidestepping the issue cleanly.
# --without-slurm is kept as documentation/defence in depth; it has no effect
# once no PM is built.
CFLAGS="-fPIC" \
CXXFLAGS="-fPIC" \
FCFLAGS="-fPIC" \
../configure \
	--prefix=${TMPDIR}/tmp.therock/mpich-3.4a2 \
	--enable-fortran=all \
	--enable-cxx \
	--with-device=ch4:ofi \
	--with-libfabric=${libfabric_dir} \
	--without-slurm \
	--with-pm=no \
	--with-hip=$ROCM_PATH \
	--with-hip-sm="${GPU_ARCH}" |& tee log.configure.txt
# Fix libtool for the AMD flang/clang drivers.
#
# Without this, the final shared-library link step (e.g. lib/libmpi.la) fails with:
#   flang-23: error: unknown argument: '--whole-archive'
#   flang-23: error: unknown argument: '--no-whole-archive'
#   flang-23: error: unknown argument: '-soname'
#   flang-23: error: no such file or directory: 'libmpi.so.0'
#
# Cause: libtool's per-tag table contains `wl=""` (empty linker-flag-passthrough
# prefix) and `pic_flag=""` for the amdflang/amdclang compilers, because
# configure couldn't autodetect those. With wl="" libtool hands raw linker
# options (--whole-archive, -soname, ...) directly to the compiler driver,
# which flang-23 doesn't understand. We rewrite every empty wl="" to "-Wl,"
# (so flags become -Wl,--whole-archive etc., which flang-23 *does* forward to
# the linker) and every empty pic_flag="" to "-fPIC -DPIC".
#
# MPICH's sub-configures (src/mpl, src/openpa, src/mpi/romio, ...) each emit
# their own libtool script, so we patch all of them, not just the top-level
# build/libtool.
find . -type f -name libtool -print0 | xargs -0 sed -i \
    -e 's/wl=""/wl="-Wl,"/g' \
    -e 's/pic_flag=""/pic_flag=" -fPIC -DPIC"/g'

make -j |& tee log.make.txt
make install |& tee log.install.txt

cp -r ${TMPDIR}/tmp.therock/mpich-3.4a2/include ${mpich_dest_dir}
mkdir -p ${mpich_dest_dir}/lib && cp ${TMPDIR}/tmp.therock/mpich-3.4a2/lib/libmpifort.* ${mpich_dest_dir}/lib
cd ${mpich_dest_dir}/lib && ln -sf ${MPICH_DIR_CCE}/lib/libmpi_cray.so ./libmpi.so.0
chmod go+rx ${mpich_dest_dir}/bin/*

#cd ${TMPDIR} && rm -rf ${TMPDIR}/tmp.therock

