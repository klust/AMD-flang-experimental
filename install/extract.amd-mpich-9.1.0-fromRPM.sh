#!/bin/bash

RPMDIR='../cray-mpich-26.03-SLES15SP6'
RPM1="$RPMDIR/cray-mpich-9.1.0-amd70-9.1.0-794.sles15sp6.x86_64.rpm"
echo -e "Files in $RPM1:\n$(rpm2cpio $RPM1 | cpio -t)\n"

rpm2cpio $RPM1 | cpio -idmv ./opt/cray/pe/mpich/9.1.0/ofi/amd/7.0/lib/libmpi_amd.so.12.0.0

RPM2="$RPMDIR/cray-mpich-9.1.0-amd70-devel-9.1.0-794.sles15sp6.x86_64.rpm"
echo -e "Files in $RPM2:\n$(rpm2cpio $RPM2 | cpio -t)\n"

rpm2cpio $RPM2 | cpio -idmv ./opt/cray/pe/mpich/9.1.0/ofi/amd/7.0/lib/libmpi_amd.a

RPM3="$RPMDIR/cray-mpich-9.1.0-gtl-9.1.0-794.sles15sp6.x86_64.rpm"
echo -e "Files in $RPM3:\n$(rpm2cpio $RPM3 | cpio -t)\n"

rpm2cpio $RPM2 | cpio -idmv ./opt/cray/pe/mpich/9.1.0/gtl/lib/libmpi_gtl_hsa.so.0.1.0
rpm2cpio $RPM2 | cpio -idmv ./opt/cray/pe/mpich/9.1.0/gtl/lib/pkgconfig/cray-gtl-hsa.pc

# Now put the files where we want them
mkdir -p lib/pkgconfig
cp ./opt/cray/pe/mpich/9.1.0/ofi/amd/7.0/lib/libmpi_amd.so.12.0.0 lib
cp ./opt/cray/pe/mpich/9.1.0/ofi/amd/7.0/lib/libmpi_amd.a         lib
cp ./opt/cray/pe/mpich/9.1.0/gtl/lib/libmpi_gtl_hsa.so.0.1.0      lib
cp ./opt/cray/pe/mpich/9.1.0/gtl/lib/pkgconfig/cray-gtl-hsa.pc    lib/pkgconfig

# And make a tar file of those
gtar -cf cray-mpich-9.1.0-amd.tar lib
