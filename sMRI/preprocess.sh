#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Script to register anatomical sequences (i.e. FLAIR, cor T2w and tra T2w) to 3D-T2w, \
make high-resolution versions tra T2w and cor T2w, \
create relevant brain masks for neonatal-segmentation \
and to further preproc of sMRI data.
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -T2				T2 image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_T2w.nii.gz)
  -FLAIR			FLAIR image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_FLAIR.nii.gz)
  -corT2			Cor T2 image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_acq-cor_T2w.nii.gz)
  -traT2			Tra T2 image (default: sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_acq-tra_T2w.nii.gz)
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
t2wcor=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_acq-cor_T2w.nii.gz
t2wtra=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_acq-tra_T2w.nii.gz
flair=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_FLAIR.nii.gz
regdir=derivatives/registrations/sub-$sID/ses-$ssID
datadir=derivatives/sMRI_preproc/sub-$sID/ses-$ssID

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; tw2=$1; ;;
	-corT2) shift; tw2cor=$1; ;;
	-traT2) shift; tw2tra=$1; ;;
	-FLAIR) shift; flair=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-r|-reg-dir)  shift; regdir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $tw2 ]; then tw2=""; fi
if [ ! -f $flair ]; then flair=""; fi
if [ ! -f $tw2cor ]; then tw2cor=""; fi
if [ ! -f $tw2tra ]; then tw2tra=""; fi

echo "Registration and sMRI-processing
Subject:       $sID 
Session:       $ssID
T2:	       $t2w 
corT2:	       $t2wcor	       
traT2:	       $t2wtra
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
cp $t2w $t2wcor $t2wtra $flair $datadir/.
cp $t2w $t2wcor $t2wtra $flair $regdir/.

#Then update the flair and t2w variables to only refer to filebase names (instead of path/file)
t2w=`basename $t2w .nii.gz` #sub-${sID}_ses-${ssID}_T2w
t2wcor=`basename $t2wcor .nii.gz` #sub-${sID}_ses-${ssID}_acq-cor_T2w
t2wtra=`basename $t2wtra .nii.gz` #sub-${sID}_ses-${ssID}_acq-tra_T2w
flair=`basename $flair .nii.gz` #sub-${sID}_ses-${ssID}_FLAIR

##################################################################################
# 1. Upsample cor T2w and tra T2w (required for DrawEM neonatal-segmentation)
cd $regdir

## Take care of the cor T2w and tra T2w seperately (easier)
# cor T2w
image=$t2wcor;
if [[ $image = "" ]];then
    echo "No cor T2w image";
else
    if [[ $image = sub-${sID}_ses-${ssID}_acq-cor_T2w ]];then
	# BIDS compliant highres name 
	highres=`echo $image | sed 's/\_T2w/\_desc\-hires\_T2w/g'`
    else
	# or else, just add desc-highres before the file name
	highres=desc-hires_${image}
    fi
    # Do interpolation (spline)
    if [ ! -f $highres.nii.gz ];then
	flirt -in $image.nii.gz -ref $image.nii.gz -applyisoxfm 0.8 -nosearch -out $highres.nii.gz -interp spline
    fi
    # and update t2wcor to point to highres
    t2wcor=$highres;
fi
# tra T2w
image=$t2wtra;
if [[ $image = "" ]];then echo "No tra T2w image";
else
    if [[ $image = sub-${sID}_ses-${ssID}_acq-tra_T2w ]];then
	# BIDS compliant highres name 
	highres=`echo $image | sed 's/\_T2w/\_desc\-hires\_T2w/g'`
    else
	# or else, just add desc-highres before the file name
	highres=desc-hires_${image}
    fi
    # Do interpolation (spline)
    if [ ! -f $highres.nii.gz ];then
	flirt -in $image.nii.gz -ref $image.nii.gz -applyisoxfm 0.8 -nosearch -out $highres.nii.gz -interp spline
    fi
    # and update t2wtra to point to highres
    t2wtra=$highres;
fi

cd $currdir
# and copy them to $datadir
cp $regdir/*desc-hires*.nii.gz $datadir/.

##################################################################################
## 1. Registration

# The T2w images have same contrast, don't need to register with brain_extraction before
# FLAIR image can be co-register to T2w as it is without brain_extraction, so let us stick with that as below

cd $regdir
if [ ! -d reg ]; then mkdir -p reg; fi

# Register moving images to reference 3D T2w
ref=$t2w
for moving in $flair $t2wcor $t2wtra; do
    
    # Affine registration with 6 dof
    flirt -in $moving.nii.gz -ref $ref.nii.gz -omat reg/${moving}_2_${ref}_flirt.mat -dof 6

    # For the FLAIR we want to transform in 3D T2w-space
    if [[ $moving = $flair ]]; then
	if [[ $moving = sub-${sID}_ses-${ssID}_FLAIR ]];then
	    # BIDS compliant space name 
	    outimage=`echo $moving | sed 's/\_FLAIR/\_space\-T2w\_FLAIR/g'`;
	else
	    # or else, just add space-T2w before the file name
	    outimage=space-T2w_${moving};
	fi
	# then transform
	flirt -in $moving.nii.gz -ref $ref.nii.gz -out $outimage.nii.gz -init reg/${moving}_2_${ref}_flirt.mat -applyxfm;
    fi;
    
done

cd $currdir
# Copy images transformed in T2 space to $datadir
cp $regdir/*space-T2w*.nii.gz $datadir/.


##################################################################################
## 2. Create brain mask in T2w-space
cd $datadir
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz ];then
    
    # Perform brain extraction on FLAIR and dilate x2 - use -F option
    bet sub-${sID}_ses-${ssID}_space-T2w_FLAIR.nii.gz sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain.nii.gz -m -R -F
    
    # Multiply mask to skull-stripp T2w 
    fslmaths $t2w.nii.gz -mul sub-${sID}_ses-${ssID}_space-T2w_FLAIR_brain_mask.nii.gz ${t2w}_skullstripped.nii.gz

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
