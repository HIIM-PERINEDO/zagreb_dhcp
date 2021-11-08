#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age [options]
Creates a 5TT equivalent from resulting anatomical DrawEM parcellation (all_labels parcelleation file)
Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)

Options:
  -s / -seg-file		The DrawEM all_labels segmentation file (default: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation/segmentations)
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

currdir=$PWD
T2seg=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_T2w_all_labels.nii.gz
mask=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_brain_mask.nii.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID
threads=10
atlas=ALBERT

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
currdir=`pwd`

shift; shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-s|-seg-file) shift; T2seg=$1; ;;
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
## 1. Create 5TT image

cd $datadir

# Create subfolder 5TT to hold results
if [ ! -d 5TT ];then mkdir 5TT; fi

# Path to LUTs for conversion
LUTdir=$codedir/../label_names/$atlas

if [ ! -f 5TT/${T2base}_5TT.mif.gz ]; then
    # NOTE - for both all_labels_2_5TT.txt and all_labels_2_5TT_sgm_amyg_hipp.txt
    # 1 - Converts Intra-cranial-background to WM - This converts dWM properly (in tissue_labels => sGM) but there can be some extra-cerebral tissue that becomes included in WM! Check results!!
    # 2 - Converts cerebellum to subcortical-GM
    # NOTE - for all_labels_2_5TT_sgm_amyg_hipp.txt
    # 3 - Converts Amygdala and Hippocampi to subcortical-GM (change by using LUT all_labels_2_5TT.txt)
    labelconvert segmentations/${T2base}_all_labels.nii.gz $LUTdir/all_labels.txt $LUTdir/all_labels_2_5TT_sgm_amyg_hipp.txt 5TT/${T2base}_5TTtmp.mif
    
    # Break up 5TTtmp in its individual components
    mrcalc 5TT/${T2base}_5TTtmp.mif 1 -eq 5TT/${T2base}_5TTtmp_01.mif #cGM
    mrcalc 5TT/${T2base}_5TTtmp.mif 2 -eq 5TT/${T2base}_5TTtmp_02.mif #sGM
    mrcalc 5TT/${T2base}_5TTtmp.mif 3 -eq 5TT/${T2base}_5TTtmp_03.mif #WM
    mrcalc 5TT/${T2base}_5TTtmp.mif 4 -eq 5TT/${T2base}_5TTtmp_04.mif #CSF
    mrcalc T2/$T2base.nii.gz 0 -mul 5TT/${T2base}_5TTtmp_05.nii.gz #pathological tissue - create image with 0:s
    # and put together in 4D 5TT-file
    mrcat -axis 3  5TT/${T2base}_5TTtmp_0*.mif 5TT/${T2base}_5TT.mif.gz
    # remove tmp-files
    rm 5TT/*tmp*
    
    # Create some 5TT maps for visualization
    if [ ! -f 5TT/${T2base}_5TTvis.mif.gz ];then
	5tt2vis 5TT/${T2base}_5TT.mif.gz 5TT/${T2base}_5TTvis.mif.gz;
	5tt2gmwmi 5TT/${T2base}_5TT.mif.gz 5TT/${T2base}_5TTgmwmi.mif.gz;
    fi
fi

cd $currdir




