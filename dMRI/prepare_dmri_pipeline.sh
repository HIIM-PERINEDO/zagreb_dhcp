#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Script to create for the structure for the dMRI processing pipeline folder on session level 
Creates folder structure 
$datadir
       	/dwi
	/anat
	/fmap
	/qc
	/xfm
	/logs
copies the relevant files (often given by images which have passed QC logged in session_QC.tsv file) into subfolder /orig in /dwi, /anat and /fmap
Also copies the session.tsv (if present rawdata/sub-$sID/ses-$ssID) into $datadir

Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -s / session-file		session.tsv that list files in rawdata/sub-sID/ses-ssID that should be used! Overrides options below (default: rawdata/sub-sID/ses-ssID/session_QC.tsv)
  -dwi				dMRI AP data (default: rawdata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-AP_run-1_dwi.nii.gz)
  -dwiAPsbref			dMRI AP SBRef, potentially for registration and  TOPUP  (default: rawdata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-AP_run-1_sbref.nii.gz)
  -dwiPA			dMRI PA data, potentially for TOPUP  (default: rawdata/sub-sID/ses-ssID/fmap/sub-sID_ses-ssID_acq-dwi_dir-PA_run-1_epi.nii.gz)
  -dwiPAsbref			dMRI PA SBRef, potentially for registration and TOPUP  (default: rawdata/sub-sID/ses-ssID/dwi/sub-sID_ses-ssID_dir-PA_run-1_sbref.nii.gz)
  -seAP				Spin-echo field map AP, for TOPUP (default: rawdata/sub-sID/ses-ssID/fmap/sub-sID_ses-ssID_acq-se_dir-AP_run-1_epi.nii.gz)
  -sePA				Spin-echo field map PA, for TOPUP (default: rawdata/sub-sID/ses-ssID/fmap/sub-sID_ses-ssID_acq-se_dir-PA_run-1_epi.nii.gz)
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

currdir=$PWD

# Defaults
dwi=rawdata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-AP_run-1_dwi.nii.gz
dwiPA=rawdata/sub-$sID/ses-$ssID/fmap/sub-${sID}_ses-${ssID}_acq-dwi_dir-PA_run-1_epi.nii.gz
dwiAPsbref=rawdata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-AP_run-1_sbref.nii.gz
dwiPAsbref=rawdata/sub-$sID/ses-$ssID/dwi/sub-${sID}_ses-${ssID}_dir-PA_run-1_sbref.nii.gz
seAP=rawdata/sub-$sID/ses-$ssID/fmap/sub-${sID}_ses-${ssID}_acq-se_dir-AP_run-1_epi.nii.gz
sePA=rawdata/sub-$sID/ses-$ssID/fmap/sub-${sID}_ses-${ssID}_acq-se_dir-PA_run-1_epi.nii.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID
sessionfile=rawdata/sub-$sID/ses-$ssID/session_QC.tsv

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-s|-session-file)  shift; sessionfile=$1; ;;
	-dwi) shift; dwi=$1; ;;
	-dwiAPsbref) shift; dwiAPsbref=$1; ;;
	-dwiPA) shift; dwiPA=$1; ;;
	-dwiPAsbref) shift; dwiPAsbref=$1; ;;
	-seAP) shift; seAP=$1; ;;
	-seAP) shift; sePA=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if files exist, else put in blank/No_image
if [ ! -f $sessionfile ]; then sessionfile=""; fi
if [ ! -f $dwi ]; then dwi=""; fi
if [ ! -f $dwiAPsbref ]; then dwiAPsbref=""; fi
if [ ! -f $dwiPA ]; then dwiPA=""; fi
if [ ! -f $dwiPAsbref ]; then dwiPAsbref=""; fi
if [ ! -f $seAP ]; then seAP=""; fi
if [ ! -f $sePA ]; then sePA=""; fi

if [ ! $sessionfile == "" ]; then
    echo "Preparing for dMRI pipeline
    Subject:           $sID 
    Session:           $ssID
    Session file:      $sessionfile
    Data directory:    $datadir 

    $BASH_SOURCE       $command
    ----------------------------"
