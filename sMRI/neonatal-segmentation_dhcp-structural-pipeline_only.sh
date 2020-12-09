#!/bin/bash
#
# Script to run the dHCP segmentation pipepline only
# (i.e. the scripts/segmentation/pipeline.sh) 
#


# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
CODE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Study/subject specific
codeFolder=$CODE_DIR;
studyFolder=`dirname -- "$codeFolder"`;
rawdataFolder=$studyFolder/rawdata

# Input text-file
sID=$1
ssID=$2
age=$3

# Threads
if [ $# -gt 3 ]; then
threads=$4;
else
threads=10
fi

# Location of input files for T2s
inputFolder=$rawdataFolder/sub-$sID/ses-$ssID/anat  
outputFolder=$studyFolder/derivatives/dhcp_segmentation-pipeline/sub-$sID/ses-$ssID
logFolder=$outputFolder/logs
if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

# T2 input file, which is put in outputFolder
T2input=sub-${sID}_ses-${ssID}_run-001_T2w # might change to skip the run- index
T2=sub-${sID}_ses-${ssID}_T2w

if [ ! -f $outputFolder/$T2.nii.gz ]; then
    imcp $inputFolder/$T2input $outputFolder/$T2
fi

echo Running the dHCP segmentation pipeline
echo Processing $sID and session $ssID with age $age using $threads threads
script=`basename $0`
echo Executing: $script $@ > ${logFolder}/sub-${sID}_ses-${ssID}_$script.log 2>&1
echo

#docker run --rm -t -u $(id -u):$(id -g) -v $PWD:/data --entrypoint /bin/bash biomedia/dhcp-structural-pipeline:latest -c ". /etc/fsl/fsl.sh && /usr/src/structural-pipeline/scripts/segmentation/pipeline.sh 3dt2_bias_in_meanb0.nii.gz pk323-mri 40 -t 1"

docker run --rm -t -u $(id -u):$(id -g) \
-v $outputFolder:/data --entrypoint /bin/bash biomedia/dhcp-structural-pipeline:latest \
-c ". /etc/fsl/fsl.sh && /usr/src/structural-pipeline/scripts/segmentation/pipeline.sh $T2.nii.gz sub-${sID}_ses-${ssID} $age -t $threads" > ${logFolder}/sub-${sID}_ses-${ssID}_dhcp_segmentation-pipeline.log 2>&1

