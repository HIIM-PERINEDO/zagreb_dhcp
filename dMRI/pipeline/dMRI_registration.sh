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
  -meanb1000			Undistorted brain extracted dMRI mean b1000 image  (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/preproc/meanb1000_brain.nii.gz)

  -T2				T2 that has been segmented and will be registered to, should be N4-corrected and brain extracted (default: derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz)

  -m / -method			Method with which the segmentation was done (options DrawEM or later if default neonatal-5TT) (default: neonatal-5TT)

  -a / -atlas			Atlas used for segmentation (options ALBERT or M-CRIB) 
       				(default DrawEM: ALBERT)
				(default  neonatal-5TT: M-CRIB)

  -5TT				5TT image of T2, to use for BBR reg and to be transformed into dMRI space 
  				(default DrawEM: derivatives/dMRI/sub-sID/ses-ssID/dwi/neonatal_5tt_mcrib/sub-sID_ses-ssID_5TT.nii.gz) 
				( M-CRIB: derivatives/dMRI/sub-sID/ses-ssID/dwi/neonatal_5tt_mcrib/sub-sID_ses-ssID_5TT.nii.gz)
                

  -label			Label file from segmentation, to be transformed into dMRI space 
  				(default DrawEM: derivatives/sMRI_neonatal_segmentation/sub-sID/ses-ssID/segmentations/sub-sID_ses-ssID_desc-preproc_T2w_all_labels.nii.gz)
				(default neonatal-5TT: derivatives/dMRI/sub-sID/ses-ssID/dwi/neonatal_5tt_mcrib/sub-sID_ses-ssID_desc-mcrib_dseg.nii.gz)

  -label_LUT			LUT for label file 
  				(default ALBERT: codedir/../label_names/ALBERT/all_labels.txt)
  				(later if implemented  M-CRIB: codedir/../label_names/M-CRIB/Structural_Labels.txt)

  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_registration/sub-sID/ses-ssID)

  -h / -help / --help           Print usage.
"
  exit;
}
#-meanb1000			Undistorted brain extracted dMRI mean b1000 image  (default: derivatives/dMRI_preproc/sub-sID/ses-ssID/meanb1000_brain.nii.gz)
#-T2				T2 that has been segmented and will be registered to, should be N4-corrected and brain extracted (default: derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz)
#-5TT				5TT image of T2, to use for BBR reg and to be transformed into dMRI space 
#  				(default DrawEM: derivatives/dMRI_neonatal_5tt_mcrib/sub-sID/ses-ssID/sub-sID_ses-ssID_5TT.nii.gz) 
#				(later if implemented  M-CRIB: derivatives/dMRI_neonatal_5tt_mcrib/sub-sID/ses-ssID/sub-sID_ses-ssID_5TT.nii.gz)
#-label			Label file from segmentation, to be transformed into dMRI space 
#  				(default DrawEM: derivatives/sMRI_neonatal_segmentation/sub-sID/ses-ssID/segmentations/sub-sID_ses-ssID_desc-preproc_T2w_all_labels.nii.gz)
#				(default neonatal-5TT: derivatives/dMRI_neonatal_5tt_mcrib/sub-sID/ses-ssID/sub-sID_ses-ssID_desc-mcrib_dseg.nii.gz)

################ ARGUMENTS ################

# check whether the different tools are set and load parameters

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2
shift; shift

currdir=$PWD

# START Defaults
meanb1000=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/preproc/meanb1000_brain.nii.gz #meanb1000=derivatives/dMRI_preproc/sub-$sID/ses-$ssID/meanb1000_brain.nii.gz
T2=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz #T2=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz
T2_brain_mask=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib/sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz #T2_brain_mask=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib/sub-${sID}_ses-${ssID}_5TT.nii.gz #ct5tt=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_5TT.nii.gz
csd_wm_2tt=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/csd/dhollander/csd_dhollander_dwi_preproc_inorm_wm_2tt.mif.gz #csd_wm_2tt=derivatives/dMRI_csd/sub-$sID/ses-$ssID/dhollander/csd_dhollander_wm_2tt.mif.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration #datadir=derivatives/dMRI_registration/sub-$sID/ses-$ssID
method="neonatal-5TT" #DrawEM
atlas="M-CRIB" #ALBERT
codedir=code/zagreb_dhcp

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
	    allLabel=derivatives/sMRI_neonatal_segmentation/sub-$sID/ses-$ssID/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_T2w_all_labels.nii.gz;
	    allLabelLUT=$codedir/label_names/$atlas/all_labels.txt;
	fi		     
	;;    
   neonatal-5TT)
	if [ $atlas == "M-CRIB" ]; then
        allLabel=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib/sub-${sID}_ses-${ssID}_desc-mcrib_dseg.nii.gz;
        allLabelLUT=$codedir/label_names/$atlas/Structural_Labels.txt;
	fi
	;;
esac

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

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to relevant location in $datadir (incl .json if present at original location)

