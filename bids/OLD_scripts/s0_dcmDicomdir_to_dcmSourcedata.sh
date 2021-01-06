## Zagreb Collab study

## PREPROCESS DATA, including:
#   1. arrangement of DICOMs into organised forlders in /sourcedata folder
#
# Currently needs to be run from main data_BIDS-folder 
# Input
# $1 = subject_id (e.g. PK343)
# $2 = session_id (e.g. MR1)

# Exit upon any error
set -exo pipefail

## To make CODE_DIR as global variable - NOT WORKING??
#source code/setup.sh
# instead use trick from code/setup.sh
# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
CODE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Study/subject specific #
codeFolder=$CODE_DIR;
studyFolder=`dirname -- "$codeFolder"`; #or "studyFolder"/rawdata?
origdcmFolder=$studyFolder/dicomdir;
dcmFolder=$studyFolder/sourcedataDcm
niftiFolder=$studyFolder/sourcedataNifti

subjectID=$1
sessionID=$2 
logFolder=${studyFolder}/derivatives/preprocessing_logs/sub-${subjectID}/ses-${sessionID}

if [ ! -d $logFolder ]; then 
mkdir -p $logFolder; fi

# we'll be running the Docker containers as yourself, not as root:
userID=$(id -u):$(id -g)

# Re-arrange DICOMs into $dcmFolder
if [ ! -d $dcmFolder ]; then mkdir $dcmFolder; fi
dcm2niix -b o -r y -o $dcmFolder -w 1 -f sub-$subjectID/ses-${sessionID}/s%2s_%d/%d_%5r.dcm $origdcmFolder/${subjectID}_${sessionID}

# Also create a $niftiFolder where all the DICOMs are plainly converted into NIfTIs
# Good to keep for future 
if [ ! -d $niftiFolder ]; then mkdir $niftiFolder; fi
dcm2niix -b y -ba y -z y -w 1 -o $niftiFolder -f sub-$subjectID/ses-${sessionID}/s%2s_%d $origdcmFolder/${subjectID}_${sessionID}

# Simple log
echo "Executing $0 $@ "> ${logFolder}/sub-${subjectID}_ses-${sessionID}_dcm2sourcedata.log 2>&1 
cat $0 >> ${logFolder}/sub-${subjectID}_ses-${sessionID}_dcm2sourcedata.log 2>&1 
