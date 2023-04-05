#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Estimation of response function

Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -dwi				Preprocessed dMRI data serie (format: .mif.gz) (default: derivatives/dMRI_preproc/sub-sID/ses-ssID/dwi_preproc_inorm.mif.gz)
  -mask				Mask for dMRI data (format: .mif.gz) (default: derivatives/dMRI_preproc/sub-sID/ses-ssID/mask.mif.gz)
  -response			Response function (tournier or dhollander) (default: dhollander)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_response/sub-sID/ses-ssID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2

shift; shift

currdir=$PWD

# Defaults
datadir=derivatives/dMRI_response/sub-$sID/ses-$ssID
dwi=derivatives/dMRI_preproc/sub-$sID/ses-$ssID/dwi_preproc_inorm.mif.gz
mask=derivatives/dMRI_preproc/sub-$sID/ses-$ssID/mask.mif.gz
response=dhollander

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ $# -gt 0 ]; do
    case "$1" in
	-dwi) shift; dwi=$1; ;;
	-mask) shift; mask=$1; ;;
	-response) shift; response=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "CSD estimation of dMRI 
Subject:       $sID 
Session:       $ssID
DWI:	       $dwi
Mask:	       $mask
Response:      $response
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/dMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo


##################################################################################
# 0. Copy to files to datadir (incl .json if present at original location)

for file in $dwi $mask; do
    origdir=`dirname $file`
    filebase=`basename $file .mif.gz`
    outdir=$datadir
    
    if [ ! -d $outdir ]; then mkdir -p $outdir; fi
    
    if [ ! -f $outdir/$filebase.mif.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi

done

# Update variables to point at corresponding filebases in $datadir
dwidir=`dirname $dwi`
dwi=`basename $dwi .mif.gz`
mask=`basename $mask .mif.gz`

##################################################################################
## Make Response Function estimation and then CSD calcuation

cd $datadir

## ---- Tournier ----
if [[ $response = tournier ]]; then

    # response fcn

    if [ ! -f ${response}_response.txt ]; then
	echo "Estimating response function use $response method"
	dwi2response tournier -force -mask  $mask.mif.gz -voxels ${response}_sf.mif.gz $dwi.mif.gz ${response}_response.txt
    fi

    echo Check results: response fcn and sf voxels
    echo shview  ${response}_response.txt
    echo mrview  meanb0_brain.mif.gz -roi.load ${response}_sf.mif.gz -roi.opacity 0.5 -mode 2
fi


## ---- dhollander ----
if [[ $response = dhollander ]]; then
    

    if [ ! -f ${response}_response.txt ]; then
	# Estimate dhollander msmt response functions (use FA < 0.10 according to Blesa et al Cereb Cortex 2021)
	echo "Estimating response function use $response method"
	dwi2response dhollander -force -mask $mask.mif.gz -voxels ${response}_sf.mif.gz -fa 0.1 $dwi.mif.gz ${response}_wm.txt ${response}_gm.txt ${response}_csf.txt
    fi
    
    echo "Check results for response fcns (wm, gm and csf) and single-fibre voxels (sf)"
    echo shview  $datadir/${response}_wm.txt
    echo shview  $datadir/${response}_gm.txt
    echo shview  $datadir/${response}_csf.txt
    echo mrview  $dwidir/meanb0_brain.mif.gz -overlay.load $datadir/${response}_sf.mif.gz -overlay.opacity 0.5 -mode 2
    
fi

cd $currdir


# shview  $datadir/${response}_wm.txt
# shview  $datadir/${response}_gm.txt
# shview  $datadir/${response}_csf.txt
# mrview  $dwidir/meanb0_brain.mif.gz -overlay.load $datadir/${response}_sf.mif.gz -overlay.opacity 0.5 -mode 2