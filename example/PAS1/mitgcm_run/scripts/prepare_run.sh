#!/bin/bash
################################################
# Clean out old results and link input files.
################################################

# Save current directory
ORIG_DIR=$PWD

# Optional argument: path to scripts/ directory.
# Can be useful if this script was called from a different directory.
# If unset, assume we're already in it
SCRIPT_DIR=$1
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR=$ORIG_DIR
fi

cd $SCRIPT_DIR

# Empty the run directory - but first make sure it exists!
if [ -d "../run" ]; then
  cd ../run
  rm -rf *
else
  echo 'Creating run directory'
  mkdir ../run
  cd ../run
fi

# Copy everything from the input directory
cp ../input/* .

# MH
# Copy grid files
cp ../gridfiles/* .
# -MH

# Link input files stored elsewhere
PAS_IN=/epccfs/n02/n02/michai1/forcing/PAS_files/
ln -s $PAS_IN/* .

LENS_WND=/epccfs/n02/n02/michai1/forcing/CESM/LENS
ln -s $LENS_WND/* .
PIctrl_WND=/epccfs/n02/n02/michai1/forcing/CESM/PIctrl
ln -s $PIctrl_WND/* .

../scripts/dummy_link.sh LENS 1889 1919 1920 1950                                                                                                                                             
../scripts/dummy_link.sh LENS 2101 2101 2100 2100   

# Deep copy of some files that will be modified
rm -f OB*corr.bin
cp -r $PAS_IN/OB*corr.bin .
for f in OB*corr.bin; do
  cp $f $f.master
done

# Copy restart files 
cp /work/n02/n02/michai1/UaMITgcm/example/PAS1/mitgcm_run/input/restart/pickup*spinup* .

rm panom.bin shelfice_bedmach.bin bathymetry_bedmach.bin
cp $PAS_IN/bathymetry_bedmach.bin $PAS_IN/shelfice_bedmach.bin $PAS_IN/panom.bin .

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
