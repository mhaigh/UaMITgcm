#!/bin/bash
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
###############################################################

echo $WORK

module load cray-python

# USER VARIABLES
# Path to UaMITgcm repository
REPO_DIR=$WORK/UaMITgcm
# Path to MITgcm source code: default is to use the version inside UaMITgcm
MIT_SOURCE=$REPO_DIR/MITgcm_68r

echo 'Coupler starts '`date` >> jobs.log

# Get various python files/packages in the path
# coupling scripts
COUPLEPY=$REPO_DIR/coupling
# mitgcm_python
MITPY=$REPO_DIR/tools
# MITgcmutils
MITU=$MIT_SOURCE/utils/python/MITgcmutils
export PYTHONPATH=$PWD:$COUPLEPY:$MITPY:$MITU:$PYTHONPATH:$(pwd)
# echo $PYTHONPATH
echo $'\n''*****'`date`'*****' >> coupler_stdout

source $MITPY/venv3/bin/activate

python $COUPLEPY/master.py >> coupler_stdout 2>&1
OUT=$?

if [ $OUT == 0 ]; then
    echo 'Coupler ends '`date` >> jobs.log
    exit 0
else
    echo 'Error in coupler '`date` >> jobs.log
    exit 1
fi

