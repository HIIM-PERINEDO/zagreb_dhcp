#!/bin/bash

# Define a usage function
usage() {
  echo "Usage: $0 <start> <end>"
  echo "Runs pipeline for subjects from <start> to <end>, where <start> and <end> are positive numbers and <start> < <end>."
  exit 1
}

# Check that the correct number of input parameters is provided
if [[ $# -ne 2 ]]; then
  usage
fi

# Get the start and end values from input parameters
script_dir=$(dirname "$0")
start=$1
end=$2
mr=MR2

scripts=( "dMRI_prepare_dmri_pipeline.sh" "dMRI_preprocess.sh" "dMRI_response.sh" "dMRI_csd.sh"  "dMRI_neonatal_5tt_mcrib.sh" "dMRI_registration.sh" "dMRI_tractography.sh" "dMRI_connectome.sh" )

# Hardcoded list of numerical arguments for "-from"
from_args=( "1" "2" "3" )
# Hardcoded list of strings for "-to"
to_args=( "20,30,40" "50,60,70" "80,90,100" )

# Check if the input parameters are valid
if ! [[ "$start" =~ ^[1-9][0-9]*$ ]] || ! [[ "$end" =~ ^[1-9][0-9]*$ ]] || (( start > end )); then
  echo "Error: Invalid input parameters. Please provide two positive numbers, with the first one smaller than the second."
  usage
fi

# Loop through subjects from start to end
for (( i=$start; i<=$end; i++ )); do
  # Construct the subject ID (e.g. PMR001)
  subject_id=$(printf "PMR%03d" $i)
  
  for script_file in ${scripts[@]}; do
    if [ -f $script_dir/$script_file ]; then
      # If it exists, run the script
      echo "Running script $script_file for subject $subject_id"
      #bash $script_dir/$script_file $subject_id $mr
    else
      # If it doesn't exist, print an error message
      echo "Error: script file not found: $script_file"
    fi
  done

  # Loop for running dMRI_tractography_multiple_roi.sh with paired "-from" and "-to"
  for idx in "${!from_args[@]}"; do
    if [ -f $script_dir/dMRI_tractography_multiple_roi.sh ]; then
    #if true ; then
      from_value=${from_args[$idx]}
      to_value=${to_args[$idx]}
      echo "Running dMRI_tractography_multiple_roi.sh with -from $from_value and -to $to_value for subject $subject_id"
      #bash $script_dir/dMRI_tractography_multiple_roi.sh -from $from_value -to $to_value
    else
      echo "Error: script file not found: dMRI_tractography_multiple_roi.sh"
    fi
  done
done
