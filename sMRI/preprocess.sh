#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Script to register FLAIR and T2w and to create brain mask in T2 space for neonatal-segmentation
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -T2				T2 image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_T2w.nii.gz)
  -FLAIR			FLAIR image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_FLAIR.nii.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/sMRI_preproc)
  -r / -reg-dir  <directory>   	The directory used to output registrations (default: derivatives/registrations)
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
t2w=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_T2w.nii.gz
flair=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_FLAIR.nii.gz
regdir=derivatives/registrations/sub-$sID/ses-$ssID
datadir=derivatives/sMRI_preproc/sub-$sID/ses-$ssID

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; tw2=$1; ;;
	-FLAIR) shift; flair=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-r|-reg-dir)  shift; regdir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration and Creation of brain mask in T2 space
Subject:       $sID 
Session:       $ssID
T2:	       $t2w 
FLAIR:         $flair
Directory:     $datadir 
Registration:  $regdir
$BASH_SOURCE   $command
----------------------------"

logdir=derivatives/preprocessing_logs/sub-$sID/ses-$ssID
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $regdir ];then mkdir -p $regdir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo sMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to datadir and regdir
cp $t2w $flair $datadir/.
cp $t2w $flair $regdir/.

#Then update the flair and t2w variables to only refer to filebase names
t2w=sub-${sID}_ses-${ssID}_T2w
flair=sub-${sID}_ses-${ssID}_FLAIR


##################################################################################
## 1. Registration
cd $regdir

# Register FLAIR(=moving file) T2w(=ref file) and transform into T2w-space
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz ];then
    if [ ! -d reg ]; then mkdir -p reg; fi
    flirt -in $flair.nii.gz -ref $t2w.nii.gz -omat reg/${flair}_2_${t2w}_flirt.mat -dof 6
    flirt -in $flair.nii.gz -ref $t2w.nii.gz -out sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz -init reg/${flair}_2_${t2w}_flirt.mat -applyxfm
fi

cd $currdir
# Copy FLAIR transformed in T2 space to $datadir
cp $regdir/sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz $datadir/.

##################################################################################
## 2. Create brain mask in T2w-space
cd $datadir
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz ];then
    
    # Perform brain extraction on FLAIR and dilate x2 - use -F option
    bet sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain.nii.gz -m -R -F
    #fslmaths sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain.nii.gz -dilM -dilM sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask-dilMx2.nii.gz
    # Multiply mask to skull-stripp T2w 
    fslmaths $t2w.nii.gz -mul sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask.nii.gz ${t2w}_skullstripped.nii.gz
    #fslmaths $t2w.nii.gz -mul sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask-dilMx2 ${t2w}_skullstripped.nii.gz
    # and perform bet on skull-stripped T2w using -F flag
    bet ${t2w}_skullstripped.nii.gz ${t2w}_brain.nii.gz -m -R -F #f 0.3
    mv ${t2w}_brain_mask.nii.gz sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz

    # Clean-up
    rm *brain* *skullstripped*
fi
cd $currdir

##################################################################################
## Additional?
#
#
##################################################################################
