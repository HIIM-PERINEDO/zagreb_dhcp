#!/bin/bash

# Define a usage function
usage() {
  echo "Usage: $0 <PMR>"
  echo "Example: $0 PMR001"
  exit 1
}

# Check that the correct number of input parameters is provided
if [[ $# -ne 1 ]]; then
  usage
fi

# Get the PMR value from the input parameter
pmr=$1

# Validate the PMR format
if ! [[ "$pmr" =~ ^PMR[0-9]{3}$ ]]; then
  echo "Error: Invalid PMR format. Please provide a valid PMR in the format PMR___ (e.g., PMR001)."
  usage
fi

# Initialize start_dir variable
start_dir="/home/perinedo/Projects/PK_PMR"

cat ${start_dir}/code/zagreb_dhcp/label_names/M-CRIB/Structural_Labels.txt

# While loop to get user input
while true; do
  # Ask user for input
  read -p "Enter two numbers separated by a comma (or 'exit' to quit): " input

  # Check if user wants to exit
  if [[ "$input" == "exit" ]]; then
    echo "Exiting the script."
    break
  fi

  # Split input into two numbers
  IFS=',' read -ra nums <<< "$input"

  # Check if two numbers were provided
  if [[ "${#nums[@]}" -ne 2 ]]; then
    echo "Error: Please provide two numbers separated by a comma."
    continue
  fi

  # Check if the numbers are integers
  re='^[0-9]+$'
  if ! [[ ${nums[0]} =~ $re ]] || ! [[ ${nums[1]} =~ $re ]]; then
    echo "Error: Invalid input. Please provide two integers separated by a comma."
    continue
  fi

  # Assign the start_dir variable
  from_to=${nums[0]},${nums[1]}

  # Call the 'mrview' script with the parameters
  echo "Calling 'mrview' script with start_dir: $start_dir and PMR: $pmr"
  # Replace the following line with the actual command to call 'mrview'
  # ./mrview "$start_dir" "$pmr"
  tracks=${start_dir}/derivatives/dMRI_connectome/sub-${pmr}/ses-MR2/tractography/whole_brain_10M.tck
  #assignments=${start_dir}/derivatives/dMRI_connectome/sub-${pmr}/ses-MR2/connectome/neonatal-5TT-M-CRIB/cortical/assignments_whole_brain_10M_cortical_Connectome.csv
  assignments=${start_dir}/derivatives/dMRI_connectome/sub-${pmr}/ses-MR2/connectome/neonatal-5TT-M-CRIB/Structural_M-CRIB/assignments_whole_brain_10M_Structural_M-CRIB_Connectome.csv

  connectome2tck ${tracks} ${assignments} track_${nums[0]}_to_${nums[1]}.tck -nodes $from_to -exclusive -files single -force

  #connectome2tck -nodes 43  whole_brain_10M_sift.tck assignments_whole_brain_10M_sift_Structural_M-CRIB_Connectome.csv R_thalamus_to_
  tckinfo track_${nums[0]}_to_${nums[1]}.tck
  mrview ${start_dir}/derivatives/dMRI_registration/sub-${pmr}/ses-MR2/dwi/T2w_brain_coreg.mif.gz  -tractography.load track_${nums[0]}_to_${nums[1]}.tck

done
