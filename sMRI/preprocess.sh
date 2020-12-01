#!/bin/bash
#
## sMRI preprocess
# 1. Creating brain mask (in T2w space)
# 2. Additional?
#

# Input subject and session
sID=$1
ssID=$2

# Defining Folders
codeFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studyFolder=`pwd`
sourcedataFolder=sourcedata/sub-$sID/ses-$ssID/anat
derivativesFolder=derivatives/sMRI-preprocess/sub-$sID/ses-$ssID
logFolder=derivatives/preprocessing_logs/sub-$sID/ses-$ssID
if [ ! -d $derivativesFolder ];then mkdir -p $derivativesFolder; fi
if [ ! -d $logFolder ];then mkdir -p $logFolder; fi

echo sMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codeFolder/sMRI/$script.sh $@ > ${logFolder}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logFolder}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logFolder}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codeFolder/$script.sh >> ${logFolder}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

# Define files
t1w=sub-${sID}_ses-${ssID}_T1w
t2w=sub-${sID}_ses-${ssID}_T2w
flair=sub-${sID}_ses-${ssID}_FLAIR
# and copy to derivatives-folder
cp $sourcedataFolder/$t1w.nii.gz $sourcedataFolder/$t2w.nii.gz $sourcedataFolder/$flair.nii.gz $derivativesFolder/.

##################################################################################
## 1. Creating brain mask

cd $derivativesFolder

# Register FLAIR(=moving file) T2w(=ref file) and transform into T2w-space
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz ];then
    if [ ! -d reg ]; then mkdir -p reg; fi
    flirt -in $flair.nii.gz -ref $t2w.nii.gz -omat reg/${flair}_2_${t2w}_flirt.mat -dof 6
    flirt -in $flair.nii.gz -ref $t2w.nii.gz -out sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz -init reg/${flair}_2_${t2w}_flirt.mat -applyxfm
fi

# Create the brain mask in T2w-space
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz ];then
    
    # Perform brain extraction on FLAIR and dilate x2
    bet sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain.nii.gz -m -R
    fslmaths sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain.nii.gz -dilM -dilM sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask-dilMx2.nii.gz
    # Multiply mask to skull-stripp T2w 
    fslmaths $t2w.nii.gz -mul sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask-dilMx2 ${t2w}_skullstripped.nii.gz
    # and perform bet on skull-stripped T2w 
    bet ${t2w}_skullstripped.nii.gz ${t2w}_brain.nii.gz -m -R -F #f 0.3
    mv ${t2w}_brain.nii.gz sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz

    # Clean-up
    rm *brain* *skullstripped*
fi
cd $studyFolder

##################################################################################
## Additional?
#
#
##################################################################################