else
    
    echo "Preparing for dMRI pipeline
    Subject:       	$sID 
    Session:        	$ssID
    DWI (AP):		$dwi
    DWI (AP_SBRef):	$dwiAPsbref
    DWI (PA):      	$dwiPA
    DWI (PA_SBRef):	$dwiPAsbref
    SE fMAP (AP):  	$seAP	       
    SE fMAP (PA):  	$sePA	       
    Directory:     	$datadir 

    $BASH_SOURCE   	$command
    ----------------------------"
fi

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_dMRI_$script.log 2>&1
echo


##################################################################################
# 0a. Create subfolders in $datadir

cd $datadir
if [ ! -d anat/orig ]; then mkdir -p anat/orig; fi
if [ ! -d dwi/orig ]; then mkdir -p dwi/orig; fi
if [ ! -d fmap/orig ]; then mkdir -p fmap/orig; fi
if [ ! -d xfm ]; then mkdir -p xfm; fi
if [ ! -d qc ]; then mkdir -p qc; fi
cd $currdir

##################################################################################
# 0. Copy to files to $datadir (incl .json and bvecs/bvals files if present at original location)

if [ -f $sessionfile ]; then
    # Use files listed in "session.tsv" file, which refer to file on session level in BIDS rawdata directory
    rawdatadir=rawdata/sub-$sID/ses-$ssID
    # Read $sessionfile, copy files and meanwhile create a local session_QC.tsv in $datadir
    echo "Transfer data in $sessionfile which has qc_pass_fail = 1 or 0.5"
    {
	linecounter=1	
	while IFS= read -r line
	do
	      if [ $linecounter == 1 ] && [ ! -f $datadir/session_QC.tsv ]; then
		  echo $line > $datadir/session_QC.tsv;
	      fi
	      # check if the file/image has passed QC (qc_pass_fail = fourth column) (1 or 0.5)
	      QCPass=`echo "$line" | awk '{ print $4 }'`
	      if [[ $QCPass == 1 || $QCPass == 0.5 ]]; then
		  file=`echo "$line" | awk '{ print $3 }'`
		  filebase=`basename $file .nii.gz`
		  filedir=`dirname $file`
		  case $filedir in
		      anat)
			  if [ ! -f $datadir/anat/orig/$filebase.nii.gz ]; then 
			      cp $rawdatadir/$filedir/$filebase.nii.gz $rawdatadir/$filedir/$filebase.json $datadir/anat/orig/.
			      echo "$line" | sed "s/$filedir/$filedir\/orig/g" >> $datadir/session_QC.tsv
			  fi
			  ;;
		      dwi)
			  if [ ! -f $datadir/anat/dwi/$filebase.nii.gz ]; then 
		    	      cp $rawdatadir/$filedir/$filebase.nii.gz $rawdatadir/$filedir/$filebase.json $rawdatadir/$filedir/$filebase.bval $rawdatadir/$filedir/$filebase.bvec $datadir/dwi/orig/.
			      echo "$line" | sed "s/$filedir/$filedir\/orig/g" >> $datadir/session_QC.tsv
			  fi
			  ;;		      
		      fmap)
			  if [ ! -f $datadir/anat/fmap/$filebase.nii.gz ]; then 
			      cp $rawdatadir/$filedir/$filebase.nii.gz $rawdatadir/$filedir/$filebase.json $datadir/fmap/orig/.
			      echo "$line" | sed "s/$filedir/$filedir\/orig/g" >> $datadir/session_QC.tsv
			  fi
			  ;;
		  esac
	      fi
	      let linecounter++
	done
    } < "$sessionfile";
        
else
    # no session_QC.tsv file, so use files from input
    filelist="$dwi $dwiAPsbref $dwiPA $dwiPAsbref $seAP $sePA"
    for file in $filelist; do
	filebase=`basename $file .nii.gz`;
	filedir=`dirname $file`
	if [ $file == $dwi ]; then
	    cp $file $filedir/$filebase.json $filedir/$filebase.bval $filedir/$filebase.bvec $datadir/dwi/orig/.
	else # should be put in /fmap
	    cp $file $filedir/$filebase.json $datadir/fmap/orig/.
	fi	
    done
fi

##################################################################################



