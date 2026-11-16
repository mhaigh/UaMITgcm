#!/bin/bash
################################################
# Compile MITgcm.
################################################

# USER VARIABLE
# Path to MITgcm source code: recommend to use the one inside UaMITgcm
# MIT_SOURCE=$WORK/UaMITgcm/MITgcm_67s
# ROOTDIR=$MIT_SOURCE
# Path to file containing Fortran flags etc
# BUILD_OPTIONS=../linux_x86_monsoon_ifort

# Empty the build and output directories
if [ -d "../build" ]; then
    rm -rf ../build/*
else
    mkdir -p ../build
fi
if [ -d "../output" ]; then
    rm -rf ../output/*
else
    mkdir -p ../output
fi

. ./case_setup
cd ../build

rm ../code/*

# These for exf2winds version of code
#cp $WORK/UaMITgcm/example/PAS1/mitgcm_run/code/exf2winds/* ../code/
#MITGCM_ROOTDIR=$WORK/UaMITgcm/MITgcm_68r

# These for default version of code
cp $WORK/UaMITgcm/example/PAS1/mitgcm_run/code/PAS_default/* ../code/

# Generate a Makefile
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
$MITGCM_ROOTDIR/tools/genmake2 ${MITGCM_GENM_FLAGS} -mods=../code -of=${MITGCM_OPT} -mpi >genmake.trace 2>&1 

# Run the Makefile
make depend
make
