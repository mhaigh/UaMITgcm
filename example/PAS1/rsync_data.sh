#!/bin/bash

EXPTNAME=PAS1

# Make directories on Polar Oceans volume
ssh ${HOMEHOST} "mkdir -p ${HOMEROOT}/${EXPTNAME}"

# Copy whole output directory
rsync -avh --progress \
	output ${HOMEHOST}:${HOMEROOT}/${EXPTNAME}/

# Copy config file and coupler output
rsync -avh config_options.py ${HOMEHOST}:${HOMEROOT}/${EXPTNAME}/
rsync -avh coupler_stdout ${HOMEHOST}:${HOMEROOT}/${EXPTNAME}/
