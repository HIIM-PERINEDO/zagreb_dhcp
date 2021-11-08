#!/bin/bash
# bash code/sMRI_process_neonatal-5TT.sh PK343 MR1 ~/Research/Atlases/M-CRIB/derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_M-CRIB_preproc_neonatal-5TT derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_FLAIR_mask-dilMx2_betmRf0p3_mask_ORIGT2
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age neonatal-segmentation-directory [options]
Script to do M-CRIB neonatal-5TT (follows: https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT)
Output 
Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
  age				Age at scanning in weeks (e.g. 40)
Options:
  -s / -seg-dir <directory>	Root directory were the neonatal-segmentaion resides (default: derivatives/neonatal-segmentation)		
  -a / -atlas <directory>	DrawEM processed M-CRIB atlas location (default: $HOME/Research/Atlases/M-CRIB/derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_M-CRIB_preproc_neonatal-5TT)
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

segdir=derivatives/neonatal-segmentation
atlasdir=$HOME/Research/Atlases/M-CRIB/derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_M-CRIB_preproc_neonatal-5TT
threads=10

shift; shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-s|-seg-dir) shift; segdir=$1; ;;
	-t|-threads)  shift; threads=$1; ;;
	-a|-atlas)  shift; atlasdir=$1; ;; 
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Folder and paths
currdir=`pwd`
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studyneo5ttdir=${segdir}_neonatal-5TT
neo5ttdir=$studyneo5ttdir/sub-$sID/ses-$ssID;

echo "Neonatal-5TT
Subject:	$sID 
Session:    	$ssID
Age:        	$age
Segmentaiton:	$segdir
Atlas:      	$atlasdir
Threads:    	$threads
$BASH_SOURCE 	$command
----------------------------"

# Set up log
script=`basename $BASH_SOURCE .sh`
logdir=$neo5ttdir/logs
if [ ! -d $logdir ]; then mkdir -p $logdir; fi
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo


###################################################################################
## Get atlas files

# Folder in which to place the atlas files
if [ ! -d $studyneo5ttdir/atlas ]; then mkdir -p $studyneo5ttdir/atlas; fi

