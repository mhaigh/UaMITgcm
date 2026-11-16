#!/bin/bash

rm -rf output/*
rm coupler_stdout
rm slurm*
touch coupler_stdout

sbatch --export=ALL -A $HECACC run_coupler.sh
