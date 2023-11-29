#!/bin/bash

usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Performs whole-brain tractography and SIFT-filtering

Arguments:
  sID                            Subject ID (e.g. PMRxyz) 
  ssID                           Session ID (e.g. MR2)
Options:
  -csd                           CSD mif.gz-file (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/csd/dhollander/csd_dhollander_wm_2tt.mif.gz)
  -5TT                           5TT mif.gz-file in dMRI space (default: derivatives/dMRI_registration/sub-sID/ses-ssID/dwi/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz)
  -from                          single or multiple tb separated integers
  -from_subset                   subset of '-from' ROIs, separated by commas
  -to                            single or multiple tb separated integers (THALAMUS: R: 48 L: 9 | OCCIPITAL: LEFT: 1011,1013,1021  RIGHT: 2011,2013,2021)
  -to_subset                     subset of '-to' ROIs, separated by commas
  -nbr                           Number of streamlines in brain tractogram (default: 10K)
  -threads                       Number of threads for parallel processing (default: 24)
  -d / -data-dir  <directory>    The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/tractography_roi)
  -h / -help / --help            Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2

currdir=$PWD

# Defaults
method=neonatal-5TT
atlas="M-CRIB"
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography_roi
actdir=act/$method-$atlas
csddir=csd/$method-$atlas
tractdir=tractography/$method-$atlas
segmentationsdir=segmentations/$method-$atlas
from_roi=9
declare -a to_rois
declare -a to_subset_rois

csd=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/csd/dhollander/csd_dhollander_dwi_preproc_inorm_wm_2tt.mif.gz
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/act/$method-$atlas/5TT_coreg.mif.gz
segmentations=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/parcellation/neonatal-5TT-M-CRIB/segmentations/Structural_Labels_coreg.mif.gz

nbr=10K
threads=24

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
    -csd) shift; csd=$1; ;;
    -5TT) shift; act5tt=$1; ;;
    -nbr) shift; nbr=$1; ;;
    -from) shift; from_roi=$1; ;;
    -to) 
    shift; 
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
        if [[ $i =~ ^[0-9]+$ ]]; then
            to_rois+=("$i")
        fi
    done
    ;;
    -to_subset)
    shift; 
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
        if [[ $i =~ ^[0-9]+$ ]]; then
            to_subset_rois+=("$i")
        fi
    done
    ;;
    -threads) shift; threads=$1; ;;
    -d|-data-dir)  shift; datadir=$1; ;;
    -h|-help|--help) usage; ;;
    -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
    *) break ;;
    esac
    shift
done

# Update variables to point at corresponding filebases in $datadir
csd=`basename $csd .mif.gz`
act5tt=`basename $act5tt .mif.gz`

##################################################################################
# 1. Perform roi-based tractography

cd $datadir

if [ ! -d $tractdir ]; then mkdir -p $tractdir; fi

# Conditionally include ROI arguments in tckgen
roi_args_from=""
roi_args_from_seg=""
if [ -n "$from_roi" ]; then
    origdir=`dirname $segmentations`
    filebase=`basename $segmentations .mif.gz`

   roi_args_from="-seed_image "
   # roi_args_from_seg="mrcalc ${segmentations} $from_roi -eq $tractdir/from_roi.mif.gz" 
   mrcalc ${segmentationsdir}/${filebase}.mif.gz $from_roi -eq $tractdir/from_${from_roi}_roi.mif.gz
fi

roi_args_to=""
roi_args_to_seg=""
origdir=`dirname $segmentations`
filebase=`basename $segmentations .mif.gz`
mask_template=""
# First, create an initial mask set to zero
#mask_template=$(mrcalc ${segmentationsdir}/${filebase}.mif.gz -min 0 -max 0 -)
# Initialize a mask_template only if it does not exist before

mrcalc ${segmentationsdir}/${filebase}.mif.gz 0 -mul ${segmentationsdir}/${filebase}_zero_mask.mif.gz
mask_template=${segmentationsdir}/${filebase}_zero_mask.mif.gz

concat_rois=""
# Loop through the to_rois array and create a union mask
for roi in "${to_rois[@]}"; do
    roi_args_to="-include "

    # Concatenate ROIs
    if [ -z "$concat_rois" ]; then
        concat_rois="$roi"
    else
        concat_rois="${concat_rois}_$roi"
    fi

done

# Initialize an empty string to store concatenated ROIs
concat_rois_subset=""
# Loop through the to_rois array and create a union mask
for roi in "${to_subset_rois[@]}"; do
    roi_args_to="-include "

    # Concatenate ROIs
    if [ -z "$concat_rois_subset" ]; then
        concat_rois_subset="$roi"
    else
        concat_rois_subset="${concat_rois_subset}_$roi"
    fi

    # Calculate each intermediate step and store them in temporary files
    mrcalc ${segmentationsdir}/${filebase}.mif.gz $roi -eq  ${segmentationsdir}/temp1_${roi}.mif.gz
    mrcalc ${segmentationsdir}/temp1_${roi}.mif.gz ${mask_template} -add  $tractdir/to_${roi}_roi_union.mif.gz

    # Update the mask_template
    mask_template=$tractdir/to_${roi}_roi_union.mif.gz

    # Optionally remove temporary files (if you don't need them)
    rm ${segmentationsdir}/temp1_${roi}.mif.gz
    #rm ${segmentationsdir}/temp2_${roi}.mif.gz
done

# Rename the final union mask to include all concatenated ROIs
mv $mask_template $tractdir/to_${concat_rois}_roi.mif.gz

rm $tractdir/*union.mif.gz


# Select subset of rois from tck file
tck_file="$tractdir/roi_brain_from_${from_roi}_to_${concat_rois}_$nbr.tck"
output_tck_file="$tractdir/roi_brain_from_${from_roi}_to_${concat_rois}_$nbr_${concat_rois_subset}_subset.tck"

# Execute tckedit command
tckedit $tck_file $output_tck_file -include $tractdir/to_${concat_rois}_roi.mif.gz -include $tractdir/from_${from_roi}_roi.mif.gz

# Visualization of the extracted tract overlaying the act5tt image
mrview $actdir/$act5tt.mif.gz -tractography.load $output_tck_file

