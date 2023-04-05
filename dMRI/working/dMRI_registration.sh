#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Rigid-body linear registration of dMRI (meanb1000) to sMRI (T2)
Then tranformation into dMRI space (by updating headers = no resampling) of
- T2 (used for segmentation)
- 5TT image (in T2-space) created from segmentation (also used for BBR segmentation)
- labels parcellation image (in T2-space) created from segmentation

Arguments:
  sID				Subject ID (e.g. PMRABC) 
  ssID                       	Session ID (e.g. MR2)

Options:
  -meanb1000			Undistorted brain extracted dMRI mean b1000 image  (default: derivatives/dMRI_preproc/sub-sID/ses-ssID/meanb1000_brain.nii.gz)

  -T2				T2 that has been segmented and will be registered to, should be N4-corrected and brain extracted (default: derivatives/sMRI_neonatal_segmentation/sub-$sID/ses-$ssID/N4/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz)

  -m / -method			Method with which the segmentation was done (options DrawEM or neonatal-5TT) (default: neonatal-5TT)

  -a / -atlas			Atlas used for segmentation (options ALBERT or M-CRIB) 
       				(default DrawEM: ALBERT)
				(default neonatal-5TT: M-CRIB)

  -5TT				5TT image of T2, to use for BBR reg and to be transformed into dMRI space 
  				(default DrawEM: derivatives/sMRI/sub-sID/ses-ssID/5TT_\$method-\$atlas/sub-sID_ses-ssID_desc-preproc_T2w_5TT.nii.gz) 
				(default M-CRIB: derivatives/sMRI/sub-sID/ses-ssID/5TT_\$method-\$atlas/sub-sID_ses-ssID_desc-preproc_T2w_5TT.nii.gz)

  -label			Label file from segmentation, to be transformed into dMRI space 
  				(default DrawEM: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation/segmentations/sub-sID_ses-ssID_desc-preproc_T2w_all_labels.nii.gz)
				(default neonatal-5TT: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentaion/5TT_neonatal-5TT-M-CRIB/sub-sID_ses-ssID_desc-preproc_T2w_M-CRIB_Structural_Labels.nii.gz)
  -label_LUT			LUT for label file 
  				(default ALBERT: codedir/../label_names/ALBERT/all_labels.txt)
  				(default M-CRIB: codedir/../label_names/M-CRIB/Structural_Labels.txt)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_registration/sub-sID/ses-ssID)

  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2
shift; shift

currdir=$PWD

# START Defaults
meanb1000=derivatives/dMRI_preproc/sub-$sID/ses-$ssID/meanb1000_brain.nii.gz
T2=derivatives/sMRI_neonatal_segmentation/sub-$sID/ses-$ssID/N4/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz
datadir=derivatives/dMRI_registration/sub-$sID/ses-$ssID
method=neonatal-5TT
atlas="M-CRIB"

# Set defaults dependning on method and atlas
while [ $# -gt 0 ]; do
    case "$1" in
	-m|-method) shift; method=$1; ;;
	-a|-atlas) shift; atlas=$1; ;;
    esac
    shift
done
# now set defaults depending on method and atlas
case "$method" in
    DrawEM)
	if [ $atlas == "ALBERT" ]; then
	    allLabel=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_T2w_all_labels.nii.gz;
	    allLabelLUT=$codedir/../label_names/$atlas/all_labels.txt;
	fi		     
	;;    
    neonatal-5TT)
	if [ $atlas == "M-CRIB" ]; then
	    allLabel=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/5TT_${method}-$atlas/sub-${sID}_ses-${ssID}_desc-preproc_T2w_Structural_Labels.nii.gz;
	    allLabelLUT=$codedir/../label_names/$atlas/Structural_Labels.txt;
	fi
	;;
esac
act5tt=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/5TT_${method}-$atlas/sub-${sID}_ses-${ssID}_desc-preproc_T2w_5TT.nii.gz
# END Defaults

while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; T2=$1; ;;
	-meanb1000) shift; meanb1000=$1; ;;
	-label) shift; allLabel=$1; ;;
	-label_LUT) shift; allLabelLUT=$1; ;;
	-5TT) shift; act5tt=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       	   $sID 
Session:       	   $ssID
meanb1000:	       	   $meanb1000
Atlas:	       	   $atlas     
T2:		   $T2
5TT:           	   $act5tt
Labels file:   	   $allLabel
Labels LUT:	   $allLabelLUT
Directory:     	   $datadir 
$BASH_SOURCE   	   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to relevant location in $datadir (incl .json if present at original location)

