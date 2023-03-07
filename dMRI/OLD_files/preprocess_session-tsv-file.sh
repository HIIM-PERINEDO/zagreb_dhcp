#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Script to preprocess dMRI data 
Requires that folder structure for dMRI pipeline has been run (e.g. with script prepare_dmri_pipeline.sh)
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction
3. N4 biasfield correction, Normalisation

Arguments:
  sID				Subject ID (e.g. PMR001) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -s / -session-file		Session file to depict which files should go into preprocessing. Overrides defaults below (default: $datadir/session.tsv)
  -dwi				dMRI AP data (default: $datadir/dwi/orig/sub-sID_ses-ssID_dir-AP_run-1_dwi.nii.gz)
  -SE-pair			SE APPA pair for TOPUP - NOTE vol 0 will go in as first bzero in dwi (default: $datadir/dwi/preproc/b0APPA.mif.gz)
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
shift; shift

currdir=$PWD

# Defaults
rawdatadir=rawdata/sub-$sID/ses-$ssID
sessionfile=$rawdatadir/session.tsv

datadir=derivatives/dMRI_study_structural_connectivity_PKandPMR/sub-$sID/ses-$ssID
if [ ! -f $sessionfile ]; then
    dwi=$datadir/dwi/orig/sub-${sID}_ses-${ssID}_dir-AP_run-1_dwi.nii.gz
    b0APPA=$datadir/dwi/b0APPA.mif.gz
fi

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


while [ $# -gt 0 ]; do
    case "$1" in
	-s|session-file) shift; sessionfile= $1; ;;
	-dwi) shift; dwi=$1; ;;
	-SE-pair) shift; sepair=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $dwi ]; then dwi=""; fi
if [ ! -f $sessionfile ]; then sessionfile=""; fi
if [ ! -f $sepair ]; then sepair=""; fi

echo "dMRI preprocessing
Subject:       	$sID 
Session:        $ssID
Session file:	$sessionfile
DWI (AP):	$dwi
SE pair:	$sepair	       
Directory:     	$datadir 
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
# 1. Creae dwi.mif.gz in $datadir/dwi/preproc and put b0AP.mif.gz b0PA.mif.gz in $datadir/dwi/preproc/topup

if [ ! -d $datadir/dwi/preproc/topup ]; then mkdir -p $datadir/dwi/preproc/topup; fi

# If we have a session.tsv file, use this
if [ -f $sessionfile ]; then
    # Read $sessionfile and use entries to create relevant files
    {
	read
	while IFS= read -r line
	do
	    # check if the file/image has passed QC (qc_pass_fail = fourth column)
	    QCPass=`echo "$line" | awk '{ print $4 }'`

	    if [ $QCPass == 1 ]; then
		
		# Get file from column nbr 3
		file=`echo "$line" | awk '{ print $3 }'`
		filebase=`basename $file .nii.gz`
		filedir=`dirname $file`

		#### Read flags in session.tsv file with corresponding column index
		## DWI AP data
		dwiAP=`echo "$line" | awk '{ print $6 }'`
		if [ $dwiAP == 1 ]; then		    
		    if [ ! -f $datadir/dwi/preproc/dwi.mif.gz ]; then 
			mrconvert -json_import $rawdatadir/$filedir/$filebase.json \
				  -fslgrad $rawdatadir/$filedir/$filebase.bvec $rawdatadir/$filedir/$filebase.bval \
				  $rawdatadir/$filedir/$filebase.nii.gz $datadir/dwi/preproc/dwi.mif.gz
		    fi
		fi		
		## b0AP and b0PA data
		volb0AP=`echo "$line" | awk '{ print $7 }'`
		if [ ! $volb0AP == "-" ]; then
		    if [ ! -f $datadir/dwi/preproc/b0AP.mif.gz ]; then
			mrconvert $rawdatadir/$filedir/$filebase.nii.gz -json_import $rawdatadir/$filedir/$filebase.json - | \
			    mrconvert -coord 3 $volb0AP -axes 0,1,2 - $datadir/dwi/preproc/topup/b0AP.mif.gz
		    fi
		fi
		volb0PA=`echo "$line" | awk '{ print $8 }'`
		if [ ! $volb0PA == "-" ]; then
		    if [ ! -f $datadir/dwi/preproc/b0PA.mif.gz ]; then
			mrconvert $rawdatadir/$filedir/$filebase.nii.gz -json_import $rawdatadir/$filedir/$filebase.json $datadir/dwi/preproc/topup/b0PA.mif.gz
		    fi
		fi
	    fi
	    
	done
    } < "$sessionfile"
