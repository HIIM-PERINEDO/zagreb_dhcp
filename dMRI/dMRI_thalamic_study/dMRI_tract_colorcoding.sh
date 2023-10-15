#!/bin/bash

sID=PMR021
ssID=MR2
datadir=derivatives/dMRI_thalamic_study/sub-$sID/ses-$ssID
origdir=derivatives/dMRI/sub-$sID/ses-$ssID
method=neonatal-5TT #DrawEM 
atlas="M-CRIB" #ALBERT 
actdir=act/$method-$atlas
csddir=csd/$method-$atlas
tracts=dwi/tractography_roi_multiple/tractography/$method-$atlas/roi_brain_from_9_to_1011_1013_1021_10K.tck

segmentations=dwi/registration/dwi/parcellation/$method-$atlas/segmentations/Structural_Labels_coreg.mif.gz
structural=dwi/tractography_roi_multiple/act/$method-$atlas/5TT_coreg.mif.gz

# Your main tractogram
tractogram=$origdir/$tracts

# Your source ROI
#source_roi=$origdir/$segmentations
source_roi=9

anatomy=$origdir/$structural

# List of target ROIs
declare -a target_rois=(1011 1013 1021)


# List of colors for each target ROI
# Ensure this list has the same number of colors as target ROIs
declare -a colors=("255,0,0" "0,255,0" "0,0,255")
declare -a opacities=(0 0 1)


mkdir -p $datadir

# For each target ROI, extract the streamlines and then visualize in mrview
mrview_command="mrview $anatomy"  # Assuming anatomy.mif as your reference background image

for index in "${!target_rois[@]}"
do
    target="${target_rois[$index]}"
    color="${colors[$index]}"
    opacity="${opacities[$index]}"
    segmentations_all=$origdir/$segmentations
    echo $opacity
    mrcalc $segmentations_all $source_roi -eq  ${datadir}/segmentation_of_${source_roi}.mif.gz
    mrcalc $segmentations_all $target -eq  ${datadir}/segmentation_of_${target}.mif.gz

    output_tck=${datadir}/tracts_${source_roi}_to_${target}.tck
    
    # Extract streamlines
    tckedit -include ${datadir}/segmentation_of_${source_roi}.mif.gz -include ${datadir}/segmentation_of_${target}.mif.gz $tractogram $output_tck
    
    # Append to the mrview command
    mrview_command+=" -tractography.load $output_tck -tractography.colour $color -tractography.opacity $opacity"
done

# Execute the full mrview command
$mrview_command
