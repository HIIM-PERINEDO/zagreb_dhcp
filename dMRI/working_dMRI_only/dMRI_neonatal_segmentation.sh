#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
Script to run the mirtk neonatal-segmentation (DrawEM) on processed sMRI data

Arguments:
  sID				Subject ID (e.g. PMRXYZ) 
  ssID                       	Session ID (e.g. MR2)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -T2				T2 image to segment (default: derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz)
  -m / -mask			mask (default: derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz)
  -d / -data-dir  <directory>   The directory used to run the script and output the files (default: dderivatives/dMRI_neonatal_segmentation/sub-$sID/ses-$ssID)
  -a / -atlas	  		Atlas to use for DrawEM neonatal segmentation (default: ALBERT, only ALBERT can currently be used)    
  -t / -threads  <number>       Number of threads (CPU cores) allowed for the registration to run in parallel (default: 16)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 3 ] || { usage; }
command=$@
sID=$1
ssID=$2
age=$3

currdir=`pwd`
T2=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz
mask=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz
datadir=derivatives/dMRI_neonatal_segmentation/sub-$sID/ses-$ssID
threads=16
atlas=ALBERT

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
currdir=`pwd`

#shift all 3 input arguments
shift; shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; T2=$1; ;;
	-m|-mask) shift; mask=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-t|-threads)  shift; threads=$1; ;;
	-a|-atlas)  shift; atlas=$1; ;; 
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Neonatal segmentation using DrawEM
Subject:    $sID 
Session:    $ssID
Age:        $age
T2:         $T2 
Mask:	    $mask
Atlas:	    $atlas
Directory:  $datadir 
Threads:    $threads
$BASH_SOURCE $command
----------------------------"

# Set up log
script=`basename $BASH_SOURCE .sh`
logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ]; then mkdir -p $logdir; fi


################ PIPELINE ################

# Make sure mirtk neonatal-segmentation is in the path
#source ~/Software/DrawEM/parameters/path.se

# Update T2 to point to T2 basename
T2base=`basename $T2 .nii.gz`

################################################################
## 1. Run neonatal-segmentation
if [ -f $datadir/segmentations/${T2base}_all_labels.nii.gz ];then
    echo "Segmentation already run/exists in $datadir"
else
    if [ "$mask" = "" ];then
	# No mask provided
	mirtk neonatal-segmentation $T2 $age -d $datadir -atlas $atlas -p 1 -c 0 -t $threads -v 1 \
	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    else
	# Use provided mask
	mirtk neonatal-segmentation $T2 $age -m $mask -d $datadir -atlas $atlas -p 1 -c 0 -t $threads -v 1 \
	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    fi
fi

################################################################
