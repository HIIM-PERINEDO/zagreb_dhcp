#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
Script to run the mirtk neonatal-segmentation on sMRI_processed data
Creates a 5TT equivalent from resulting anatomical parcellation (all_labels)
Arguments:
  sID				Subject ID (e.g. PMRABC) 
  ssID                       	Session ID (e.g. MR2)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -T2				T2 image to segment (default: derivatives/sMRI/sub-sID/ses-ssID/preproc/sub-ssID_ses-ssID_desc-preproc_T2w.nii.gz)
  -m / -mask			mask (default: derivatives/sMRI/sub-sID/ses-ssID/preproc/sub-ssID_ses-ssID_space-T2w_mask.nii.gz)
  -d / -data-dir  <directory>   The directory used to run the script and output the files (default: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation)
  -a / -atlas	  		Atlas to use for DrawEM neonatal segmentation (default: ALBERT)    
  -t / -threads  <number>       Number of threads (CPU cores) allowed for the registration to run in parallel (default: 10)
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
T2=derivatives/sMRI/sub-$sID/ses-$ssID/preproc/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz
mask=derivatives/sMRI/sub-$sID/ses-$ssID/preproc/sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz
datadir=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation
threads=10
atlas=ALBERT

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
currdir=`pwd`

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
Directory:  $datadir 
Threads:    $threads
$BASH_SOURCE $command
----------------------------"

# Set up log
script=`basename $BASH_SOURCE .sh`
logdir=$datadir/logs
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
	mirtk neonatal-segmentation $T2 $age -d $datadir -atlas $atlas -p 1 -c 0 -t $threads \
	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    else
	# Use provided mask
	mirtk neonatal-segmentation $T2 $age -m $mask -d $datadir -atlas $atlas -p 1 -c 0 -t $threads \
	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    fi
fi

################################################################
