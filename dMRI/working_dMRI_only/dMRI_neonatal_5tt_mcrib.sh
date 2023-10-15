#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Runs the 5ttgen mcrib routine for generation of 5TT image from T2w
Also generates/transforms M-CRIB parcellations into space-T2w

Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -s / -session-file		Session file to depict which T2w file that should be used. Overrides defaults below (default: rawdata/sub-sID/ses-ssID/session_QC.tsv)
  -T2				T2w image to use (default: derivatives/dMRI/sub-sID/ses-ssID/anat/sub-sID_ses-ssID_acq-MCRIB_run-1_T2w.nii.gz)
  -threads			Number of CPUs to use (default: 10)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID)
  -h / -help / --help           Print usage.
"
  exit;
}

convertsecs() 
{
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02d:%02d:%02d\n" $h $m $s
}

start=`date +%s`

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2
shift; shift

currdir=$PWD

# Defaults
origdatadir=derivatives/dMRI/sub-$sID/ses-$ssID    #rawdata/sub-$sID/ses-$ssID
sessionfile=$origdatadir/session_QC.tsv
MCRIBpath=/home/perinedo/Projects/Atlases/M-CRIB/M-CRIB_for_MRtrix_5ttgen_neonatal
datadir=derivatives/dMRI/sub-$sID/ses-$ssID/dwi/neonatal_5tt_mcrib #datadir=derivatives/dMRI_neonatal_5tt_mcrib/sub-$sID/ses-$ssID
threads=24

if [ ! -f $sessionfile ]; then
    T2=$origdatadir/anat/sub-${sID}_ses-${ssID}_acq-MCRIB_run-1_T2w.nii.gz
fi

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ $# -gt 0 ]; do
    case "$1" in
	-s|session-file) shift; sessionfile= $1; ;;
	-T2) shift; T2=$1; ;;
	-threads) shift; threads=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $T2 ]; then T2=""; fi
if [ ! -f $sessionfile ]; then sessionfile=""; fi

echo "Generating 5TT image using MRtrix's 5ttgen mcrib routine
Subject:       	$sID 
Session:        $ssID
Session file:	$sessionfile
T2w:		$T2
Directory:     	$datadir 
Threads:	$threads
$BASH_SOURCE   	$command
----------------------------"


logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Create subfolder structure in $datadir

#cd $datadir
#if [ ! -d anat ]; then mkdir -p anat; fi
# if [ ! -d dwi ]; then mkdir -p dwi; fi
# if [ ! -d fmap ]; then mkdir -p fmap; fi
# if [ ! -d xfm ]; then mkdir -p xfm; fi
# if [ ! -d qc ]; then mkdir -p qc; fi
#cd $currdir

##################################################################################
# 0. Create copy file into $datadir/anat and create symbolic link in $datadir/anat

# If we have a session.tsv file, use this
if [ -f $sessionfile ]; then
    # Read $sessionfile and use entries to create relevant files
    {
    bestQCPass=0  # to keep track of the highest QCPass value
    bestFile=""   # to store the best file name with the highest QCPass value
    counter=0
    read
    while IFS= read -r line
    do
        # check if the file/image has passed QC (qc_pass_fail = 4th column)
        QCPass=`echo "$line" | awk '{ print $4 }'`

        # Checking for files with MCRIB in the name
        file=`echo "$line" | awk '{ print $3 }'`
        if echo "$file" | grep -q "MCRIB"; then
            # If the current QCPass value is greater than the bestQCPass value
            if (( $(echo "$QCPass > $bestQCPass" | bc -l) )); then
                bestQCPass=$QCPass
                bestFile=$file
            fi
        fi
    done } < "$sessionfile"

    # Now process only the best file
    if [ ! -z "$bestFile" ]; then
        echo "Best file with QCPass=$bestQCPass is: $bestFile"
        filebase=`basename $bestFile .nii.gz`
        filedir=`dirname $bestFile`
        let counter++
        if [ ! -f $datadir/anat/$filebase.mif.gz ]; then
            cp $origdatadir/$filedir/$filebase.nii.gz $origdatadir/$filedir/$filebase.json $datadir/.
            echo "COPY"
        fi
    fi
    
else
    echo "No session.tsv file, using input/defaults"
    if [ ! -f $T2 ]; then
	counter=1
	filedir=`dirname $T2`
	filebase=`basename $T2 .nii.gz`
	cp $filedir/$filebase.nii.gz $filedir/$filebase.json $datadir/.
    fi
fi

# Check that we only have one T2 file that we have read only 1 T2 file.
if [ ! $counter == 1 ]; then
    echo "None or multiple T2 files - check input and/or $datadir"
    exit
else
    cd $datadir
    # Create a symbolic link to the original T2w image that we have just copied
    ln -s $filebase.nii.gz sub-${sID}_ses-${ssID}_T2w.nii.gz
    cd $currdir
fi
				        
##################################################################################
## 1. Create brain mask, N4-biasfield correct and then perform 5ttgen mcrib
cd $datadir

# Create brain mask
if [ ! -f sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz ]; then
    bet sub-${sID}_ses-${ssID}_T2w.nii.gz tmp.nii.gz -m -R -f 0.3 # 0.25 for diffusion and 0.3 for structural
    mv tmp_mask.nii.gz sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz
    rm tmp*nii.gz
fi
cd $currdir

##################################################################################
## 2. N4-biasfield correct (same procedure with rescaling and then N4 as in dhcp_structural_pipeline)
cd $datadir

if [ ! -f sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz ]; then

    # rescale
    mirtk convert-image sub-${sID}_ses-${ssID}_T2w.nii.gz sub-${sID}_ses-${ssID}_desc-rescaled_T2w.nii.gz -rescale 0 1000 -double

    # N4 biasfield (ANTs)
    mirtk N4 3 -i sub-${sID}_ses-${ssID}_desc-rescaled_T2w.nii.gz -x sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz -o [sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz,sub-${sID}_ses-${ssID}_desc-biasfield_T2w.nii.gz] -c [50x50x50,0.001] -s 2 -b [100,3] -t [0.15,0.01,200]

    # clean up
    rm sub-${sID}_ses-${ssID}_desc-rescaled_T2w.nii.gz

fi
cd $currdir

##################################################################################
## 3. Perform 5ttgen mcrib
cd $datadir

scratchdir=5ttgen_mcrib

# Run 5ttgen mcrib
# NOTE - built from Manuel Blesa's github repo https://github.com/mblesac/mrtrix3/tree/5ttgen_neonatal_rs

if [ ! -f sub-${sID}_ses-${ssID}_5TT.nii.gz ]; then
    5ttgen mcrib \
	   -mask sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz \
	   -mcrib_path $MCRIBpath \
	   -ants_parallel 2 -nthreads $threads \
	   -nocleanup -scratch $scratchdir \
	   -sgm_amyg_hipp \
	   -parcellation sub-${sID}_ses-${ssID}_desc-mcrib_dseg.nii.gz \
	   sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz t2w sub-${sID}_ses-${ssID}_5TT.nii.gz
    # clean up
    # rm -rf $scratchdir
fi
# sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz  is the input T2 file that was N4 corrected
# sub-${sID}_ses-${ssID}_5TT.nii.gz are the 5tt which is a 4d tensor
cd $currdir

#######################################################################################

end=`date +%s`
runtime=$((end-start))
TIME=$(convertsecs $runtime)
echo "Total runtime = $TIME"
