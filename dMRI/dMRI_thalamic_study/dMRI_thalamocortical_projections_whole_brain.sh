#!/bin/bash

declare -A cortical_parcels

# Primary Motor Cortex
cortical_parcels["left_primary_motor_cortex"]="1024"  # ctx-lh-precentral
cortical_parcels["right_primary_motor_cortex"]="2024" # ctx-rh-precentral

# Primary Sensory Cortex
cortical_parcels["left_primary_sensory_cortex"]="1022"  # ctx-lh-postcentral
cortical_parcels["right_primary_sensory_cortex"]="2022" # ctx-rh-postcentral

# Posterior Parietal Cortex
# Assuming 'superiorparietal' and 'inferiorparietal' as the regions for posterior parietal cortex
cortical_parcels["left_posterior_parietal_cortex"]="1029,1008"  # ctx-lh-superiorparietal, ctx-lh-inferiorparietal
cortical_parcels["right_posterior_parietal_cortex"]="2029,2008" # ctx-rh-superiorparietal, ctx-rh-inferiorparietal

# Dorso-Lateral Prefrontal Cortex
# Assuming 'lateralorbitofrontal' and 'rostralmiddlefrontal' as the regions for dorso-lateral prefrontal cortex
cortical_parcels["left_dorso_lateral_prefrontal_cortex"]="1012,1027"  # ctx-lh-lateralorbitofrontal, ctx-lh-rostralmiddlefrontal
cortical_parcels["right_dorso_lateral_prefrontal_cortex"]="2012,2027" # ctx-rh-lateralorbitofrontal, ctx-rh-rostralmiddlefrontal

# Primary Visual Cortex
cortical_parcels["left_primary_visual_cortex"]="1021"  # ctx-lh-pericalcarine
cortical_parcels["right_primary_visual_cortex"]="2021" # ctx-rh-pericalcarine

#ALL FROM LEFT HEMISPHERE
all_parcels_left_hemisphere=$(printf "%s," {1000..1035})
all_parcels_left_hemisphere=${all_parcels_left_hemisphere%,}  # Removing the trailing comma

#ALL FROM RIGHT HEMISPHERE
all_parcels_right_hemisphere=$(printf "%s," {2000..2035})
all_parcels_right_hemisphere=${all_parcels_right_hemisphere%,}  # Removing the trailing comma

# Define colors for each cortical parcel
declare -A parcel_colors
parcel_colors["left_primary_motor_cortex"]="0,0,255" #"green"
parcel_colors["right_primary_motor_cortex"]="0,255,255" #"red"
parcel_colors["left_primary_sensory_cortex"]="255,255,255" #"yellow"
parcel_colors["right_primary_sensory_cortex"]="0,255,0" #"blue"
parcel_colors["left_posterior_parietal_cortex"]="255,0,0" #"purple"
parcel_colors["right_posterior_parietal_cortex"]="127,0,0" #"orange"
parcel_colors["left_dorso_lateral_prefrontal_cortex"]="0,127,255" #"pink"
parcel_colors["right_dorso_lateral_prefrontal_cortex"]="127,0,255" #"cyan"
parcel_colors["left_primary_visual_cortex"]="0,0,177" #"magenta"
parcel_colors["right_primary_visual_cortex"]="0,128,0" #"lime"

sID=PMR001
ssID=MR2

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 arg1 arg2"
    echo "Description: This script requires exactly two arguments: PMRxyz anr MRx"
    exit 1
else
    # Assign arguments to variables
    sID="$1"
    ssID="$2"
    
    echo "Argument 1: $sID"
    echo "Argument 2: $ssID"

    # Your script logic goes here
fi

nbr=100M

# Path to the extraction script
codedir=code/zagreb_dhcp
tract_extraction_script=$codedir/dMRI/dMRI_thalamic_study/dMRI_tract_extraction_whole_brain.sh

method=neonatal-5TT #DrawEM 
atlas="M-CRIB" #ALBERT 
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/act/$method-$atlas/5TT_coreg.mif.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography #datadir=derivatives/dMRI_tractography/sub-$sID/ses-$ssID
#datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography
actdir=act/$method-$atlas
tractdir=tractography/$method-$atlas


# Store names of resulting tck files
declare -a tck_files
declare -a tck_colors


# Loop through each cortical parcel
for parcel in "${!cortical_parcels[@]}"; do
    rois=${cortical_parcels[$parcel]}
    # Replace commas with underscores for file name
    rois_for_filename=${rois//,/_}
    #tck_file_name="tract_${parcel}_${rois_for_filename}.tck"
    
    all_parcels=""
    file_with_pattern=""
    # Determine the 'from' value based on hemisphere
    if [[ $parcel == left* ]]; then
        from_roi="9"
        all_parcels=$all_parcels_left_hemisphere
    else
        from_roi="48"
        all_parcels=$all_parcels_right_hemisphere
    fi

    #FILTERING HAS TO BE DONE ON ORIGINAL THALAMOCORTICAL PROJECTIONS!!!!!
    #file_with_pattern=$(find "$datadir/$tractdir" -type f -name "*${from_roi}*${all_parcels//,/_}*${nbr}.tck" -print | head -n 1)
    file_with_pattern=$(find "$datadir/$tractdir" -type f -name "whole_brain_${nbr}.tck" -print | head -n 1) #_sift2
    echo ${file_with_pattern}
    
    output_tck_file="$datadir/$tractdir/whole_brain_${nbr}_sift2_${from_roi}_${rois_for_filename}_subset_filtered.tck"
    output_tck_file_basename=`basename $output_tck_file .tck`

    bash $tract_extraction_script $sID $ssID -rois_from "$from_roi" -rois_to "$rois" -nbr $nbr -file "${file_with_pattern}"  -o "$output_tck_file_basename.tck"

    
    #output_tck_file="$datadir/$tractdir/whole_brain_${nbr}_sift2_${from_roi}_${rois_for_filename}_subset_filtered.tck"
    #output_tck_file="$datadir/$tractdir/roi_brain_from_${from_roi}_to_${all_parcels//,/_}_$nbr_${rois_for_filename}_subset.tck"
    # Store the tck file name
    tck_files+=("$output_tck_file")
    tck_colors+=("${parcel_colors[$parcel]}")
done

# Visualization
# Initialize the mrview command with the act5tt image
mrview_cmd="mrview $act5tt"

# Add each tck file to the mrview command
for i in "${!tck_files[@]}"; do
    tck_file=${tck_files[$i]}
    echo $tck_file
    color=${tck_colors[$i]}
    echo $color
    #mrview_cmd+=" -tractography.load $tck_file -tractography.colour $color"
    eval "${mrview_cmd} -tractography.load $tck_file -tractography.colour $color"
done

# Execute the mrview command to overlay all categories
#eval $mrview_cmd

# Additional commands for customizing the visualization can be added here