# and put all the atlas files locally
cp $atlasdir/* $studyneo5ttdir/atlas/.


###################################################################################3
# Copy files and make match histograms

# Go to the processing folder
currdir=`pwd`
if [ ! -d $neo5ttdir ]; then mkdir -p $neo5ttdir; fi

# Relevant files to copy and create
T2=sub-${sID}_ses-${ssID}_T2w;
T2N4=${T2}_N4;
brainmaskdrawem=brain_mask_drawem;

# Copy T2w N4 file
if [ ! -f $neo5ttdir/$T2N4.nii.gz ]; then
    cp $segdir/sub-$sID/ses-$ssID/N4/$T2.nii.gz $neo5ttdir/$T2N4.nii.gz
fi
# and create an equivalent brain_mask_drawem
if [ ! -f  $neo5ttdir/${T2}_$brainmaskdrawem.nii.gz ]; then
    mirtk padding \
	  $segdir/sub-$sID/ses-$ssID/segmentations/${T2}_tissue_labels.nii.gz \
	  $segdir/sub-$sID/ses-$ssID/segmentations/${T2}_tissue_labels.nii.gz \
	  $neo5ttdir/${T2}_$brainmaskdrawem.nii.gz 2 1 4 0
fi


###################################################################################
## Neonatal-5TT pipeline
# 1. Intensity histogram matching between the M-CRIB templates and our subject

cd  $neo5ttdir

for i in $(seq -f %02g 1 10); do
    if [ ! -f ${T2N4}_M-CRIB_P${i}_T2_hist.nii.gz ]; then
	mrhistmatch -mask_input ../../atlas/M-CRIB_P${i}_T2_$brainmaskdrawem.nii.gz \
		    -mask_target ${T2}_$brainmaskdrawem.nii.gz \
		    scale ../../atlas/M-CRIB_P${i}_T2_N4.nii.gz $T2N4.nii.gz \
		    ${T2N4}_M-CRIB_P${i}_T2_hist.nii.gz
    fi
done

cd $currdir


###################################################################################3
## Neonatal-5TT pipeline
# 2. ANTs registration
echo ANTs registration

cd  $neo5ttdir

if [ ! -f ${T2N4}_M-CRIB_Structural_Labels.nii.gz ];then
    antsJointLabelFusion.sh -d 3 -t $T2N4.nii.gz \
			    -x ${T2}_$brainmaskdrawem.nii.gz \
			    -o ${T2N4}_M-CRIB_Structural_ \
			    -q 0 -c 2 -j $threads \
			    -g ${T2N4}_M-CRIB_P01_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P01_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P02_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P02_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P03_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P03_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P04_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P04_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P05_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P05_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P06_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P06_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P07_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P07_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P08_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P08_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P09_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P09_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P10_T2_hist.nii.gz -l ../../atlas/M-CRIB_orig_P10_parc_mrtrix.nii.gz;
fi

cd $currdir


###################################################################################3
## Neonatal-5TT pipeline
# 3. Create probability maps by combining the obtained label from the previous step with the probability maps obtained from the dHCP pipeline.

# Pmap GM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-GM.nii.gz ]; then
#    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/gm/$T2.nii.gz $neo5ttdir/${T2N4}-Pmap-GM.nii.gz
    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/seg1/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg2/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg3/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg4/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg5/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg6/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg7/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg8/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg9/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg10/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg11/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg12/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg13/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg14/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg15/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg16/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg20/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg21/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg22/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg23/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg24/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg25/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg26/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg27/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg28/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg29/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg30/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg31/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg32/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg33/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg34/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg35/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg36/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg37/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg38/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg39/$T2.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-GM.nii.gz  
fi
# Pmap CSF
if [ ! -f $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz ]; then
#    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/csf/$T2.nii.gz $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz  
    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/seg49/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg50/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg83/$T2.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz
fi
# Pmap WM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-WM.nii.gz ]; then
    #    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/wm/$T2.nii.gz $neo5ttdir/${T2N4}-Pmap-WM.nii.gz
    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/seg19/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg51/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg52/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg53/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg54/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg55/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg56/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg57/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg58/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg59/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg60/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg61/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg62/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg63/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg64/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg65/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg66/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg67/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg68/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg69/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg70/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg71/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg72/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg73/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg74/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg75/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg76/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg77/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg78/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg79/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg80/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg81/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg82/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg85/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg48/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg40/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg41/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg42/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg43/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg44/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg45/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg46/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg47/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg86/$T2.nii.gz \
	     -add $segdir/sub-$sID/ses-$ssID/posteriors/seg87/$T2.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-WM.nii.gz
fi
# Pmap subcortical GM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-subGM.nii.gz ]; then
    fslmaths $segdir/sub-$sID/ses-$ssID/posteriors/seg17/$T2.nii.gz -add \
	     $segdir/sub-$sID/ses-$ssID/posteriors/seg18/$T2.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-subGM.nii.gz
fi

# extract the subcortical structures from the M-CRIB parcellation and combine them:
cd $neo5ttdir
if [ ! -f ${T2N4}_sub_all.nii.gz ]; then
    fslmaths ${T2N4}_M-CRIB_Structural_Labels.nii.gz -thr 36 -uthr 39 -bin ${T2N4}_sub1.nii.gz
    fslmaths ${T2N4}_M-CRIB_Structural_Labels.nii.gz -thr 43 -uthr 46 -bin ${T2N4}_sub2.nii.gz
    fslmaths ${T2N4}_M-CRIB_Structural_Labels.nii.gz -thr 42 -uthr 42 -bin ${T2N4}_sub3.nii.gz
    fslmaths ${T2N4}_M-CRIB_Structural_Labels.nii.gz -thr 49 -uthr 49 -bin ${T2N4}_sub4.nii.gz
    fslmaths ${T2N4}_sub1.nii.gz -add ${T2N4}_sub2.nii.gz -add ${T2N4}_sub3.nii.gz -add ${T2N4}_sub4.nii.gz ${T2N4}_sub_all.nii.gz
fi

# invert this mask and apply it to the WM tissue probability map:
if [ ! -f ${T2N4}-Pmap-WM-corr.nii.gz ]; then
    mrthreshold -abs 0.5 -invert ${T2N4}_sub_all.nii.gz ${T2N4}_sub_all_inverted.nii.gz
    fslmaths ${T2N4}-Pmap-WM.nii.gz -mul ${T2N4}_sub_all_inverted.nii.gz ${T2N4}-Pmap-WM-corr.nii.gz
fi

# combine the subcortical GM tissue probability map with the structures derived from the M-CRIB parcellation and normalize all the maps between 0 and 1.
fslmaths ${T2N4}-Pmap-GM.nii.gz -div 100 ${T2N4}-Pmap-0001.nii.gz
fslmaths ${T2N4}-Pmap-subGM.nii.gz -div 100 ${T2N4}-Pmap-0002_pre.nii.gz
fslmaths ${T2N4}-Pmap-0002_pre.nii.gz -add ${T2N4}_sub_all.nii.gz ${T2N4}-Pmap-0002.nii.gz
fslmaths ${T2N4}-Pmap-WM-corr.nii.gz -div 100 ${T2N4}-Pmap-0003.nii.gz
fslmaths ${T2N4}-Pmap-CSF.nii.gz -div 100 ${T2N4}-Pmap-0004.nii.gz

# ensure that the sum of all the tissue probability maps in all the voxels is equal to 1, we run the following command:
# NOTE - this command uses the function niftiRead and niftiWrite, which can be found in the vistasoft repository. So add it to the path
if [ ! -f ${T2N4}-normalized-Pmap-0004.nii.gz ]; then
    matlab -nodesktop -nosplash -r "clc; clear all; addpath(genpath('$HOME/Software/vistasoft')); STRUCTURAL=niftiRead('${T2N4}.nii.gz'); x=STRUCTURAL.dim(1); y=STRUCTURAL.dim(2); z=STRUCTURAL.dim(3); bigMat=zeros(x*y*z,4); for i=1:4; nii=niftiRead(sprintf('${T2N4}-Pmap-000%d.nii.gz',i)); bigMat(:,i)=nii.data(:); end; bigMat2=bigMat; for j=1:x*y*z; bigMat2(j,:)=bigMat(j,:)./sum(bigMat(j,:)); end; for k=1:4; nii=niftiRead(sprintf('${T2N4}-Pmap-000%d.nii.gz',k)); nii.data=reshape(bigMat2(:,k),[x y z]); niftiWrite(nii,sprintf('${T2N4}-normalized-Pmap-000%d.nii.gz',k)); end; exit"
fi

# finally, merge the files (adding a blanc tissue type at the end for the case of healthy brains) and remove all the NaN values.
if [ ! -f ${T2N4}-5TT.nii.gz ];then
    fslmaths ${T2N4}.nii.gz -mul 0 ${T2N4}-normalized-Pmap-0005.nii.gz
    fslmerge -t ${T2N4}-5TTnan.nii.gz ${T2N4}-normalized-Pmap-0001.nii.gz ${T2N4}-normalized-Pmap-0002.nii.gz ${T2N4}-normalized-Pmap-0003.nii.gz ${T2N4}-normalized-Pmap-0004.nii.gz ${T2N4}-normalized-Pmap-0005.nii.gz
    fslmaths ${T2N4}-5TTnan.nii.gz -nan ${T2N4}-5TT.nii.gz
fi

# Create some 5TT maps for visualization
if [ ! -f ${T2N4}-5TTvis.nii.gz ];then
    5ttvis ${T2N4}-5TT.gz ${T2N4}-5TTvis.nii.gz;
    5tt2gmwmi ${T2N4}-5TT.gz ${T2N4}-5TTgmwmi.nii.gz;
fi

cd $currdir
