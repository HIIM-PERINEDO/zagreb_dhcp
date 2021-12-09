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
  -s / -session-file		Session file to depict which T2w file that should be used. Overrides defaults below (default: $rawdatadir/session.tsv)
  -t2w				T2w image to use (default: $rawdatadir/anat/sub-sID_ses-ssID_acq-SPC_run-1_t2w.nii.gz)
  -threads			Number of CPUs to use (default: 10)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI_study_structural_connectivity_PKandPMR/sub-sID/ses-ssID)
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
rawdatadir=rawdata/sub-$sID/ses-$ssID
sessionfile=$rawdatadir/session.tsv
threads=10

datadir=derivatives/dMRI_study_structural_connectivity_PKandPMR/sub-$sID/ses-$ssID
if [ ! -f $sessionfile ]; then
    t2w=$rawdatadir/anat/sub-${sID}_ses-${ssID}_acq-SPC_run-1_t2w.nii.gz
fi

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ $# -gt 0 ]; do
    case "$1" in
	-s|session-file) shift; sessionfile= $1; ;;
	-t2w) shift; t2w=$1; ;;
	-threads) shift; threads=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $t2w ]; then t2w=""; fi
if [ ! -f $sessionfile ]; then sessionfile=""; fi

echo "Generating 5TT image using MRtrix's 5ttgen mcrib routine
Subject:       	$sID 
Session:        $ssID
Session file:	$sessionfile
T2w:		$t2w
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

cd $datadir
if [ ! -d anat ]; then mkdir -p anat; fi
if [ ! -d dwi ]; then mkdir -p dwi; fi
if [ ! -d fmap ]; then mkdir -p fmap; fi
if [ ! -d xfm ]; then mkdir -p xfm; fi
if [ ! -d qc ]; then mkdir -p qc; fi
cd $currdir

##################################################################################
# 0. Create copy file into $datadir/anat and create symbolic link in $datadir/anat

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

	    if [ $QCPass == 1 ]; then
		
		# Get file from column nbr 3
		file=`echo "$line" | awk '{ print $3 }'`
		filebase=`basename $file .nii.gz`
		filedir=`dirname $file`

		#### Read flags in session.tsv file with corresponding column index
		## Flag for use of sMRI in 5ttgen mcrib (sMRI_use_for_5ttgen_mcrib = 9th column)
		sMRI_use_for_5ttgen_mcrib=`echo "$line" | awk '{ print $9 }'`
		if [ $sMRI_use_for_5ttgen_mcrib == 1 ]; then
		    let counter++
		    if [ ! -f $datadir/anat/$filebase.mif.gz ]; then
			cp $rawdatadir/$filedir/$filebase.nii.gz $rawdatadir/$filedir/$filebase.json $datadir/anat/.
		    fi
		fi
	    fi
	    
	done
    } < "$sessionfile"
else
    echo "No session.tsv file, using input/defaults"
    if [ ! -f $t2w ]; then
	counter=1
	filedir=`dirname $t2w`
	filebase=`basename $t2w .nii.gz`
	cp $filedir/$filebase.nii.gz $filedir/$filebase.json $datadir/anat/.
    fi
fi

# Check that we only have one t2w file that we have read only 1 t2w file.
if [ ! $counter == 1 ]; then
    echo "None or multiple t2w files - check input and/or $datadir/anat"
    exit
else
    cd $datadir/anat
    # Create a symbolic link to the original T2w image that we have just copied
    ln -s $filebase.nii.gz sub-${sID}_ses-${ssID}_T2w.nii.gz
    cd $currdir
fi
				        
##################################################################################
## 1. Create brain mask, N4-biasfield correct and then perform 5ttgen mcrib
cd $datadir/anat

# Create brain mask
if [ ! -f sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz ]; then
    bet sub-${sID}_ses-${ssID}_T2w.nii.gz tmp.nii.gz -m -R
    mv tmp_mask.nii.gz sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz
    rm tmp*nii.gz
fi
cd $currdir

##################################################################################
## 2. N4-biasfield correct (same procedure with rescaling and then N4 as in dhcp_structural_pipeline)
cd $datadir/anat

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
cd $datadir/anat

MCRIBpath=/home/finn/Research/Atlases/M-CRIB/5ttgen_mcrib_atlas_input
scratchdir=5ttgen_mcrib

# Run 5ttgen mcrib
# NOTE - built from Manuel Blesa's github repo https://github.com/mblesac/mrtrix3/tree/5ttgen_neonatal_rs

if [ ! -f sub-${sID}_ses-${ssID}_5TT.nii.gz ]; then
    5ttgen mcrib \
	   -mask sub-${sID}_ses-${ssID}_desc-brain_mask.nii.gz \
	   -mcrib_path $MCRIBpath \
	   -ants_parallel 2 -cores $threads \
	   -nocleanup -scratch $scratchdir \
	   -sgm_amyg_hipp \
	   -parcellation sub-${sID}_ses-${ssID}_desc-mcrib_dseg.nii.gz \
	   sub-${sID}_ses-${ssID}_desc-restore_T2w.nii.gz sub-${sID}_ses-${ssID}_5TT.nii.gz t2w
    # clean up
    # rm -rf $scratchdir
fi

cd $currdir

#######################################################################################
