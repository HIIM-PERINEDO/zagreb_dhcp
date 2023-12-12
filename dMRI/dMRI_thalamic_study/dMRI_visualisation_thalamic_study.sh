#!/bin/bash
# NENAH Study

usage()
{
  base=$(basename "$0")
  echo "usage: $base sID ssID processing_step [options]
Simple script to visualize diffusion NII-images BIDS folder (rawdata/sub-\$sID/dwi) in order to do QC of rawdata
Arguments:
  sID              Subject ID (e.g. PMR001)
  ssID             Session ID (e.g. MR2)
  processing_step  Step of processing (RAWDATA,PREPROCESS,RESPONSE,CSD,5TT,REGISTRATION,TRACTOGRAPHY,CONNECTOME) 
Options:
  -studyfolder         BIDS dwi folder location (default: directory from which script is called)
  -h / -help / --help   Print usage.
"
  exit;
}

#Defaults
[ $# -ge 3 ] || { usage; }
command=$@
sID=$1
ssID=$2
processing_step=$3

studyfolder=$PWD

shift 3
while [ $# -gt 0 ]; do
    case "$1" in
    -studyfolder) shift; studyfolder=$1; ;;
    -h|-help|--help) usage; ;;
    -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
    *) break ;;
    esac
    shift
done

# Define processing step to directory mapping
declare -A dir_mapping=(
  ["RAWDATA"]="derivatives/dMRI/sub-$sID/ses-$ssID"
  ["PREPROCESS"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/preproc"
  ["RESPONSE"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/response"
  ["CSD"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/csd"
  ["5TT"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib"
  ["REGISTRATION"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration"
  ["TRACTOGRAPHY"]="derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography"
  ["CONNECTOME"]="/path/to/connectome"
)

cd $studyfolder

# Processing based on the processing_step
case $processing_step in
    "RAWDATA")
        echo "Processing RAWDATA"
        # Add your command here
        rawdata=`echo "${dir_mapping[$processing_step]}"`

        for dir in "anat/orig" "dwi/orig"; do
            for file in $(find $rawdata/$dir -name "*.nii.gz"); do
                echo "Visualization of $file"
                mrview $file -mode 2
            done
        done
    ;;
    "PREPROCESS")
        echo "Processing PREPROCESS"
        # Add your command here
        preprocdir=`echo "${dir_mapping[$processing_step]}"`

        for bvalue in 0 400 1000 2600; do
            bfile=meanb$bvalue
            echo "Visualization of $bfile"
            mrview $preprocdir/${bfile}_brain.mif.gz -mode 2
            #add the overlay of mask for B0 roi.load
        done
        #dwiextract -shells 0 
        dwiextract -bzero $preprocdir/dwi_den_unr_eddy.mif.gz - | mrmath -force -axis 3 - mean - | mrview - -mode 2 -roi.load $preprocdir/mask.mif.gz -roi.opacity 0.5
        #mask should be from b1000
        mrview $preprocdir/meanb1000_brain.mif.gz -mode 2 -roi.load $preprocdir/mask.mif.gz 
    ;;
    "RESPONSE")
        echo "Processing RESPONSE"
        # Add your command here
        responsedir=`echo "${dir_mapping[$processing_step]}"`
        response="dhollander_dwi_preproc_inorm"
        echo "Visualization of WM"
        shview  $responsedir/${response}_wm.txt
        echo "Visualization of GM"
        shview  $responsedir/${response}_gm.txt
        echo "Visualization of CSF"
        shview  $responsedir/${response}_csf.txt

        preprocdir=`echo "${dir_mapping[PREPROCESS]}"`
        mrview  $responsedir/dwi_preproc_inorm.mif.gz -overlay.load $responsedir/${response}_sf.mif.gz -overlay.opacity 0.5 -mode 2
    ;;
    "CSD")
        echo "Processing CSD"
        # Add your command here
        csddir=`echo "${dir_mapping[$processing_step]}"`
        response=dhollander
        responsenorm=dwi_preproc_inorm
        mrview -load $csddir/dwi_preproc_inorm.mif.gz -odf.load_sh $csddir/$response/csd_${response}_${responsenorm}_wm_2tt.mif.gz -mode 2
    ;;
    "5TT")
        echo "Processing 5TT"
        # Add your command here
        tt5dir=`echo "${dir_mapping[$processing_step]}"`

        mrview  ${tt5dir}/sub-${sID}_ses-${ssID}_5TT.nii.gz 
    ;;
    "REGISTRATION")
        echo "Processing REGISTRATION"
        # Add your command here
        registrationdir=`echo "${dir_mapping[$processing_step]}"`

        mrview  $registrationdir/dwi/T2w_brain_coreg.mif.gz -overlay.load $registrationdir/dwi/meanb1000_brain_brain.nii.gz -overlay.opacity 0.5 -mode 2
        mrview  $registrationdir/dwi/T2w_brain_coreg.mif.gz -overlay.load $registrationdir/dwi/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz -overlay.opacity 0.7 -mode 2
        mrview  $registrationdir/dwi/T2w_brain_coreg.mif.gz -overlay.load $registrationdir/dwi/parcellation/neonatal-5TT-M-CRIB/segmentations/Structural_Labels_coreg.mif.gz -overlay.opacity 0.7 -mode 2
    ;;
    "TRACTOGRAPHY")
        echo "Processing TRACTOGRAPHY"
        # Add your command here
        tractographydir=`echo "${dir_mapping[$processing_step]}"`
        registrationdir=`echo "${dir_mapping[REGISTRATION]}"`

        mrview $tractographydir/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz  -tractography.load $tractographydir/tractography/neonatal-5TT-M-CRIB/whole_brain_10M_edit100k.tck
        mrview $registrationdir/dwi/T2w_brain_coreg.mif.gz  -tractography.load $tractographydir/tractography/neonatal-5TT-M-CRIB/whole_brain_10M_edit100k.tck

    ;;
    "TRACTOGRAPHY_ROI")
        echo "Processing TRACTOGRAPHY"
        # Add your command here
        tractographydir=`echo "${dir_mapping[$processing_step]}"`
        registrationdir=`echo "${dir_mapping[REGISTRATION]}"`

        mrview $tractographydir/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz  -tractography.load $tractographydir/tractography/neonatal-5TT-M-CRIB/whole_brain_10M_edit100k.tck
        mrview $registrationdir/dwi/T2w_brain_coreg.mif.gz  -tractography.load $tractographydir/tractography/neonatal-5TT-M-CRIB/whole_brain_10M_edit100k.tck

    ;;
    "CONNECTOME")
        echo "Processing CONNECTOME"
        # Add your command here
        python $PWD/code/zagreb_dhcp/dMRI/pipeline/heatmap_plotting.py $sID $ssID
    ;;
    *)
        echo "Invalid processing_step: $processing_step"
        usage
    ;;
esac