# Files to go into different locations in $datadir 
for file in $meanb1000 $T2 $act5tt $allLabel; do
    origdir=`dirname $file`
    filebase=`basename $file .nii.gz`
    
    if [[ $file = $meanb1000 ]]; then outdir=$datadir/dwi;fi
    if [[ $file = $T2 ]]; then outdir=$datadir/anat;fi
    if [[ $file = $act5tt ]]; then actdir=act/${method}-$atlas; outdir=$datadir/dwi/$actdir;fi
    if [[ $file = $allLabel ]]; then outdir=$datadir/dwi/parcellation/${method}-$atlas/segmentations;fi

    if [ ! -d $outdir ];then mkdir -p $outdir;fi
			     
    if [ ! -f $datadir/$filebase.nii.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# LUT to copy
LUTdir=dwi/parcellation/$method-$atlas/label_names
if [ ! -d $datadir/$LUTdir ]; then mkdir -p $datadir/$LUTdir ]; fi
for file in $allLabelLUT; do
    filebase=`basename $file`
    if [ ! -f $datadir/$LUTdir/$filebase ];then
	cp $file $datadir/$LUTdir/.
    fi
done

# Update variables to point at corresponding filebases in $datadir
T2=`basename $T2 .nii.gz`
meanb1000=`basename $meanb1000 .nii.gz`
act5tt=`basename $act5tt .nii.gz`
allLabel=`basename $allLabel .nii.gz`
allLabelLUT=`basename $allLabelLUT .txt`

##################################################################################
## 1. Do registrations and transform into dMRI space
# Adaption from mine and Kerstin Pannek's MRtrix posts: https://community.mrtrix.org/t/registration-of-structural-and-diffusion-weighted-data/203/8?u=finn

cd $datadir

# Do registrations in subfolder xfm

if [ ! -d xfm ]; then mkdir xfm; fi

# Do brain extractions of meanb1000 and T2 before linear registration
if [ ! -f dwi/${meanb1000}_brain.nii.gz ];then
    bet dwi/$meanb1000.nii.gz dwi/${meanb1000}_brain.nii.gz -F -R
fi
# NOTE - desc-preproc is brain extracted, make this mock so that it is clear that a _brain file goes in to FLIRT below
if [ ! -f anat/${T2}_brain.nii.gz ];then
    cp anat/$T2.nii.gz anat/${T2}_brain.nii.gz
fi
     
# Registration using BBR
if [ ! -f xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat ];then 
    echo "Rigid-body linear registration using FSL's FLIRT with BBR"
    
    # First, make sure that we have a WM seg in $actdir
    wmseg=${T2}_5TTwm;
    if [ ! -f dwi/$actdir/$wmseg.nii.gz ]; then
	# Extract WM from 5TT image and save as 3D image
	mrconvert -coord 3 2 -axes 0,1,2 dwi/$actdir/${T2}_5TT.nii.gz dwi/$actdir/$wmseg.nii.gz 
    fi

    # Second, perform 2-step registration
    flirt -in dwi/${meanb1000}_brain.nii.gz -ref anat/${T2}_brain.nii.gz -dof 6 -omat xfm/tmp.mat
    flirt -in dwi/${meanb1000}_brain.nii.gz -ref anat/${T2}_brain.nii.gz -dof 6 -cost bbr -wmseg dwi/$actdir/$wmseg.nii.gz -init xfm/tmp.mat -omat xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat -schedule $FSLDIR/etc/flirtsch/bbr.sch
    rm xfm/tmp.mat
fi

# Transform FLIRT registration matrix into MRtrix format
if [ ! -f xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat ];then
     transformconvert xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat dwi/${meanb1000}_brain.nii.gz anat/$T2.nii.gz flirt_import xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat
fi
     

cd $currdir

####################################################################################################
## 2. Transformations of T2, 5TT, allLabels-file into dMRI space by updating image headers (no resampling!)

cd $datadir

# T2
if [ ! -f anat/${T2}_space-dwi.nii.gz ]; then
    mrtransform anat/$T2.nii.gz -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat anat/${T2}_space-dwi.nii.gz -inverse
    mrconvert anat/${T2}_space-dwi.nii.gz dwi/T2w_coreg.mif.gz
fi

# Take care of 5TT
if [ ! -f  dwi/$actdir/${act5tt}_space-dwi.nii.gz ]; then
    mrtransform dwi/$actdir/$act5tt.nii.gz -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat dwi/$actdir/${act5tt}_space-dwi.nii.gz -inverse
    mrconvert dwi/$actdir/${act5tt}_space-dwi.nii.gz dwi/$actdir/5TT_coreg.mif.gz
fi

# Take care of all_labels
labeldir=dwi/parcellation/$method-$atlas/segmentations
if [ ! -f $labeldir/${allLabel}_space-dwi.nii.gz ]; then
    mrtransform $labeldir/$allLabel.nii.gz -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat $labeldir/${allLabel}_space-dwi.nii.gz -inverse
    mrconvert $labeldir/${allLabel}_space-dwi.nii.gz $labeldir/${allLabelLUT}_coreg.mif.gz
fi

cd $currdir
