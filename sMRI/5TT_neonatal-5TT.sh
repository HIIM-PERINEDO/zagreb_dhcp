#!/bin/bash
# Zagreb_Collab - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID age neonatal-segmentation-directory [options]
Script to do M-CRIB neonatal-5TT (follows: https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT)

Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -s / -seg-dir <directory>	Root directory were the neonatal-segmentaion resides (default: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation)		
  -T2  				T2 (N4 biasfield corrected) that was used for segmentation (default: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation/N4/sub-sID_ses-ssID_desc-preproc_T2w.nii.gz)		
  -a / -atlas <directory>	DrawEM processed M-CRIB atlas location (default: $HOME/Research/Atlases/M-CRIB/derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_M-CRIB_preproc_neonatal-5TT)
  -d / -data-dir <directory>	Data dir for output (default: derivatives/sMRI/sub-sID/ses-ssID/neonatal-segmentation)
  -t / -threads  <number>       Number of threads (CPU cores) allowed for the registration to run in parallel (default: 10)
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

segdir=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation
T2=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation/N4/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz
atlasdir=$HOME/Research/Atlases/M-CRIB/derivatives/neonatal-segmentation_DrawEMv1p3_ALBERT_M-CRIB_preproc_neonatal-5TT
datadir=derivatives/sMRI/sub-$sID/ses-$ssID/neonatal-segmentation
threads=10

while [ $# -gt 0 ]; do
    case "$1" in
	-s|-seg-dir) shift; segdir=$1; ;;
	-d|-data-dir) shift; datadir=$1; ;;
	-t|-threads)  shift; threads=$1; ;;
	-a|-atlas)  shift; atlasdir=$1; ;; 
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Folder and paths
currdir=$PWD
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#studyneo5ttdir=${segdir}_neonatal-5TT
neo5ttdir=$datadir/5TT_neonatal-5TT;

echo "Neonatal-5TT
Subject:	$sID 
Session:    	$ssID
Segmentation:	$segdir
T2 (N4):	$T2
Atlas:      	$atlasdir
Data dir:	$datadir
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
#if [ ! -d $studyneo5ttdir/atlas ]; then mkdir -p $studyneo5ttdir/atlas; fi

# and put all the atlas files locally
#cp $atlasdir/* $studyneo5ttdir/atlas/.


###################################################################################3
# Copy files and make match histograms

# Go to the processing folder
currdir=$PWD
if [ ! -d $neo5ttdir ]; then mkdir -p $neo5ttdir; fi

# Relevant files to copy and create
T2base=`basename $T2 .nii.gz`
T2N4=${T2base}_N4; #adding _N4 to show that it is N4 biasfield corrected and comply with $atlasdir
brainmaskdrawem=desc-drawembrain_mask; #name compliant with $atlasdir

# Copy T2w N4 file
if [ ! -f $neo5ttdir/$T2N4.nii.gz ]; then
    cp $T2 $neo5ttdir/$T2N4.nii.gz
fi
# and create an equivalent brain_mask_drawem
if [ ! -f  $neo5ttdir/${T2base}_$brainmaskdrawem.nii.gz ]; then
    mirtk padding \
	  $segdir/segmentations/${T2base}_tissue_labels.nii.gz \
	  $segdir/segmentations/${T2base}_tissue_labels.nii.gz \
	  $neo5ttdir/${T2base}_$brainmaskdrawem.nii.gz 2 1 4 0
fi


###################################################################################
## Neonatal-5TT pipeline
# 1. Intensity histogram matching between the M-CRIB templates and our subject

cd  $neo5ttdir

