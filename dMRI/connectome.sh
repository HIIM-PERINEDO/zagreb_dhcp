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
  -label			Parcellation image in dMRI space (default: derivatives/dMRI/sub-sID/ses-ssID/parcellation/ALBERT/segmentations/all_labels.mif.gz)
  -a / -atlas			Atlas used for parcellation (options ALBERT or MCRIB) (default: ALBERT)
  -LUT_label			LUT corresponding to parcellation image (default: codedir/label_names/ALBERT/all_labels.txt)
  -LUT_2connectome		Conversion LUT to convert from parcellation image into nodes image for connectome (default: codedir/label_names/ALBERT/all_labels_2_CorticalStructuresConnectome.txt)
  -connectome			Name of connectome (options cortical or lobar) (default: cortical)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID)
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

currdir=`pwd`

# Defaults
datadir=derivatives/dMRI/sub-$sID/ses-$ssID
tract=derivatives/dMRI/sub-$sID/ses-$ssID/tractography/whole_brain_10M_sift.tck
label=derivatives/dMRI/sub-$sID/ses-$ssID/parcellation/$atlas/segmentations/all_labels.mif.gz
atlas=ALBERT
lutin=$codedir/label_names/ALBERT/all_labels.txt
lutout=$codedir/label_names/ALBERT/all_labels_2_CorticalStructuresConnectome.txt
connectome=cortical
threads=10

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-tract) shift; tract=$1; ;;
	-label) shift; label=$1; ;;
	-LUT_label) shift; lutin=$1; ;;
	-a|-atlas) shift; atlas=$1; ;;
	-LUT_2connectome) shift; lutout=$1; ;;
	-connectome) shift; connectome=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
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
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo


##################################################################################
## 0. Copy to files to relevant $atlas location $datadir/anat folder (incl .json if present at original location)

# Tractogram will go into tractography folder
tractdir=tractography
if [ ! -d $datadir/$tractdir ]; then mkdir -p $datadir/$tractdir; fi
tractbase=`basename $tract .tck`
if [ ! -f $datadir/$tractdir/$tractbase.tck ];then
    cp $tract $datadir/$tractdir/.
fi

# Labels file will go into parcellation folder and the correspondings atla's segmentations subfolder
segdir=parcellation/$atlas/segmentations
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
lutindir=parcellation/$atlas/label_names
if [ ! -d $datadir/$lutindir ]; then mkdir -p $datadir/$lutindir ]; fi
for file in $lutin; do
    filebase=`basename $file`
    if [ ! -f $datadir/$lutindir/$filebase ];then
	cp $file $datadir/$lutindir/.
    fi
done
# LUT_2Connectome $lutout
condir=connectome/$atlas/$connectome
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
        
    # first use labelconvert to extract connectome structures and put into a continuous LUT
    labelconvert -force $seg_in $lut_in $lut_out $seg_out
    # then use mrthreshold to get rid of entries past $thr and make sure $seg_out is 3D and with integer datatype
    mrthreshold -abs $thr -invert $seg_out - | mrcalc -force -datatype uint32 - $seg_out -mul - | mrmath -force -axis 3 -datatype uint32 - mean $seg_out
fi

cd $currdir

##################################################################################
## 2. Create connectome

cd $datadir

# Generate connectome
if [ ! -f $condir/${tractbase}_${connectome}_Connectome.csv ]; then
    # Create connectome using ${tractbase}.tck
    echo "Creating $atlas $connectome connectome from ${tractbase}.tck"
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol -out_assignments $condir/assignments_${tractbase}_${connectome}_Connectome.csv $tractdir/$tractbase.tck $condir/${label}_2_${connectome}_Connectome.mif.gz $condir/${tractbase}_${connectome}_Connectome.csv    
fi

cd $currdir
