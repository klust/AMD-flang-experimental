#! /bin/bash

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
rootdir="$(dirname $0)/.."

export CACHE_DIR="${rootdir}/cache"
mkdir -p "$CACHE_DIR"

cd "$CACHE_DIR" 

# Load software versions. We use an external file to guarantee consistency between the
# download script and the install script.
source ${rootdir}/install/source.set_versions.sh

# https://repo.radeon.com/rocm/misc/flang/therock-afar-23.2.1-gfx90a-7.13.0-7357b5084b.tar.bz2
[[ -f $THEROCK ]] || wget "https://repo.radeon.com/rocm/misc/flang/$THEROCK"

# MPICH: https://www.mpich.org/static/downloads/3.4a2/mpich-3.4a2.tar.gz
[[ -f $MPICH_RELEASE ]] || wget "https://www.mpich.org/static/downloads/$MPICH_VERSION/$MPICH_RELEASE"

# HDF5: https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.6/hdf5-1.14.6.tar.gz
[[ -f $HDF5_RELEASE ]] || ( wget "https://github.com/HDFGroup/hdf5/releases/download/hdf5_$HDF5_VERSION/hdf5-$HDF5_VERSION.tar.gz" ; mv "hdf5-$HDF5_VERSION.tar.gz" "$HDF5_RELEASE" )

# NetCDF: https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.3.tar.gz
[[ -f $NETCDF_C_RELEASE ]] || ( wget "https://github.com/Unidata/netcdf-c/archive/refs/tags/v$NETCDF_C_VERSION.tar.gz" ; mv "v$NETCDF_C_VERSION.tar.gz" "$NETCDF_C_RELEASE" )

# NetCDF-fortran: https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.2.tar.gz
[[ -f $NETCDF_FORTRAN_RELEASE ]] || ( wget "https://github.com/Unidata/netcdf-c/archive/refs/tags/v$NETCDF_FORTRAN_VERSION.tar.gz" ; mv "v$NETCDF_FORTRAN_VERSION.tar.gz" "$NETCDF_FORTRAN_RELEASE" )

# PnetCDF: https://parallel-netcdf.github.io/Release/pnetcdf-1.14.1.tar.gz
[[ -f $PNETCDF_RELEASE ]] || wget "https://parallel-netcdf.github.io/Release/$PNETCDF_RELEASE"

# FFTW: https://www.fftw.org/fftw-3.3.10.tar.gz
[[ -f $FFTW_RELEASE ]] || wget "https://www.fftw.org/$FFTW_RELEASE"

# rocThrust: ????


# rocPRIM: ????


# Lapack: https://github.com/Reference-LAPACK/lapack/archive/v3.12.1.tar.gz
[[ -f $LAPACK_RELEASE ]] || ( wget "https://github.com/Reference-LAPACK/lapack/archive/v$LAPACK_VERSION.tar.gz" ; mv "v$LAPACK_VERSION.tar.gz" "$LAPACK_RELEASE" )

# templates.therock.tgz
#wget https://github.com/klust/AMD-flang-experimental/raw/refs/heads/main/downloads/templates.therock.tgz
