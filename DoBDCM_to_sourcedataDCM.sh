#!/bin/bash
# Zagreb_Collab
#
# Simple script to put patient DCMs in DoB-folder into sourcedata by using dcm2niix.
# Data is copied and with file and folder names rearranged and renamed
#
# Input:
# $1 = sourcedata-folder (e.g. sourcedata) 
# $2 = DoB-folder (e.g. DICOM_DoB)
# $3 = Patient (assumed to be in the in the format PMR$SubjectID_$SessionID_DoBYYYYMMDD or PK$SubjectID_$SessionID_DoBYYYYMMDD)
# (optional) $4 = SubjectID (i.e. number PMRXYZ, e.g. PMR343)
# (optional) $5 = SessionID (e.g. MR2)
#
# Output:
# Patient DCM-folder in PMR-folder organized in BIDS
# sourcedata-folder
#  |
#  -- subj-$SubjectID
#      |
#      -- ses-$SessionID
#          |
#          --DCM-folders for each Series
#

# START

#Input/s
PMRfolder=$1;
DoBfolder=$2;
Patient=$3
if [ $# -gt 3 ]; then
    SubjectID=$4;
    SessionID=$5;
else
    SubjectID=`echo "$Patient" | sed 's/\_/\ /g' | awk '{print $1}'`;
    SessionID=`echo "$Patient" | sed 's/\_/\ /g' | awk '{print $2}'`;
fi
echo
echo Transferring $Patient from DoB-folder $DoBfolder to PMR-folder $PMRfolder;
echo SubjectID = $SubjectID
echo SessionID = $SessionID;

# Re-arrange DCM into PMR-folder in a BIDS-like structure using dcm2niix
if [ -d $PMRfolder/sub-$SubjectID/ses-$SessionID ]; then
    echo "Folder $PMRfolder/sub-$SubjectID/ses-$SessionID already exists => NO transfer"
    echo
else
    echo "Transfer DCMs into $PMRfolder/sub-$SubjectID/ses-$SessionID"
    echo
    dcm2niix -b o -r y -w 1 -v 1 -o $PMRfolder -f sub-$SubjectID/ses-$SessionID/s%2s_%d/%d_%5r.dcm $DoBfolder/$Patient
fi