for i in $(seq -f %02g 1 10); do
    if [ ! -f ${T2N4}_M-CRIB_P${i}_T2_hist.nii.gz ]; then
	mrhistmatch -mask_input $atlasdir/M-CRIB_P${i}_T2_$brainmaskdrawem.nii.gz \
		    -mask_target ${T2}_$brainmaskdrawem.nii.gz \
		    scale $atlasdir/M-CRIB_P${i}_T2_N4.nii.gz $T2N4.nii.gz \
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
			    -g ${T2N4}_M-CRIB_P01_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P01_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P02_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P02_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P03_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P03_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P04_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P04_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P05_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P05_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P06_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P06_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P07_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P07_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P08_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P08_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P09_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P09_parc_mrtrix.nii.gz \
			    -g ${T2N4}_M-CRIB_P10_T2_hist.nii.gz -l $atlasdir/M-CRIB_orig_P10_parc_mrtrix.nii.gz;
fi

cd $currdir


###################################################################################3
## Neonatal-5TT pipeline
# 3. Create probability maps by combining the obtained label from the previous step with the probability maps obtained from the dHCP pipeline.

# Pmap GM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-GM.nii.gz ]; then
#    fslmaths $segdir/posteriors/gm/$T2base.nii.gz $neo5ttdir/${T2N4}-Pmap-GM.nii.gz
    fslmaths $segdir/posteriors/seg1/$T2base.nii.gz \
	     -add $segdir/posteriors/seg2/$T2base.nii.gz \
	     -add $segdir/posteriors/seg3/$T2base.nii.gz \
	     -add $segdir/posteriors/seg4/$T2base.nii.gz \
	     -add $segdir/posteriors/seg5/$T2base.nii.gz \
	     -add $segdir/posteriors/seg6/$T2base.nii.gz \
	     -add $segdir/posteriors/seg7/$T2base.nii.gz \
	     -add $segdir/posteriors/seg8/$T2base.nii.gz \
	     -add $segdir/posteriors/seg9/$T2base.nii.gz \
	     -add $segdir/posteriors/seg10/$T2base.nii.gz \
	     -add $segdir/posteriors/seg11/$T2base.nii.gz \
	     -add $segdir/posteriors/seg12/$T2base.nii.gz \
	     -add $segdir/posteriors/seg13/$T2base.nii.gz \
	     -add $segdir/posteriors/seg14/$T2base.nii.gz \
	     -add $segdir/posteriors/seg15/$T2base.nii.gz \
	     -add $segdir/posteriors/seg16/$T2base.nii.gz \
	     -add $segdir/posteriors/seg20/$T2base.nii.gz \
	     -add $segdir/posteriors/seg21/$T2base.nii.gz \
	     -add $segdir/posteriors/seg22/$T2base.nii.gz \
	     -add $segdir/posteriors/seg23/$T2base.nii.gz \
	     -add $segdir/posteriors/seg24/$T2base.nii.gz \
	     -add $segdir/posteriors/seg25/$T2base.nii.gz \
	     -add $segdir/posteriors/seg26/$T2base.nii.gz \
	     -add $segdir/posteriors/seg27/$T2base.nii.gz \
	     -add $segdir/posteriors/seg28/$T2base.nii.gz \
	     -add $segdir/posteriors/seg29/$T2base.nii.gz \
	     -add $segdir/posteriors/seg30/$T2base.nii.gz \
	     -add $segdir/posteriors/seg31/$T2base.nii.gz \
	     -add $segdir/posteriors/seg32/$T2base.nii.gz \
	     -add $segdir/posteriors/seg33/$T2base.nii.gz \
	     -add $segdir/posteriors/seg34/$T2base.nii.gz \
	     -add $segdir/posteriors/seg35/$T2base.nii.gz \
	     -add $segdir/posteriors/seg36/$T2base.nii.gz \
	     -add $segdir/posteriors/seg37/$T2base.nii.gz \
	     -add $segdir/posteriors/seg38/$T2base.nii.gz \
	     -add $segdir/posteriors/seg39/$T2base.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-GM.nii.gz  
fi
# Pmap CSF
if [ ! -f $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz ]; then
#    fslmaths $segdir/posteriors/csf/$T2base.nii.gz $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz  
    fslmaths $segdir/posteriors/seg49/$T2base.nii.gz \
	     -add $segdir/posteriors/seg50/$T2base.nii.gz \
	     -add $segdir/posteriors/seg83/$T2base.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-CSF.nii.gz