else
    echo "No session.tsv file, using input/defaults"
    filedir=`dirname $dwi`
    filebase=`basename $dwi .nii.gz`
    mrconvert $filedir/$filebase.nii.gz \
	      -json_import $filedir/$filebase.json \
	      -fslgrad $filedir/$filebase.bvec $filedir/$filebase.bval  \
	      $datadir/dwi/preproc/dwi.mif.gz
fi


##################################################################################
# 1b. Create b0APPA.mif.gz in $datadir/dwi/preproc/topup

cd $datadir/dwi/preproc

if [ ! -d topup ]; then mkdir topup; fi

# Create b0APPA.mif.gz to go into TOPUP
if [ ! -f topup/b0APPA.mif.gz ]; then
    if [ -f topup/b0AP.mif.gz ] && [ -f topup/b0PA.mif.gz ]; then
	echo "Creating b0APPA.mif.gz from b0AP.mif.gz and b0PA.mif.gz"
	mrcat topup/b0AP.mif.gz topup/b0PA.mif.gz topup/b0APPA.mif.gz
    else
	echo "No b0APPA.mif.gz or pair of b0AP.mif.gz and b0PA.mif.gz are present to use with TOPUP 
	1. Do this by put one good b0 from dir-AP_dwi and dir-PA_dwi into a file b0APPA.mif.gz into $datadir/dwi/preproc/topup
	2. The same b0 from dir-AP_dwi should be put 1st in the dir-AP_dwi dataset, as dwifslpreprocess will use the 1st b0 in dir-AP and replace the first b0 in b0APPA with
	3. Run this script again.    
    	 "
	exit;
    fi
fi

cd $currdir


##################################################################################
# 2. Do PCA-denoising and Remove Gibbs Ringing Artifacts
cd $datadir/dwi/preproc

# Directory for QC files
if [ ! -d denoise ]; then mkdir denoise; fi

# Perform PCA-denosing
if [ ! -f dwi_den.mif.gz ]; then
    echo Doing MP PCA-denosing with dwidenoise
    # PCA-denoising
    dwidenoise dwi.mif.gz dwi_den.mif.gz -noise denoise/dwi_noise.mif.gz;
    # and calculate residuals
    mrcalc dwi.mif.gz dwi_den.mif.gz -subtract denoise/dwi_den_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

# Directory for QC files
if [ ! -d unring ]; then mkdir unring; fi

if [ ! -f dwi_den_unr.mif.gz ]; then
    echo Remove Gibbs Ringing Artifacts with mrdegibbs
    # Gibbs 
    mrdegibbs -axes 0,1 dwi_den.mif.gz dwi_den_unr.mif.gz
    #calculate residuals
    mrcalc dwi_den.mif.gz  dwi_den_unr.mif.gz -subtract unring/dwi_den_unr_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

cd $currdir

##################################################################################
# 3. TOPUP and EDDY for Motion- and susceptibility distortion correction
# Do Topup and Eddy with dwifslpreproc and use topup/b0APPA.mif.gz as SE-pair for TOPUP
#
cd $datadir/dwi/preproc

scratchdir=dwifslpreproc

if [ ! -f dwi_den_unr_eddy.mif.gz ];then
    dwifslpreproc -se_epi topup/b0APPA.mif.gz -rpe_header -align_seepi \
		  -nocleanup \
		  -scratch $scratchdir \
		  -topup_options " --iout=field_mag_unwarped" \
		  -eddy_options " --slm=linear --repol --mporder=8 --s2v_niter=10 --s2v_interp=trilinear --s2v_lambda=1 --estimate_move_by_susceptibility --mbs_niter=20 --mbs_ksp=10 --mbs_lambda=10 " \
		  -eddyqc_all eddy \
		  dwi_den_unr.mif.gz \
		  dwi_den_unr_eddy.mif.gz;
    # or use -rpe_pair combo: dwifslpreproc DWI_in.mif DWI_out.mif -rpe_pair -se_epi b0_pair.mif -pe_dir ap -readout_time 0.72 -align_seepi
