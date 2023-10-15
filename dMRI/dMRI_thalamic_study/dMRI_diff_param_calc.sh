#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 SUBJECT SESSION PARAMETER"
    exit 1
fi

SUBJECT=$1
SESSION=$2
PARAMETER=$3

param_file=""
# Check if PARAMETER is either MD or FA
if [ "$PARAMETER" != "ADC" ] && [ "$PARAMETER" != "FA" ]; then
    echo "Error: PARAMETER must be either MD or FA"
    exit 1
fi
if [ "$PARAMETER" == "ADC" ] ; then
    param_file="adc"
fi
if [ "$PARAMETER" == "FA" ] ; then
    param_file="fa"
fi

# Define the parameter file path based on the PARAMETER argument
PARAM_FILE="derivatives/dMRI/sub-${SUBJECT}/ses-${SESSION}/dwi/preproc/${param_file}.mif.gz"

# Check if the parameter file exists
if [ ! -f "$PARAM_FILE" ]; then
    echo "Error: Parameter file $PARAM_FILE not found"
    exit 1
fi

# Loop through all mask files and run the fslstats command
for MASK_FILE in derivatives/dMRI/sub-${SUBJECT}/ses-${SESSION}/dwi/tractography_roi_multiple/tractography/neonatal-5TT-M-CRIB/*_mask.nii.gz; do
    # Check if mask file exists
    if [ ! -f "$MASK_FILE" ]; then
        echo "No mask files found in derivatives/sub-${SUBJECT}/${SESSION}/"
        break
    fi
    echo "Processing mask: $MASK_FILE"
    filebase=`basename $PARAM_FILE .mif.gz`
    filebase="${PARAM_FILE%.mif.gz}"
    echo $filebase

    mrconvert "$PARAM_FILE" "${filebase}.nii.gz"


    fslstats "${filebase}.nii.gz" -k "$MASK_FILE" -M
done
