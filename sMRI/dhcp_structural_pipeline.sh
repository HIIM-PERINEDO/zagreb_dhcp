#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
Script to run the dHCP structural pipeline on sMRI processed data (default is using -additional flag)
Run from $studyfolder, and internally then studyfolder=$PWD

Arguments:
  sID				Subject ID (e.g. PMRABC) 
  ssID                       	Session ID (e.g. MR2)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -T2				T2 image to segment with full path (default: $studyfolder/derivatives/sMRI/preproc/sub-\$sID/ses-\$ssID/sub-\$sID_ses-\$ssID_desc-preproc_T2w.nii.gz)
  -T1				T1 image to segment with full path (default: $studyfolder/derivatives/sMRI/preproc/sub-\$sID/ses-\$ssID/sub-\$sID_ses-\$ssID_T1w.nii.gz)
  -d / -data-dir  <directory>   The directory used to run the script and output the files with full path (default: $studyfolder/derivatives/sMRI/dhcp_structural_pipeline/sub-\$sID/ses-\$ssID)
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

# defaults
currdir=`pwd`
# NOTE - need fullpath to comply with Docker --volumes
studyfolder=$currdir;
T2=$studyfolder/derivatives/sMRI/preproc/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz
T1=$studyfolder/derivatives/sMRI/preproc/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_T1w.nii.gz
datadir=$studyfolder/derivatives/sMRI/dhcp_structural_pipeline
threads=10

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; T2=$1; ;;
	-T1) shift; T1=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-t|-threads)  shift; threads=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

## Extract folder and file-names for T2 and T1
# T2
T2file=`basename $T2`
T2folder=`dirname $T2`
# T1
# check if the T1 exists
if [ ! -f $T1 ]; then
    T1="";
else
    T1file=`basename $T1`
    T1folder=`dirname $T1`
fi

echo "dHCP structural pipeline
Subject:    $sID 
Session:    $ssID
Age:        $age
T2:         $T2 
T1:	    $T1
Directory:  $datadir 
Threads:    $threads
$BASH_SOURCE $command
----------------------------"

# Set up log
scriptname=`basename $BASH_SOURCE .sh`
logdir=$datadir/logs
if [ ! -d $logdir ]; then mkdir -p $logdir; fi

# we'll be running the Docker containers as yourself, not as root:
userID=$(id -u):$(id -g)


################ PIPELINE ################

# Update T2 to point to T2 basename
T2base=`basename $T2 .nii.gz`

################################################################
## 1. Run dhcp structural pipeline
#
# NOTE - we want to use the flag -additional to be able to run Manuel's MCRIB 5TT routine
#

# FL - update this with correct path after adding cleanup to coher with dHCP datarelease2 or datarelease3
if [ -f $datadir/derivatives/sub-$sID/ses-$ssID/anat/sub-{$sID}_ses-${ssID}_drawem_all_labels.nii.gz ];then
    echo "Segmentation already run/exists in $datadir/derivatives/sub-$sID/ses-$ssID/anat"
else
    if [ "$T1" = "" ];then
	# No T1w provided, so run without T1 as input argument 
	docker run --rm -it \
	       --user $userID \
	       --volume $datadir:/dataOut \
	       --volume $T2folder:/T2folder \
	       biomedia/dhcp-structural-pipeline:latest \
	       sub-$sID ses-$ssID $age \
	       -T2 /T2folder/$T2file \
	       -t $threads \
	       -d /dataOut \
	       -additional \
	       > ${logdir}/sub-${sID}_ses-${ssID}_$scriptname.log 2>&1 
    else 
	# T1 provided and exists	
	docker run --rm -it \
	       --user $userID \
	       --volume $datadir:/dataOut \
	       --volume $T2folder:/T2folder \
	       --volume $T1folder:/T1folder \
	       biomedia/dhcp-structural-pipeline:latest \
	       sub-$sID ses-$ssID $age \
	       -T2 /T2folder/$T2file \
	       -T1 /T1folder/$T1file \
	       -t $threads \
	       -d /dataOut \
	       -additional \
	       > ${logdir}/sub-${sID}_ses-${ssID}_$scriptname.log 2>&1 
    fi

fi

