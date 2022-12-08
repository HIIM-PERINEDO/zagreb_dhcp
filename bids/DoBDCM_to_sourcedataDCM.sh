#!/bin/bash
# Zagreb_Collab
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base patient [options]
Simple script to put patient DCMs in DoB-folder into sourcedata folder using dcm2niix.
sourcedata-folder
 |
 -- subj-$SubjectID
     |
     -- ses-$SessionID
         |
         --DCM-folders for each Series
Data is copied and with file and folder names rearranged and renamed.

Arguments:
  patient			Patient's DoBDCM-folder in format PMR/PK$SubjectID_$SessionID_DoBYYYYMMDD (e.g. PMR002_MR2_YYYYMMDD or PK340_MR2_YYYYMMDD) 
Options:
  -sourcedata			Output sourcedata folder (default: sourcedata)
  -DoBDCM		       	Input DCM-folder (default: DICOM_DoB)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
Patient=$1
shift

if [ $# -gt 3 ]; then
    SubjectID=$4;
    SessionID=$5;
else
    SubjectID=`echo "$Patient" | sed 's/\_/\ /g' | awk '{print $1}'`;
    SessionID=`echo "$Patient" | sed 's/\_/\ /g' | awk '{print $2}'`;
fi

# Defaults
studydir=$PWD
PMRfolder=$studydir/sourcedata;
DoBfolder=$studydir/DICOM_DoB;

# Read arguments
while [ $# -gt 0 ]; do
    case "$1" in
	-sourcedata)  shift; PMRfolder=$1; ;;
	-DoBDCM) shift; DoBfolder=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

################ START ################

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
