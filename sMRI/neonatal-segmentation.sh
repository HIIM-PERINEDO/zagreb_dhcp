#!/bin/bash
#
# Script to run the neonatal-segmentation on sMRI_processed data
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
This script runs the dHCP surface pipeline.
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -T2				T2 image to segment (default: derivatives/sMRI_preprocess/sub-$sID/ses-$ssID/sub-${ssID}_ses-${ssID}_T2w.nii.gz)
  -m / -mask			mask (default: derivatives/sMRI_preprocess/sub-$sID/ses-$ssID/sub-${ssID}_ses-${ssID}_space-T2w_mask.nii.gz)
  -d / -data-dir  <directory>   The directory used to run the script and output the files (default: derivatives/neonatal-segmentation)
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
T2=derivatives/sMRI_preprocess/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_T2w.nii.gz
mask=derivatives/sMRI_preprocess/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz
datadir=derivatives/neonatal-segmentation/sub-$sID/ses-$ssID
threads=10
atlas=ALBERT

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
T2:         $T2 
Subject:    $sID 
Session:    $ssID
Age:        $age
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
    
# Run neonatal-segmentation
mirtk neonatal-segmentation $T2 $age -m $mask -d $datadir -atlas $atlas -p 1 -c 0 -t $threads \
      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1
