#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Estimation of CSD

Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -dwi				Preprocessed dMRI data serie (default: derivatives/dMRI/sub-sID/ses-ssID/dwi_preproc_norm.mif.gz)
  -mask				Mask for dMRI data (default: derivatives/dMRI/sub-sID/ses-ssID/mask.mif.gz)
  -response			Response function (tournier or msmt_5tt) (default: msmt_5tt)
  -5TT				5TT in dMRI space (default: derivatives/dMRIess/sub-sID/ses-ssID/act/5TT.mif.gz)
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
datadir=derivatives/dMRI/sub-$sID/ses-$ssID
dwi=derivatives/dMRI/sub-$sID/ses-$ssID/dwi_preproc_norm.mif.gz
mask=derivatives/dMRI/sub-$sID/ses-$ssID/mask.mif.gz
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/act/5TT.mif.gz
response=msmt_5tt

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-dwi) shift; dwi=$1; ;;
	-mask) shift; mask=$1; ;;
	-5TT) shift; act5tt=$1; ;;
	-response) shift; response=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "CSD estimation of dMRI using 5TT
Subject:       $sID 
Session:       $ssID
DWI:	       $dwi
Mask:	       $mask
Response:      $response
5TT:           $act5tt
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

for file in $dwi $act5tt $mask; do
    origdir=dirname $file
    filebase=`basename $file .mif.gz`
    if [[ $file = $act5tt ]];then
	outdir=$datadir/act
    else
	outdir=$datadir
    fi
    
    if [ ! -f $ourdir/$filebase.mif.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# Update variables to point at corresponding filebases in $datadir
dwi=`basename $dwi .mif.gz`
act5tt=`basename $act5tt .mif.gz`
mask=`basename $mask .mif.gz`


##################################################################################
## Make Response Function estimation and then CSD calcuation

cd $datadir

if [ ! -d csd ];then mkdir -p csd;fi

# ---- Tournier ----
if [[ $response = tournier ]]; then
    # response fcn
    if [ ! -f csd/${response}_response.txt ]; then
	echo "Estimating response function use $response method"
	dwi2response tournier -force -mask  $mask.mif.gz -voxels csd/${response}_sf.mif $dwi.mif.gz csd/${response}_response.txt
	echo Check results: response fcn and sf voxels
	shview  csd/${response}_response.txt
	mrview  meanb0_brain.nii.gz -roi.load csd/${response}_sf.mif -roi.opacity 0.5 -mode 2
    fi
    # Do CSD estimation
    if [ ! -f csd/CSD_${response}.mif.gz ]; then
	echo "Estimating ODFs with CSD"
	dwi2fod -force -mask $mask.mif.gz csd $dwi.mif.gz csd/${response}_response.txt csd/csd_${response}.mif.gz
	echo Check results of ODFs
	mrview -load meanb0_brain.nii.gz -odf.load_sh csd/csd_${response}.mif.gz -mode 2
    fi
fi

# ---- MSMT ----
if [[ $response = msmt_5tt ]]; then
    # Estimate msmt_csd response functions (note use FA < 0.15 for gm and csf)
    echo "Estimating response function use $response method"
    dwi2response msmt_5tt -force -voxels csd/${response}_sf.mif -fa 0.15 $dwi.mif.gz act/$act5tt.mif.gz csd/${response}_wm.txt csd/${response}_gm.txt csd/${response}_csf.txt
    echo "Check results for response fcns (wm, gm and csf) and single-fibre voxels (sf)"
    shview  csd/${response}_wm.txt
    shview  csd/${response}_gm.txt
    shview  csd/${response}_csf.txt
    mrview  meanb0_brain.nii.gz -roi.load csd/${response}_sf.mif -roi.opacity 0.5 -mode 2
    # Calculate ODFs
    echo "Calculating CSD using ACT and $response"
    dwi2fod msmt_csd -force -mask $mask.mif.gz $dwi.mif.gz csd/${response}_wm.txt csd/csd_${response}_wm.mif.gz csd/${response}_gm.txt csd/csd_${response}_gm.mif.gz csd/${response}_csf.txt csd/csd_${response}_csf.mif.gz
    mrview -load meanb0_brain.nii.gz -odf.load_sh csd/csd_${response}_wm.mif.gz -mode 2
fi


cd $currdir
