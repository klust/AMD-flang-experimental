#! /bin/bash

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
basedir=$PWD

version='9.1.0'
abi='20.0'

mkdir -p /tmp/$USER

cd /opt/cray/pe/mpich/$version/ofi/cray/$abi
tar -cf /tmp/$USER/craylibs-$version.tar lib/libmpi_cray.so.12.0.0
cd -

cd /opt/cray/pe/mpich/$version/gtl
tar -rf /tmp/$USER/craylibs-$version.tar lib/libmpi_gtl_hsa.so.0.1.0 lib/pkgconfig/cray-gtl-hsa.pc
cd -

mv /tmp/$USER/craylibs-$version.tar ../cache
