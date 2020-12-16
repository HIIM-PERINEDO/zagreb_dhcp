#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Rigid-body linear registration of dMRI (meanb0) to sMRI (T2)
(NOTE - currently BBR registration does not work, to be explored with proper 3D T2w)
Then tranforms T2 and 5TT into dMRI space (by updating headers = no resampling)

Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -meanb0			Undistorted brain extracted dMRI mean b0 image  (default: derivatives/dMRI/sub-sID/ses-ssID/meanb0_brain.nii.gz)
  -T2				T2 to register to, should be N4-corrected brain extracted (default: derivatives/neonatal-segmentation/sub-sID/ses-ssID/N4/sub-sID_ses-ssID_T2w.nii.gz)
  -5TT				5TT image of T2, to use for BBR reg and to be transformed into dMRI space (default: derivatives/neonatal-segmentation/sub-sID/ses-ssID/5TT/sub-sID_ses-ssID_T2w_5TT.nii.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID)
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

# Defaults
meanb0=derivatives/dMRI/sub-$sID/ses-$ssID/meanb0.nii.gz
T2=derivatives/neonatal-segmentation/sub-$sID/ses-$ssID/N4/sub-${sID}_ses-${ssID}_T2w.nii.gz
act5tt=derivatives/neonatal-segmentation/sub-$sID/ses-$ssID/5TT/sub-${sID}_ses-${ssID}_T2w_5TT.nii.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; T2=$1; ;;
	-meanb0) shift; meanb0=$1; ;;
	-5TT) shift; act5tt=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       $sID 
Session:       $ssID
meanb0:	       $meanb0
T2:	       $T2
5TT:           $act5tt
Directory:     $datadir 
$BASH_SOURCE   $command
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

# Files to go into $datadir (exclusively for meanb0)
for file in $meanb0 $T2 $act5tt; do
    origdir=dirname $file
    filebase=`basename $file .nii.gz`
    
    if [[ $file = $meanb0 ]]; then outdir=$datadir;fi
    if [[ $file = $T2 ]]; then outdir=$datadir/registration;fi
    if [[ $file = $act5tt ]]; then outdir=$datadir/act;fi

    if [ ! -d $outdir ];then mkdir -p $outdir;fi
			     
    if [ ! -f $datadir/$filebase.nii.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# Update variables to point at corresponding filebases in $datadir
T2=`basename $T2 .nii.gz`
meanb0=`basename $meanb0 .nii.gz`
act5tt=`basename $act5tt .nii.gz`


##################################################################################
## 1. Do registrations and transform into dMRI space
# Adaption from mine and Kerstin Pannek's MRtrix posts: https://community.mrtrix.org/t/registration-of-structural-and-diffusion-weighted-data/203/8?u=finn

cd $datadir

# Do registrations
cd registration

# Do brain extractions of meanb0 and T2 before linear registration
if [ ! -f ${meanb0}_brain.nii.gz ];then
    bet ../$meanb0.nii.gz ${meanb0}_brain.nii.gz -F -R
fi
if [ ! -f ${T2}_brain.nii.gz ];then
    bet $T2.nii.gz ${T2}_brain.nii.gz -F -R
fi
     
# Registration
echo "Rigid-body linear registration using FSL's FLIRT"
flirt -in ${meanb0}_brain.nii.gz -ref ${T2}_brain.nii.gz -dof 6 -omat reg/${meanb0}_2_${T2}_flirt-dof6.mat

# Transform FLIRT registration matrix into MRtrix format
transformconvert reg/${meanb0}_2_${T2}_flirt-dof6.mat ${meanb0}_brain.nii.gz $T2.nii.gz flirt_import reg/${meanb0}_2_${T2}_mrtrix-dof6.mat

# Then transform T2, 5TT, labels-file into dMRI space by updating image headers (no resampling!)
mrtransform $T2.nii.gz -linear reg/${meanb0}_2_${T2}_mrtrix-dof6.mat ${T2}_space-dwi.nii.gz -inverse
mrconvert ${T2}_space-dwi.nii.gz ../T2w_coreg.mif.gz

# Go to ACT folder
cd ../act
mrtransform $act5tt.nii.gz -linear ../registration/reg/${meanb0}_2_${T2}_mrtrix-dof6.mat ${act5tt}_space-dwi.nii.gz -inverse
ln -s ${act5tt}_space-dwi.nii.gz 5TT.mif.gz

# Create some visualisationclean-up
#rm *tmp* reg/*tmp*

cd $currdir
