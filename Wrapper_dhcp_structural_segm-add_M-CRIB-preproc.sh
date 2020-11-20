#!/bin/bash
# Wrapper to perform dhcp's neonatal-segmentation on M-CRIB subjects
#
# Input
# $1 - file with SubjectID age on lines; e.g. /M-CRIB_sample_basic_info/M-CRIB_atlas_demographic_info_simple.txt
# $2 (optional) - number of threads (default threads = 10)
#

# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
codeFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studyFolder=`dirname -- "$codeFolder"`;

# Input text-file
input=$1
# Input number of threads
if [ $# -gt 1 ]; then
    threads=$2;
else
    threads=10;
fi

while IFS= read -r line
do

    # Find subject and age
    subjectID=`echo "$line" | awk '{print $1}'`
    sessionID=1
    age=`echo "$line" | awk '{print $2}'`
    echo "Processing $subjectID with age $age using $threads threads and the dhcp_structural_segm-add"

    outputFolder=$studyFolder/derivatives/dhcp_structural_pipeline_segm-add_M-CRIB-preproc/$subjectID
    logFolder=$outputFolder/logs
    if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

    # Put the dHCP stuff in the path
    dhcpFolder=$HOME/Software/dhcp-structural-pipeline

    # Location of input files for M-CRIBs  
    T2=$studyFolder/M-CRIB_T2-weighted_images/M-CRIB_preprocessed_T2/M-CRIB_${subjectID}_T2
    T1=$studyFolder/M-CRIB_T1-weighted_images/M-CRIB_preprocessed_T1/M-CRIB_${subjectID}_T1

    # Run the actual pipeline
    bash $dhcpFolder/dhcp-pipeline_segm-add.sh $subjectID $sessionID $age \
	 -T2 $T2.nii.gz \
	 -T1 $T1.nii.gz \
	 -additional \
	 -d $outputFolder \
	 -t $threads \

done < "$input"

