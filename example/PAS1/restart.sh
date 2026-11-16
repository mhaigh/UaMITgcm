#!/bin/bash

# Restart run from latest year with pickup saved on BSL
# Eg if year 2000 dir has pickup, restart from 2001

YEAR1=$1
YEAR0=$((YEAR1-100))

# Make sure dt set correctly in data namelist and config_options.py
deltaTold=600
deltaT=600

if [ -z $YEAR1 ]; then
	echo "Must provide year"
	exit
fi

echo 'Removing old pickup files from run dir...'
cd mitgcm_run/run/
rm *pickup*

echo 'Removing old state* files...'
rm state*

# Copy restart file from BSL
echo 'Copying latest pickup files from bsl...'
HOMEDIR=$HOMEHOST:/data/oceans_output/shelf/michai/mitgcm/PAS1/output/$YEAR0/MITgcm
scp $HOMEDIR/*pickup* .

##
# Set endtime, checkpoint freq and niter0 in data
echo 'Updating data namelist...'

# Get iter number from pickup
pickup=$(ls pickup.*.data)
tmp=${pickup#*.}
niter0=${tmp%.*}
niter0=$(echo $niter0 | sed 's/^0*//')

# If changing time step, have to scale niter0 and change pickup file name
if [ $deltaT -ne $deltaTold ]; then
	echo 'Using altered timestep. Make sure data and config_options consisent.'
	niter0old=$niter0
	if [ $deltaT -gt $deltaTold ]; then
		scale=$(( $deltaT/$deltaTold ))
		niter0=$(( $niter0/$scale ))
	else
		scale=$(( $deltaTold/$deltaT ))
		niter0=$(( $scale*$niter0 ))
	fi
	niter0fill=$(printf "%010d" $niter0)
	niter0oldfill=$(printf "%010d" $niter0old)
	# Rename all files
	mv $pickup pickup.${niter0fill}.data
	mv pickup.${niter0oldfill}.meta pickup.${niter0fill}.meta
	mv pickup_seaice.${niter0oldfill}.data pickup_seaice.${niter0fill}.data
        mv pickup_seaice.${niter0oldfill}.meta pickup_seaice.${niter0fill}.meta
fi

# Replace niter0 line in data
niter0_line="\ niter0=${niter0},"
sed -i "/^ niter0/c $niter0_line" data

# Replace endtime and pchkptFreq
endtime=$(( 86400*365+$deltaT*$niter0 ))
endtime_line="\ endTime=${endtime},"
chkpt_line="\ pchkptFreq=${endtime},"
echo $endtime_line
echo $chkpt_line
sed -i "/^ endTime/c $endtime_line" data
sed -i "/^ pchkptFreq/c $chkpt_line" data
##

# Delete old output, otherwise will get file exist error
echo 'Removing latest output dirs...'
cd ../../output/
rm -rf $YEAR1
rm -rf $YEAR0

# Set calendar to right year
sed -i "1 c $YEAR1" calendar
cd ../

echo 'Submitting job...'
sbatch -A $HECACC2 -J PAS1o --export=ALL,MIT_DIR=/work/n02/n02/michai1/UaMITgcm/example/PAS1/mitgcm_run/,ACC=$HECACC2 run_mitgcm.sh