fi
# Now cleanup by transferring relevant files to topup folder and deleting scratch folder
mv eddy/quad ../../qc/.
cp $scratchdir/command.txt $scratchdir/log.txt $scratchdir/eddy_*.txt $scratchdir/applytopup_*.txt $scratchdir/slspec.txt eddy/.
mv $scratchdir/field_* $scratchdir/topup_* topup/.
rm -rf $scratchdir 

cd $currdir


##################################################################################
# 3. Mask generation, N4 biasfield correction, meanb0 generation and tensor estimation
cd $datadir/dwi/preproc

echo "Pre-processing with mask generation, N4 biasfield correction, Normalisation, meanb0,400,1000,2600 generation and tensor estimation"

# point to right filebase
dwi=dwi_den_unr_eddy

# Create mask and dilate (to ensure usage with ACT)
if [ ! -f mask.mif.gz ]; then
    dwiextract -bzero $dwi.mif.gz - | mrmath -force -axis 3 - mean meanb0tmp.nii.gz
    bet meanb0tmp meanb0tmp_brain -m -f 0.25 -R #-f 0.25 from dHCP dMRI pipeline
    # Check result
    # echo mrview meanb0tmp.nii.gz -roi.load meanb0tmp_brain_mask.nii.gz -roi.opacity 0.5 -mode 2
    mrconvert meanb0tmp_brain_mask.nii.gz mask.mif.gz
    rm meanb0tmp*
fi

# Do B1-correction. Use ANTs N4
if [ ! -f  ${dwi}_N4.mif.gz ]; then
    threads=10;
    if [ ! -d N4 ]; then mkdir N4;fi
    dwibiascorrect ants -mask mask.mif.gz -bias N4/bias.mif.gz $dwi.mif.gz ${dwi}_N4.mif.gz
fi


# last file in the processing
dwipreproclast=${dwi}_N4.mif.gz

cd $currdir


##################################################################################
## 3. B0-normalise, create meanb0 and do tensor estimation

cd $datadir/dwi

# Create symbolic link to last file in /preproc and copy mask.mif.gz to $datadir/dwi
mrconvert preproc/$dwipreproclast dwi_preproc.mif.gz
mrconvert preproc/mask.mif.gz mask.mif.gz
dwi=dwi_preproc

# B0-normalisation
if [ ! -f ${dwi}_inorm.mif.gz ];then
    dwinormalise individual $dwi.mif.gz mask.mif.gz ${dwi}_inorm.mif.gz
fi

# Extract mean b0, b1000 and b2600
for bvalue in 0 400 1000 2600; do
    bfile=meanb$bvalue

    if [ $bvalue == 0 ]; then
	if [ ! -f $bfile.mif.gz]; then
	    dwiextract -shells $bvalue ${dwi}_inorm.mif.gz - |  mrmath -force -axis 3 - mean $bfile.mif.gz
	fi
    fi
    
    if [ ! -f ${bfile}_brain.mif.gz ]; then
	dwiextract -shells $bvalue ${dwi}_inorm.mif.gz - |  mrmath -force -axis 3 - mean - | mrcalc - mask.mif.gz -mul ${bfile}_brain.mif.gz
	#mrconvert $bfile.mif.gz $bfile.nii.gz
	#mrconvert ${bfile}_brain.mif.gz ${bfile}_brain.nii.gz
	echo "Visually check the ${bfile}_brain.mif.gz"
	echo mrview ${bfile}_brain.mif.gz -mode 2
    fi
done

# Calculate diffusion tensor and tensor metrics

if [ ! -f dt.mif.gz ]; then
    dwi2tensor -mask mask.mif.gz ${dwi}_inorm.mif.gz dt.mif.gz
    tensor2metric -force -fa fa.mif.gz -adc adc.mif.gz -rd rd.mif.gz -ad ad.mif.gz -vector ev.mif.gz dt.mif.gz
fi

cd $currdir