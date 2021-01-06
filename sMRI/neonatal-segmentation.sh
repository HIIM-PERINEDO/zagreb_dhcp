#!/bin/bash
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
Script to run the mirtk neonatal-segmentation on sMRI_processed data
Creates a 5TT equivalent from resulting anatomical parcellation (all_labels)
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR2)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -T2				T2 image to segment (default: derivatives/sMRI_preproc/sub-sID/ses-ssID/sub-ssID_ses-ssID_T2w.nii.gz)
  -m / -mask			mask (default: is no mask) #derivatives/sMRI_preproc/sub-sID/ses-ssID/sub-ssID_ses-ssID_space-T2w_mask.nii.gz)
  -d / -data-dir  <directory>   The directory used to run the script and output the files (default: derivatives/neonatal-segmentation/sub-sID/ses-ssID)
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
T2=derivatives/sMRI_preproc/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_T2w.nii.gz
mask="";#mask=derivatives/sMRI_preproc/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz
datadir=derivatives/neonatal-segmentation/sub-$sID/ses-$ssID
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
T2=`basename $T2 .nii.gz`

################################################################
## 1. Run neonatal-segmentation
if [ -f $datadir/segmentations/${T2}_all_labels.nii.gz ];then
    echo "Segmentation already run/exists in $datadir"
else
    if [ "$mask" = "" ];then
	# No mask provided
	mirtk neonatal-segmentation $T2 $age -d $datadir -atlas $atlas -p 1 -c 0 -t $threads \
	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    else
	# Use provided mask
	mirtk neonatal-segmentation $T2 $age -m $mask -d $datadir -atlas $atlas -p 1 -c 0 -t $threads \
§	      > $logdir/sub-${sID}_ses-${ssID}_$script.txt 2>&1;
    fi
fi

################################################################
## 2. Create 5TT image

cd $datadir

# Create subfolder 5TT to hold results
if [ ! -d 5TT ];then mkdir 5TT; fi

# Path to LUTs for conversion
LUTdir=$codedir/../label_names/$atlas

if [ ! -f 5TT/${T2}_5TT.nii.gz ]; then
    # NOTE - for both all_labels_2_5TT.txt and all_labels_2_5TT_sgm_amyg_hipp.txt
    # 1 - Converts Intra-cranial-background to WM - This converts dWM properly (in tissue_labels => sGM) but there can be some extra-cerebral tissue that becomes included in WM! Check results!!
    # 2 - Converts cerebellum to subcortical-GM
    # NOTE - for all_labels_2_5TT_sgm_amyg_hipp.txt
    # 3 - Converts Amygdala and Hippocampi to subcortical-GM (change by using LUT all_labels_2_5TT.txt)
    labelconvert segmentations/${T2}_all_labels.nii.gz $LUTdir/all_labels.txt $LUTdir/all_labels_2_5TT_sgm_amyg_hipp.txt 5TT/${T2}_5TTtmp.nii.gz
    
    # Break up 5TTtmp in its individual components
    mrcalc 5TT/${T2}_5TTtmp.nii.gz 1 -eq 5TT/${T2}_5TTtmp_01.nii.gz #cGM
    mrcalc 5TT/${T2}_5TTtmp.nii.gz 2 -eq 5TT/${T2}_5TTtmp_02.nii.gz #sGM
    mrcalc 5TT/${T2}_5TTtmp.nii.gz 3 -eq 5TT/${T2}_5TTtmp_03.nii.gz #WM
    mrcalc 5TT/${T2}_5TTtmp.nii.gz 4 -eq 5TT/${T2}_5TTtmp_04.nii.gz #CSF
    mrcalc T2/$T2.nii.gz 0 -mul 5TT/${T2}_5TTtmp_05.nii.gz #pathological tissue - create image with 0:s
    # and put together in 4D 5TT-file
    mrcat -axis 3  5TT/${T2}_5TTtmp_0*.nii.gz 5TT/${T2}_5TT.nii.gz
    # remove tmp-files
    rm 5TT/*tmp*
    
    # Create some 5TT maps for visualization
    if [ ! -f 5TT/${T2}_5TTvis.nii.gz ];then
	5tt2vis 5TT/${T2}_5TT.nii.gz 5TT/${T2}_5TTvis.nii.gz;
	5tt2gmwmi 5TT/${T2}_5TT.nii.gz 5TT/${T2}_5TTgmwmi.nii.gz;
    fi
fi

cd $currdir




