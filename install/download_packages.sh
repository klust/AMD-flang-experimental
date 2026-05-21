#! /bin/bash

export CACHE_DIR="$(dirname $0)/../cache"
mkdir -p "$CACHE_DIR"

cd "$CACHE_DIR" 

export MPICH_VERSION='3.4a2'
export HDF5_VERSION='1.14.6'
export NETCDF_C_VERSION='4.9.3'
export NETCDF_FORTRAN_VERSION='4.6.2'
export PNETCDF_VERSION='1.14.1'
export FFTW_VERSION='3.3.10'
export LAPACK_VERSION='3.12.1'

export THEROCK="therock-afar-23.2.1-gfx90a-7.13.0-7357b5084b.tar.bz2"
export MPICH_RELEASE="mpich-$MPICH_VERSION.tar.gz"
export HDF5_RELEASE="hdf5-$HDF5_VERSION.tar.gz"
export NETCDF_C_RELEASE="netcdf-c-$NETCDF_C_VERSION.tar.gz"
export NETCDF_FORTRAN_RELEASE="netcdf-fortran-$NETCDF_FORTRAN_VERSION.tar.gz"
export PNETCDF_RELEASE="pnetcdf-$PNETCDF_VERSION.tar.gz"
export FFTW_RELEASE="fftw-$FFTW_VERSION.tar.gz"
export THRUST_RELEASE="thrust-4.0.0.tgz"
export ROCPRIM_RELEASE="rocprim-4.0.0.tgz"
export LAPACK_RELEASE="lapack-$LAPACK_VERSION.tar.gz"

# https://repo.radeon.com/rocm/misc/flang/therock-afar-23.2.1-gfx90a-7.13.0-7357b5084b.tar.bz2
[[ -f $THEROCK ]] || wget "https://repo.radeon.com/rocm/misc/flang/$THEROCK"

# MPICH: https://www.mpich.org/static/downloads/3.4a2/mpich-3.4a2.tar.gz
[[ -f $MPICH_RELEASE ]] || wget "https://www.mpich.org/static/downloads/$MPICH_VERSION/$MPICH_RELEASE"

# HDF5: https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.6/hdf5-1.14.6.tar.gz
[[ -f $HDF5_RELEASE ]] || wget "https://github.com/HDFGroup/hdf5/releases/download/hdf5_$HDF5_VERSION/$HDF5_RELEASE"

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
