#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Script to preprocess dMRI data 
1. denoising and unringing 
2. TOPUP and EDDY 
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -dwi				dMRI AP data (default: sourcedata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-AP_dwi.nii.gz)
  -dwiAPsbref			dMRI AP SBRef, potentially for registration and  TOPUP  (default: sourcedata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-AP_sbref.nii.gz)
  -dwiPA			dMRI PA data, potentially for TOPUP  (default: sourcedata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-PA_dwi.nii.gz)
  -dwiPAsbref			dMRI PA SBRef, potentially for registration and TOPUP  (default: sourcedata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-PA_sbref.nii.gz)
  -seAP				Spin-echo field map AP, for TOPUP (default: sourcedata/sub-sID/ses-ssID/fmap/sub-sID_ses-ssID_dir-AP_epi.nii.gz)
  -sePA				Spin-echo field map PA, for TOPUP (default: sourcedata/sub-sID/ses-ssID/fmap/sub-sID_ses-ssID_dir-PA_epi.nii.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_preproc)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2

currdir=`pwd`

dwi=sourcedata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-AP_dwi.nii.gz
dwiPA=sourcedata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-PA_dwi.nii.gz
dwiAPsbref=sourcedata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-AP_sbref.nii.gz
dwiPAsbref=sourcedata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-PA_sbref.nii.gz
seAP=sourcedata/sub-$sID/ses-$ssID/fmap/sub-${sID}_ses-${ssID}_dir-AP_epi.nii.gz
sePA=sourcedata/sub-$sID/ses-$ssID/fmap/sub-${sID}_ses-${ssID}_dir-PA_epi.nii.gz

datadir=derivatives/dMRI_preproc/sub-$sID/ses-$ssID

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-dwi) shift; dwi=$1; ;;
	-dwiAPsbref) shift; dwiAPsbref=$1; ;;
	-dwiPA) shift; dwiPA=$1; ;;
	-dwiPAsbref) shift; dwiPAsbref=$1; ;;
	-seAP) shift; seAP=$1; ;;
	-seAP) shift; sePA=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
#if [ ! -f $dwi ]; then dwi=""; fi
#if [ ! -f $dwiAPsbref ]; then dwiAPsbref=""; fi
#if [ ! -f $dwiPA ]; then dwiPA=""; fi
#if [ ! -f $dwiPAsbref ]; then dwiPAsbref=""; fi
#if [ ! -f $seAP ]; then seAP=""; fi
#if [ ! -f $sePA ]; then sePA=""; fi

echo "Registration and sMRI-processing
Subject:       $sID 
Session:       $ssID
DWI (AP):      $dwi
DWI (APSBRef): $dwiAPsbref
DWI (PA):      $dwiPA
DWI (PASBRef): $dwiPAsbref
SE fMAP (AP):  $seAP	       
SE fMAP (PA):  $sePA	       
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=derivatives/preprocessing_logs/sub-$sID/ses-$ssID
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to datadir (incl .json and bvecs/bvals files if present at original location)
filelist="$dwi $dwiAPsbref $dwiPA $dwiPAsbref $seAP $sePA"
for file in $filelist; do
    filebase=`basename $file .nii.gz`;
    filedir=`dirname $file`
    cp $file $filedir/$filebase.json $filedir/$filebase.bval $filedir/$filebase.bvec $datadir/.

done

#Then update variables to only refer to filebase names (instead of path/file)
dwi=`basename $dwi .nii.gz` 
dwiAPsbref=`basename $dwiAPsbref .nii.gz` 
dwiPA=`basename $dwiPA .nii.gz`
dwiPAsbref=`basename $dwiPAsbref .nii.gz`
seAP=`basename $seAP .nii.gz`
sePA=`basename $sePA .nii.gz`


##################################################################################
# 0. Create dwi.mif.gz to work with
cd $datadir

if [[ $dwi = "" ]];then
    echo "No dwi data provided";
    exit;
else
    # Create a dwi.mif.gz-file to work with
    if [ ! -f dwi.mif.gz ]; then
	mrconvert -json_import $dwi.json -fslgrad $dwi.bvec $dwi.bval $dwi.nii.gz dwi.mif.gz
    fi
fi

cd $currdir

##################################################################################
# 1. Do PCA-denoising
cd $datadir

# Directory for QC files
if [ ! -d denoise ]; then mkdir denoise; fi

# Perform PCA-denosing
if [ ! -f dwi_den.mif.gz ]; then
    # PCA-denoising
    dwidenoise dwi.mif.gz dwi_den.mif.gz -noise denoise/dwi_noise.mif.gz;
    # and calculate residuals
    mrcalc dwi.mif.gz dwi_den.mif.gz -subtract denoise/dwi_den_residuals.mif.gz
fi
cd $currdir

