#!/bin/bash
# Zagreb Collab dhcp
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Creates connectome based on SIFT whole-brain tractogram

Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -tract			SIFT whole-brain tractogram to use (default: derivatives/dMRI/sub-sID/ses-ssID/tractography/whole_brain_10M_sift.tck)
  -label			Parcellation image in dMRI space (default: derivatives/dMRI/sub-sID/ses-ssID/parcellation/\$method-\$atlas/segmentations/all_labels_coreg.mif.gz)
  -a / -atlas			Atlas used for parcellation (options ALBERT or MCRIB) (default: ALBERT)
  -m / -method			Algorithm/Method used for segmentation (options DrawEM, neonatal-5TT, 5ttgen-neonatal)(default: DrawEM)
  -LUT_label			LUT corresponding to parcellation image (default: codedir/label_names/ALBERT/all_labels.txt)
  -LUT_2connectome		Conversion LUT to convert from parcellation image into nodes image for connectome (default: codedir/label_names/ALBERT/all_labels_2_CorticalStructuresConnectome.txt)
  -connectome			Name of connectome (options cortical or lobar) (default: cortical)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID)
  -t / -threads	  		Number of threads/CPUs (default: 10)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2

currdir=$PWD

# Defaults
method="neonatal-5TT" #DrawEM
atlas="M-CRIB" #ALBERT
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/connectome #derivatives/dMRI_connectome/sub-$sID/ses-$ssID
tract=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/tractography/tractography/$method-$atlas/whole_brain_10M.tck    #derivatives/dMRI_tractography/sub-$sID/ses-$ssID/tractography/$method-$atlas/whole_brain_10M.tck   
#sift2 weights are assumed to be in file whole_brain_10M_sift2.csv
label=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/registration/dwi/parcellation/$method-$atlas/segmentations/Structural_Labels_coreg.mif.gz  #derivatives/dMRI_registration/sub-$sID/ses-$ssID/dwi/parcellation/$method-$atlas/segmentations/Structural_Labels_coreg.mif.gz #derivatives/dMRI_registration/sub-$sID/ses-$ssID/dwi/parcellation/$method-$atlas/segmentations/all_labels_coreg.mif.gz
codedir=code/zagreb_dhcp
#lutin=$codedir/label_names/ALBERT/all_labels.txt
#lutout=$codedir/label_names/ALBERT/all_labels_2_CorticalStructuresConnectome.txt
#lutin=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_desc-mcrib_dseg.nii.gz;
lutin=$codedir/label_names/$atlas/M-CRIB_labels_itk_format.txt;
lutout=$codedir/label_names/$atlas/Structural_Labels.txt;
connectome=Structural_M-CRIB #cortical
threads=24


shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-tract) shift; tract=$1; ;;
	-label) shift; label=$1; ;;
	-LUT_label) shift; lutin=$1; ;;
	-m|-method) shift; method=$1; ;;
	-a|-atlas) shift; atlas=$1; ;;
	-LUT_2connectome) shift; lutout=$1; ;;
	-connectome) shift; connectome=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-t|-threads) shift; threads=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Creation off Whole-brain ACT tractography
Subject:       	        $sID 
Session:		$ssID
Tract:			$tract
Labels:			$label
Method:			$method
Atlas:			$atlas
LUT_Labels:		$lutin
LUT_Labels2Connectome:	$lutout
Connectome name:	$connectome
Directory:     		$datadir 
$BASH_SOURCE   		$command
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
## 0. Copy to files to relevant locations

tractbase=`basename $tract .tck`
tractssift2=${tractbase}_sift2.csv

# Tractogram will go into tractography folder
tractdir=tractography
if [ ! -d $datadir/$tractdir ]; then mkdir -p $datadir/$tractdir; fi
tractbase=`basename $tract .tck`
origtractdir=`dirname $tract`

