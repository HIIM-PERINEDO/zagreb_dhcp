## PREPROCESS DATA, including:
#   1. conversion to BIDS
#   2. validation of BIDS dataset
#
# Currently needs to be run from main data-folder 
# Input
# $1 = subject_id (e.g. PK343)
# $2 = session_id (MR1)

# Exit upon any error
set -exo pipefail

## To CODE_DIR as global variable
source code/setup.sh

###   Global variables:   ###

# Study/subject specific #
codeFolder=$CODE_DIR;
studyFolder=`dirname -- "$codeFolder"`;

sourcedataFolder=$studyFolder/sourcedata;
dcmFolder=$studyFolder/sourcedataDcm;

subjectID=$1
sessionID=$2 
logFolder=${studyFolder}/derivatives/preprocessing_logs/sub-${subjectID}/ses-${sessionID}

if [ ! -d $sourcedataFolder ]; then mkdir -p $sourcedataFolder; fi
# We place a .bidsignore here
if [ ! -f $sourcedataFolder/.bidsignore ]; then
echo -e "# Exclude following from BIDS-validator\n" > $sourcedataFolder/.bidsignore;
fi

# Log folder
if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

# we'll be running the Docker containers as yourself, not as root:
userID=$(id -u):$(id -g)

###   Get docker images:   ###
docker pull nipy/heudiconv:latest
docker pull bids/validator:latest

###   Extract DICOMs into BIDS:   ###
# The images were extracted and organized in BIDS format:

docker run --name heudiconv_container \
           --user $userID \
           --rm \
           -it \
           --volume $studyFolder:/base \
           --volume $dcmFolder:/dataIn:ro \
           --volume $sourcedataFolder:/dataOut \
           nipy/heudiconv \
               -d /dataIn/sub-{subject}/ses-{session}/*/*.dcm \
               -f /base/code/zagreb_heuristic.py \
               -s ${subjectID} \
               -ss ${sessionID} \
               -c dcm2niix \
               -b \
               -o /dataOut \
               --overwrite \
           > ${logFolder}/sub-${subjectID}_ses-${sessionID}_dcm2sourcedata.log 2>&1 
           
# heudiconv makes files read only
#    We need some files to be writable, eg for dHCP pipelines
chmod -R u+wr,g+wr $sourcedataFolder


# We run the BIDS-validator:
docker run --name BIDSvalidation_container \
           --user $userID \
           --rm \
           --volume $sourcedataFolder:/data:ro \
           bids/validator \
               /data \
           > ${studyFolder}/derivatives/bids-validator_report.txt 2>&1
           #> ${logFolder}/bids-validator_report.txt 2>&1                   
           # For BIDS compliance, we want the validator report to go to the top level of derivatives. But for debugging, we want all logs from a given script to go to a script-specific folder
           