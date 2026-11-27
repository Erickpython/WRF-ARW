#!/usr/bin/sh
# GNU Compilation of WRF dependencies 
# For gcc,g++,gfortran,cpp Version: 11.5.0: gcc --version 
# gcc (Ubuntu 11.5.0-11ubuntu2) 11.5.0
# Copyright (C) 2021 Free Software Foundation, Inc.
# This is free software; see the source for copying conditions.  There is NO
# warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
mkdir -p $PWD/wrf_dependencies
DIR=$PWD/wrf_dependencies

# These only need to be set again in new shell environments if using the older make build system
export NETCDF=$DIR/netcdf
export LD_LIBRARY_PATH=$NETCDF/lib:$DIR/grib2/lib

# Set these again in any new shell environment to build and run WRF
export PATH=$NETCDF/bin:$DIR/mpich/bin:${PATH}
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

# Use these ONLY when building these dependencies. These SHOULD NOT be set when building WRF or WPS
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS="-m64 -fallow-argument-mismatch"
export F77=gfortran
export FFLAGS="-m64 -fallow-argument-mismatch"
export LDFLAGS="-L$NETCDF/lib -L$DIR/grib2/lib"
export CPPFLAGS="-I$NETCDF/include -I$DIR/grib2/include -fcommon"

export WRF_DEP_JOBS=$(nproc)

#zlib updated to version 1.3.2 from github releases 
wget https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz
tar xzvf zlib-1.3.2.tar.gz
cd zlib-1.3.2/
./configure --prefix=$DIR/grib2
make -j $WRF_DEP_JOBS
make install
cd ..
rm -rf zlib*

# hdf5 to version 1.14.5 from github releases 
wget https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.5/hdf5-1.14.5.tar.gz
tar xzvf hdf5-1.14.5.tar.gz
cd hdf5-1.14.5
./configure --prefix=$DIR/netcdf --with-zlib=$DIR/grib2 --enable-fortran --enable-shared
make -j $WRF_DEP_JOBS
make install
cd ..
rm -rf hdf5*

# netcdf-c to version 4.10.0 from github releases 
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.10.0.tar.gz
tar xzvf v4.10.0.tar.gz
cd netcdf-c-4.10.0
./configure --prefix=$DIR/netcdf --disable-dap --enable-netcdf-4 --enable-hdf5 --enable-shared
make -j $WRF_DEP_JOBS
make install
cd ..
rm -rf v4.10.0.tar.gz netcdf-c*

export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf

# netcdf-fortran to version 4.6.2 from github releases 
export LIBS='-lnetcdf -lz'
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.2.tar.gz
tar xzvf v4.6.2.tar.gz
cd netcdf-fortran-4.6.2
./configure --prefix=$DIR/netcdf --disable-hdf5 --enable-shared
make -j $WRF_DEP_JOBS
make install
cd ..
rm -rf netcdf-fortran* v4.6.2.tar.gz
 
#mpich updated to version 5.0.0 from github releases 
wget https://github.com/pmodels/mpich/releases/download/v5.0.0/mpich-5.0.0.tar.gz
tar -xf mpich-5.0.0.tar.gz
cd mpich-5.0.0
./configure --prefix=$DIR/mpich
make -j $WRF_DEP_JOBS 
make install
cd ..
rm -rf mpich*

#libpng to version 1.6.56 from sourceForge 
wget https://sourceforge.net/projects/libpng/files/libpng16/1.6.56/libpng-1.6.56.tar.gz
tar xzvf libpng-1.6.56.tar.gz
cd libpng-1.6.56
./configure --prefix=$DIR/grib2
make -j $WRF_DEP_JOBS
make install
cd ..
rm -rf libpng*

# jasper remains as it is:
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
tar xzvf jasper-1.900.1.tar.gz
cd jasper-1.900.1
GCC_MAJOR="$(gcc -dumpversion | cut -d. -f1)"
if [ "$GCC_MAJOR" = "15" ]; then
    CFLAGS="${CFLAGS:-} -std=gnu17" ./configure --prefix=$DIR/grib2
else
    ./configure --prefix=$DIR/grib2
fi
make
make install
cd ..
rm -rf jasper* ._jasper-1.900.1

# After this in a new shell you should redo the environment settings found at the top of this script
# Resolve the exact path of wrf_dependencies so sourcing .wrfmodules later
# works from any working directory.
RESOLVED_DIR="$(cd "$DIR" && pwd)"
MODULE_FILE="${1:-.wrfmodules}"

cat << EOF > "$MODULE_FILE"
export DIR="$RESOLVED_DIR"

export NETCDF="\$DIR/netcdf"
export MPICH="\$DIR/mpich"

export LD_LIBRARY_PATH="\$NETCDF/lib:\$MPICH/lib:\$DIR/grib2/lib:\${LD_LIBRARY_PATH:-}"
export PATH="\$NETCDF/bin:\$MPICH/bin:\${PATH}"

export JASPERLIB="\$DIR/grib2/lib"
export JASPERINC="\$DIR/grib2/include"
EOF


