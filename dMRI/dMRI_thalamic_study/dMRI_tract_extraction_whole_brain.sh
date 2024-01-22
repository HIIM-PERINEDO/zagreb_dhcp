#!/bin/bash

usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Performs tract extraction

Arguments:
  sID                            Subject ID (e.g. PMRxyz) 
  ssID                           Session ID (e.g. MR2)
Options:
  -csd                           CSD mif.gz-file (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/csd/dhollander/csd_dhollander_wm_2tt.mif.gz)
  -5TT                           5TT mif.gz-file in dMRI space (default: derivatives/dMRI_registration/sub-sID/ses-ssID/dwi/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz)
  -file                          Tractography file (tck format)
  -rois_from                           Subset of ROIs for targeting, separated by commas
  -rois_to                           Subset of ROIs for targeting, separated by commas
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
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography
actdir=act/$method-$atlas
csddir=csd/$method-$atlas
tractdir=tractography/$method-$atlas
segmentationsdir=segmentations/$method-$atlas

csd=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/csd/dhollander/csd_dhollander_dwi_preproc_inorm_wm_2tt.mif.gz
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/act/$method-$atlas/5TT_coreg.mif.gz
segmentations=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/parcellation/neonatal-5TT-M-CRIB/segmentations/Structural_Labels_coreg.mif.gz

nbr=10K
threads=24
tck_file=""
output_tck_file=""
declare -a rois_from
declare -a rois_to

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
    -csd) shift; csd=$1; ;;
    -5TT) shift; act5tt=$1; ;;
    -nbr) shift; nbr=$1; ;;
    -file) shift; tck_file=$1; ;;  # Set the tck file
    -o) shift; output_tck_file=$1; ;;  # Set the output file
    -rois_from)
    shift; 
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
        if [[ $i =~ ^[0-9]+$ ]]; then
            rois_from+=("$i")
        fi
    done
    ;;
    -rois_to)
    shift; 
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
        if [[ $i =~ ^[0-9]+$ ]]; then
            rois_to+=("$i")
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

echo $tck_file
# Update variables to point at corresponding filebases in $datadir
csd=`basename $csd .mif.gz`
act5tt=`basename $act5tt .mif.gz`
tck_file=`basename $tck_file .tck`
echo $tck_file
#tck_file_orig=$tck_file
tck_file=${tck_file}.tck
echo $tck_file
echo $output_tck_file

##################################################################################
# 1. Perform roi-based tractography

cd $datadir

echo "$tractdir/$tck_file"

# Perform tractography processing with the given tck file
if [ ! -z "$tractdir/$tck_file" ] && [ -f "$tractdir/$tck_file" ]; then
    echo "Tu sam"
    origdir=`dirname $segmentations`
    filebase=`basename $segmentations .mif.gz`
    mask_template=""
    # First, create an initial mask set to zero
    #mask_template=$(mrcalc ${segmentationsdir}/${filebase}.mif.gz -min 0 -max 0 -)
    # Initialize a mask_template only if it does not exist before

    mrcalc ${segmentationsdir}/${filebase}.mif.gz 0 -mul ${tractdir}/${filebase}_zero_mask.mif.gz
    mask_template=${tractdir}/${filebase}_zero_mask.mif.gz


    # Initialize an empty string to store concatenated ROIs
    concat_rois_from=""
    # Loop through the to_rois array and create a union mask
    for roi in "${rois_from[@]}"; do
        # Concatenate ROIs
        if [ -z "$concat_rois_from" ]; then
            concat_rois_from="$roi"
        else
            concat_rois_from="${concat_rois_from}_$roi"
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
    mv $mask_template $tractdir/to_${concat_rois_from}_roi.mif.gz


    ################################################################333
    mrcalc ${segmentationsdir}/${filebase}.mif.gz 0 -mul ${tractdir}/${filebase}_zero_mask.mif.gz
    mask_template=${tractdir}/${filebase}_zero_mask.mif.gz


    # Initialize an empty string to store concatenated ROIs
    concat_rois_to=""
    # Loop through the to_rois array and create a union mask
    for roi in "${rois_to[@]}"; do
        # Concatenate ROIs
        if [ -z "$concat_rois_to" ]; then
            concat_rois_to="$roi"
        else
            concat_rois_to="${concat_rois_to}_$roi"
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
    mv $mask_template $tractdir/to_${concat_rois_to}_roi.mif.gz


    #output_tck_file="$tractdir/sub-${sID}_ses-${ssID}_${concat_rois_from}_${concat_rois_to}_${nbr}_subset.tck"
    output_tck_file="$tractdir/$output_tck_file"

    # Execute tckedit command
    tckedit $tractdir/$tck_file $output_tck_file -include $tractdir/to_${concat_rois_from}_roi.mif.gz -include $tractdir/to_${concat_rois_to}_roi.mif.gz -ends_only -force

    #output_tck_file_base=`basename $output_tck_file .tck`
    #tckmap $output_tck_file  -template ../registration/dwi/meanb1000_brain.nii.gz - \
    #| mrcalc - $(tckinfo $output_tck_file | grep " count" | cut -d':' -f2 | tr -d '[:space:]') -div - \
    #| mrthreshold - -abs 0.001 -invert $tractdir/${output_tck_file_base}_filtered_mask.mif

    #tckedit -exclude $tractdir/${output_tck_file_base}_filtered_mask.mif $output_tck_file $tractdir/${output_tck_file_base}_filtered.tck -force

    #mrthreshold $tractdir/${output_tck_file_base}_filtered_mask.mif -invert -force $tractdir/${output_tck_file_base}_filtered_mask.mif

    rm $tractdir/*union.mif.gz
    rm $tractdir/to*.mif.gz
    rm $tractdir/*_zero_mask.mif.gz

    # Visualization of the extracted tract overlaying the act5tt image
    #mrview $actdir/$act5tt.mif.gz -tractography.load $output_tck_file

    #tckedit $tck_file - -include $tractdir/to_${concat_rois}_roi.mif.gz -include $tractdir/from_${from_roi}_roi.mif.gz | mrview $actdir/$act5tt.mif.gz -tractography.load -
fi


