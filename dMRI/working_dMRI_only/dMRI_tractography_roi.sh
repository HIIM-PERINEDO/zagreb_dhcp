#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Performs whole-brain tractography and SIFT-filtering

Arguments:
  sID				Subject ID (e.g. PMRxyz) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -csd				CSD mif.gz-file (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/csd/dhollander/csd_dhollander_wm_2tt.mif.gz)
  -5TT				5TT mif.gz-file in dMRI space (default: derivatives/dMRI_registration/sub-sID/ses-ssID/dwi/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz)
  -from
  -to
  -nbr				Number of streamlines in whole-brain tractogram (default: 10M)
  -threads			Number of threads for parallell processing (default: 24)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID/dwi/tractography)
  -h / -help / --help           Print usage.
"
  exit;
}
#  -csd				CSD mif.gz-file (default: derivatives/dMRI_csd/sub-sID/ses-ssID/csd/dhollander/csd_dhollander_wm_2tt.mif.gz)
#  -5TT				5TT mif.gz-file in dMRI space (default: derivatives/dMRI_registration/sub-sID/ses-ssID/dwi/act/neonatal-5TT-M-CRIB/5TT_coreg.mif.gz)
#  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_tractography/sub-sID/ses-ssID/dwi)

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2

currdir=$PWD

# Defaults
method=neonatal-5TT #DrawEM 
atlas="M-CRIB" #ALBERT 
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography_roi #datadir=derivatives/dMRI_tractography/sub-$sID/ses-$ssID
actdir=act/$method-$atlas
csddir=csd/$method-$atlas
tractdir=tractography/$method-$atlas
segmentationsdir=segmentations/$method-$atlas
from_roi=9
to_roi=1021

#csd=$datadir/$csddir/csd_msmt_5tt_wm_2tt.mif.gz
#act5tt=$datadir/$actdir/5TT_coreg.mif.gz
#csd=derivatives/dMRI_csd/sub-$sID/ses-$ssID/dhollander/csd_dhollander_wm_2tt.mif.gz

csd=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/csd/dhollander/csd_dhollander_dwi_preproc_inorm_wm_2tt.mif.gz #csd=derivatives/dMRI_registration/sub-$sID/ses-$ssID/dwi/csd/csd_dhollander_wm_2tt.mif.gz
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
    -to) shift; to_roi=$1; ;;
	-threads) shift; threads=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Whole-brain ACT tractography
Subject:       $sID 
Session:       $ssID
CSD:	       $csd
5TT:           $act5tt
Nbr:	       $nbr
Threads:       $threads
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo


##################################################################################
# 0. Copy to files to datadir (incl .json if present at original location)

for file in $csd $act5tt $segmentations; do
    origdir=`dirname $file`
    filebase=`basename $file .mif.gz`
    
    if [[ $file = $csd ]];then outdir=$datadir/$csddir;fi
    if [[ $file = $act5tt ]];then outdir=$datadir/$actdir;fi
    if [[ $file = $segmentations ]];then outdir=$datadir/$segmentationsdir;fi
    
    if [ ! -d $outdir ]; then mkdir -p $outdir; fi
    
    if [ ! -f $outdir/$filebase.mif.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# Update variables to point at corresponding filebases in $datadir
csd=`basename $csd .mif.gz`
act5tt=`basename $act5tt .mif.gz`

##################################################################################
# 1. Perform whole-brain tractography

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
if [ -n "$to_roi" ]; then
    #roi_args_to="$roi_args -include \$(mrcalc ${segmentations} $to_roi -eq -)"
    origdir=`dirname $segmentations`
    filebase=`basename $segmentations .mif.gz`

    roi_args_to="-include "
    #roi_args_to_seg="mrcalc ${segmentations} $to_roi -eq -"
    mrcalc ${segmentationsdir}/${filebase}.mif.gz $to_roi -eq $tractdir/to_${to_roi}_roi.mif.gz
fi
echo $roi_args_from_seg

# If a gmwmi mask does not exist, then create one
if [ ! -f $actdir/${act5tt}_gmwmi.mif.gz ];then
    5tt2gmwmi $actdir/$act5tt.mif.gz $actdir/${act5tt}_gmwmi.mif.gz
fi

# Whole-brain tractography
# tckgen parameters are taken from Blesa et al, Cerebral Cortex 2021. Default is 0.1
cutoff=0.05 
init=$cutoff # default is equal to cutoff
maxlength=200
minlength=2

if [ ! -f $tractdir/roi_brain_from_${from_roi}_to_${to_roi}_$nbr.tck ];then
    tckgen -nthreads $threads \
	   -cutoff $cutoff -seed_cutoff $init -minlength $minlength -maxlength $maxlength -backtrack -seed_unidirectional \
	   -act $actdir/$act5tt.mif.gz \
       -select $nbr $roi_args_from $tractdir/from_${from_roi}_roi.mif.gz $roi_args_to $tractdir/to_${to_roi}_roi.mif.gz \
	   $csddir/$csd.mif.gz $tractdir/roi_brain_from_${from_roi}_to_${to_roi}_$nbr.tck
fi     # -backtrack -seed_dynamic $csddir/$csd.mif.gz \

expanded_name_temp=roi_brain_from_${from_roi}_to_${to_roi}_${nbr}
tckmap $tractdir/roi_brain_from_${from_roi}_to_${to_roi}_$nbr.tck  -template ../registration/dwi/meanb1000_brain.nii.gz - \
| mrcalc - $(tckinfo $tractdir/$expanded_name_temp.tck | grep " count" | cut -d':' -f2 | tr -d '[:space:]') -div - \
| mrthreshold - -abs 0.001 -invert - | tckedit -exclude - $tractdir/roi_brain_from_${from_roi}_to_${to_roi}_${nbr}.tck $tractdir/roi_brain_from_${from_roi}_to_${to_roi}_${nbr}_filtered.tck -force



cd $currdir