# Files to go into different locations in $datadir 
for file in $meanb1000 $T2 $act5tt $allLabel $csd_wm_2tt $T2_brain_mask; do
    origdir=`dirname $file`
    filebase=`basename $file .nii.gz`
    
    if [[ $file = $meanb1000 ]]; then outdir=$datadir/dwi;fi
    if [[ $file = $T2 ]]; then outdir=$datadir/anat;fi
    if [[ $file = $T2_brain_mask ]]; then outdir=$datadir/anat;fi
    if [[ $file = $act5tt ]]; then actdir=act/${method}-$atlas; outdir=$datadir/dwi/$actdir;fi
    if [[ $file = $allLabel ]]; then outdir=$datadir/dwi/parcellation/${method}-$atlas/segmentations;fi
    if [[ $file = $csd_wm_2tt ]]; then outdir=$datadir/dwi/csd;fi


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
T2_brain_mask=`basename $T2_brain_mask .nii.gz`

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
    #bet anat/$T2.nii.gz anat/${T2}_brain.nii.gz -m -R -f 0.3 #this was just cp
    mrcalc anat/$T2.nii.gz anat/$T2_brain_mask.nii.gz -mult anat/${T2}_brain.nii.gz
    #cp anat/$T2.nii.gz anat/${T2}_brain.nii.gz
fi
     
# Registration using BBR
if [ ! -f xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat ];then 
    echo "Rigid-body linear registration using FSL's FLIRT with BBR"
    
    # First, make sure that we have a WM seg in $actdir
    wmseg=${T2}_5TTwm;
    if [ ! -f dwi/$actdir/$wmseg.nii.gz ]; then
	# Extract WM from 5TT image and save as 3D image
    dwi_T2=sub-${sID}_ses-${ssID}
	mrconvert -coord 3 2 -axes 0,1,2 dwi/$actdir/${dwi_T2}_5TT.nii.gz dwi/$actdir/$wmseg.nii.gz 
    fi

    # Second, perform 2-step registration
    flirt -dof 6 -in dwi/${meanb1000}_brain.nii.gz -ref anat/${T2}_brain.nii.gz -omat xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat  #xfm/tmp.mat
    flirt -dof 6 -cost bbr -wmseg dwi/$actdir/$wmseg.nii.gz -init xfm/tmp.mat -schedule $FSLDIR/etc/flirtsch/bbr.sch -in dwi/${meanb1000}_brain.nii.gz -ref anat/${T2}_brain.nii.gz -omat xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat 
    rm xfm/tmp.mat
    #new
    #flirt -dof 6 -cost bbr -wmseg dwi/$actdir/$wmseg.nii.gz -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -bins 256 -interp spline -in dwi/${meanb1000}_brain.nii.gz -ref anat/${T2}_brain.nii.gz -omat xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat
    # -cost bbr -wmseg dwi/$actdir/$wmseg.nii.gz -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -bins 256 -interp spline
fi

# Transform FLIRT registration matrix into MRtrix format
if [ ! -f xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat ];then
    #transformconvert xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat dwi/${meanb1000}_brain.nii.gz anat/$T2.nii.gz flirt_import xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat
    transformconvert xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_flirt-bbr.mat dwi/${meanb1000}_brain.nii.gz anat/${T2}_brain.nii.gz flirt_import xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat
fi
     

cd $currdir

####################################################################################################
## 2. Transformations of T2, 5TT, allLabels-file into dMRI space by updating image headers (no resampling!)

cd $datadir

# T2
if [ ! -f anat/${T2}_space-dwi.nii.gz ]; then
    mrtransform -inverse -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat  anat/$T2.nii.gz anat/${T2}_space-dwi.nii.gz 
    mrconvert anat/${T2}_space-dwi.nii.gz dwi/T2w_coreg.mif.gz
fi

#T2 brain
if [ ! -f anat/${T2}_brain_space-dwi.nii.gz ]; then
    mrtransform -inverse -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat anat/${T2}_brain.nii.gz anat/${T2}_brain_space-dwi.nii.gz 
    mrconvert anat/${T2}_brain_space-dwi.nii.gz dwi/T2w_brain_coreg.mif.gz
fi

# Take care of 5TT
if [ ! -f  dwi/$actdir/${act5tt}_space-dwi.nii.gz ]; then
    mrtransform -inverse -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat dwi/$actdir/$act5tt.nii.gz dwi/$actdir/${act5tt}_space-dwi.nii.gz 
    mrconvert dwi/$actdir/${act5tt}_space-dwi.nii.gz dwi/$actdir/5TT_coreg.mif.gz
fi

# Take care of all_labels
labeldir=dwi/parcellation/$method-$atlas/segmentations
if [ ! -f $labeldir/${allLabel}_space-dwi.nii.gz ]; then
    mrtransform  -inverse -linear xfm/sub-${sID}_ses-${ssID}_from-dwi_to-T2w_mrtrix-bbr.mat $labeldir/$allLabel.nii.gz $labeldir/${allLabel}_space-dwi.nii.gz
    mrconvert $labeldir/${allLabel}_space-dwi.nii.gz $labeldir/${allLabelLUT}_coreg.mif.gz
fi