if [ ! -f $datadir/$tractdir/$tractbase.tck ];then
    echo "${origtractdir}/${tractssift2}"
    cp $tract "${origtractdir}/${tractssift2}" $datadir/$tractdir/.
fi



# Labels file will go into parcellation folder and the correspondings atlas's segmentations subfolder
segdir=parcellation/$method-$atlas/segmentations
if [ ! -d $datadir/$$segdir ]; then mkdir -p $datadir/$segdir; fi									  
for file in $label; do
    origdir=dirname $file
    filebase=`basename $file .mif.gz`
    if [ ! -f $datadir/$segdir/$filebase.mif.gz ];then
	cp $file $datadir/$segdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $datadir/$segdir/.
	fi
    fi
done

# LUTs go into relevant subfolders
# NOTE - separate for LUT_in $lutin and LUT_2Conncectome $lutout
# LUT_in $lutin
lutindir=parcellation/$method-$atlas/label_names
if [ ! -d $datadir/$lutindir ]; then mkdir -p $datadir/$lutindir ]; fi
for file in $lutin; do
    filebase=`basename $file`
    if [ ! -f $datadir/$lutindir/$filebase ];then
	cp $file $datadir/$lutindir/.
    fi
done
# LUT_2Connectome $lutout
condir=connectome/$method-$atlas/$connectome
if [ ! -d $datadir/$condir ];then mkdir -p $datadir/$condir; fi
lutoutdir=$condir
if [ ! -d $datadir/$lutoutdir ]; then mkdir -p $datadir/$lutoutdir ]; fi
for file in $lutout; do
    filebase=`basename $file`
    if [ ! -f $datadir/$lutourdir/$filebase ];then
	cp $file $datadir/$lutoutdir/.
    fi
done

# Update variables to point at corresponding filebases in $datadir
label=`basename $label .mif.gz`
lutin=`basename $lutin`
lutout=`basename $lutout`



##################################################################################
## 1. Create parcellations in subfolder /segmentations

cd $datadir

# define I/O files 
seg_in=$segdir/${label}.mif.gz
seg_out=$condir/${label}_2_${connectome}_Connectome.mif.gz
lut_in=$lutindir/$lutin
lut_out=$lutoutdir/$lutout

if [ ! -f $seg_out ]; then

    echo "Creating nodes image for $connectome of parcellation/segmentation of $label"

    if [[ $atlas = ALBERT ]] && [[ $connectome = cortical ]];then
	thr=33; #Last entry in lut_out is 32
    fi
    if [[ $atlas = ALBERT ]] && [[ $connectome = lobar ]];then
	thr=17; #Last entry in lut_out is 16
    fi
        
    # first use labelconvert to extract connectome structures and put into a continuous LUT and make sure 3D and datatype uint32
    #labelconvert -force $seg_in $lut_in $lut_out - | mrmath -datatype uint32 -force -axis 3 - mean $seg_out
    labelconvert -force $seg_in $lut_in $lut_out $seg_out
    # then use mrthreshold to get rid of entries past $thr and make sure $seg_out is 3D and with integer datatype# NOT needed since all $seg_out does not need to be thresholded
    #mrthreshold -abs $thr -invert $seg_out - | mrcalc -force -datatype uint32 - $seg_out -mul - | mrmath -force -axis 3 -datatype uint32 - mean $seg_out
fi

cd $currdir

##################################################################################
## 2. Create connectome

cd $datadir

# Generate connectome
if [ ! -f $condir/${tractbase}_${connectome}_Connectome.csv ]; then
    # Create connectome using ${tractbase}.tck
    echo "Creating $atlas $connectome connectome from ${tractbase}.tck"
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in $tractdir/$tractssift2 -out_assignments $condir/assignments_${tractbase}_${connectome}_Connectome.csv $tractdir/$tractbase.tck $condir/${label}_2_${connectome}_Connectome.mif.gz $condir/${tractbase}_${connectome}_Connectome.csv    
fi

cd $currdir