fi
# Pmap WM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-WM.nii.gz ]; then
    #    fslmaths $segdir/posteriors/wm/$T2base.nii.gz $neo5ttdir/${T2N4}-Pmap-WM.nii.gz
    fslmaths $segdir/posteriors/seg19/$T2base.nii.gz \
	     -add $segdir/posteriors/seg51/$T2base.nii.gz \
	     -add $segdir/posteriors/seg52/$T2base.nii.gz \
	     -add $segdir/posteriors/seg53/$T2base.nii.gz \
	     -add $segdir/posteriors/seg54/$T2base.nii.gz \
	     -add $segdir/posteriors/seg55/$T2base.nii.gz \
	     -add $segdir/posteriors/seg56/$T2base.nii.gz \
	     -add $segdir/posteriors/seg57/$T2base.nii.gz \
	     -add $segdir/posteriors/seg58/$T2base.nii.gz \
	     -add $segdir/posteriors/seg59/$T2base.nii.gz \
	     -add $segdir/posteriors/seg60/$T2base.nii.gz \
	     -add $segdir/posteriors/seg61/$T2base.nii.gz \
	     -add $segdir/posteriors/seg62/$T2base.nii.gz \
	     -add $segdir/posteriors/seg63/$T2base.nii.gz \
	     -add $segdir/posteriors/seg64/$T2base.nii.gz \
	     -add $segdir/posteriors/seg65/$T2base.nii.gz \
	     -add $segdir/posteriors/seg66/$T2base.nii.gz \
	     -add $segdir/posteriors/seg67/$T2base.nii.gz \
	     -add $segdir/posteriors/seg68/$T2base.nii.gz \
	     -add $segdir/posteriors/seg69/$T2base.nii.gz \
	     -add $segdir/posteriors/seg70/$T2base.nii.gz \
	     -add $segdir/posteriors/seg71/$T2base.nii.gz \
	     -add $segdir/posteriors/seg72/$T2base.nii.gz \
	     -add $segdir/posteriors/seg73/$T2base.nii.gz \
	     -add $segdir/posteriors/seg74/$T2base.nii.gz \
	     -add $segdir/posteriors/seg75/$T2base.nii.gz \
	     -add $segdir/posteriors/seg76/$T2base.nii.gz \
	     -add $segdir/posteriors/seg77/$T2base.nii.gz \
	     -add $segdir/posteriors/seg78/$T2base.nii.gz \
	     -add $segdir/posteriors/seg79/$T2base.nii.gz \
	     -add $segdir/posteriors/seg80/$T2base.nii.gz \
	     -add $segdir/posteriors/seg81/$T2base.nii.gz \
	     -add $segdir/posteriors/seg82/$T2base.nii.gz \
	     -add $segdir/posteriors/seg85/$T2base.nii.gz \
	     -add $segdir/posteriors/seg48/$T2base.nii.gz \
	     -add $segdir/posteriors/seg40/$T2base.nii.gz \
	     -add $segdir/posteriors/seg41/$T2base.nii.gz \
	     -add $segdir/posteriors/seg42/$T2base.nii.gz \
	     -add $segdir/posteriors/seg43/$T2base.nii.gz \
	     -add $segdir/posteriors/seg44/$T2base.nii.gz \
	     -add $segdir/posteriors/seg45/$T2base.nii.gz \
	     -add $segdir/posteriors/seg46/$T2base.nii.gz \
	     -add $segdir/posteriors/seg47/$T2base.nii.gz \
	     -add $segdir/posteriors/seg86/$T2base.nii.gz \
	     -add $segdir/posteriors/seg87/$T2base.nii.gz \
	     $neo5ttdir/${T2N4}-Pmap-WM.nii.gz
fi
# Pmap subcortical GM
if [ ! -f $neo5ttdir/${T2N4}-Pmap-subGM.nii.gz ]; then
    fslmaths $segdir/posteriors/seg17/$T2base.nii.gz -add \
	     $segdir/posteriors/seg18/$T2base.nii.gz \
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
