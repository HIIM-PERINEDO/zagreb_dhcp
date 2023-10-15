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
            #cp $origdatadir/$filedir/$filebase.nii.gz $origdatadir/$filedir/$filebase.json $datadir/.
            echo "COPY"
        fi
    fi
    
else
    echo "No session.tsv file, using input/defaults"
    if [ ! -f $T2 ]; then
	counter=1
	filedir=`dirname $T2`
	filebase=`basename $T2 .nii.gz`
	#cp $filedir/$filebase.nii.gz $filedir/$filebase.json $datadir/.
    fi
fi

EARLIER:
# If we have a session.tsv file, use this
if [ -f $sessionfile ]; then
    # Read $sessionfile and use entries to create relevant files
    {
	counter=0
	read
	while IFS= read -r line
	do
	    # check if the file/image has passed QC (qc_pass_fail = 4th column)
	    QCPass=`echo "$line" | awk '{ print $4 }'`

        if [ $QCPass == 1 ] || [ $QCPass  == 0.5 ] ; then
            #### Read flags in session.tsv file with corresponding column index
            ## Flag for use of sMRI in 5ttgen mcrib (sMRI_use_for_5ttgen_mcrib = 9th column)

            #NEW CODE START
            file=`echo "$line" | awk '{ print $3 }'`
            echo $file
            
            #if has MCRIB in name then select is as the file
            if echo "$file" | grep -q "MCRIB"; then
                echo "IS VALID"
                filebase=`basename $file .nii.gz`
                filedir=`dirname $file`
                let counter++

                if [ $QCPass == 0.5 ] && [ -f $datadir/anat/$filebase.nii.gz ]; then
                    echo "Skipping as QCPass 1 file already exists"
                    continue
                fi

                if [ ! -f $datadir/anat/$filebase.nii.gz ]; then
                    cp $origdatadir/$filedir/$filebase.nii.gz $origdatadir/$filedir/$filebase.json $datadir/.
                fi
            else
                echo "IS NOT VALID"
            fi
            #NEW CODE END

            # sMRI_use_for_5ttgen_mcrib=`echo "$line" | awk '{ print $9 }'`
            # if [ $sMRI_use_for_5ttgen_mcrib == 1 ]; then
            #     # Get file from column nbr 3
            #     file=`echo "$line" | awk '{ print $3 }'`
            #     filebase=`basename $file .nii.gz`
            #     filedir=`dirname $file`
            #     let counter++
            #     if [ ! -f $datadir/anat/$filebase.mif.gz ]; then
            #     cp $origdatadir/$filedir/$filebase.nii.gz $origdatadir/$filedir/$filebase.json $datadir/.
            #     fi
            # fi

	    fi
	    
	done
    } < "$sessionfile"
else
    echo "No session.tsv file, using input/defaults"
    if [ ! -f $T2 ]; then
	counter=1
	filedir=`dirname $T2`
	filebase=`basename $T2 .nii.gz`
	cp $filedir/$filebase.nii.gz $filedir/$filebase.json $datadir/.
    fi
fi