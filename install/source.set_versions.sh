#
# Filenames as expected by install.therock.sh and copied from that script
#
export THEROCK="therock-afar-24.3.0-multiarch-10.1.0-592954c.tar.bz2"
export MPICH_RELEASE="mpich-4.3.1.tar.gz"
export HDF5_RELEASE="hdf5-v1.14.6.tgz"
export NETCDF_C_RELEASE="netcdf-c-4.9.3.tar.gz"
export NETCDF_FORTRAN_RELEASE="netcdf-fortran-4.6.2.tar.gz"
export PNETCDF_RELEASE="pnetcdf-1.14.1.tar.gz"
export FFTW_RELEASE="fftw-3.3.10.tar.gz"
export THRUST_RELEASE="thrust-4.0.0.tgz"
export ROCPRIM_RELEASE="rocprim-4.0.0.tgz"
export LAPACK_RELEASE="v3.12.1.tar.gz"

#
# Compute versions of packages from the data file
#
export MPICH_VERSION="$(echo $MPICH_RELEASE | sed 's|mpich-\(.*\)\.tar.gz|\1|')"
export HDF5_VERSION="$(echo $HDF5_RELEASE | sed 's|hdf5-v\(.*\)\.tgz|\1|')"
export NETCDF_C_VERSION="$(echo $NETCDF_C_RELEASE | sed 's|netcdf-c-\(.*\)\.tar\.gz|\1|')"
export NETCDF_FORTRAN_VERSION="$(echo $NETCDF_FORTRAN_RELEASE | sed 's|netcdf-fortran-\(.*\)\.tar\.gz|\1|')"
export PNETCDF_VERSION="$(echo $PNETCDF_RELEASE | sed 's|pnetcdf-\(.*\)\.tar\.gz|\1|')"
export FFTW_VERSION="$(echo $FFTW_RELEASE | sed 's|fftw-\(.*\)\.tar\.gz|\1|')"
export LAPACK_VERSION="$(echo $LAPACK_RELEASE | sed 's|v\(.*\)\.tar\.gz|\1|')"
