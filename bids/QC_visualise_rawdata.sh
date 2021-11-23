#!/bin/bash
# Zagrep Collab dhcp
# Script for QC eye-balling of rawdata images by input from a BIDS session.tsv file
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Visualize NIfTIs in BIDS rawdata folder 
Arguments:
  sID				Subject ID (e.g. PMR002) 
  ssID                       	Session ID (e.g. MR2)
Options:
  -f / -tsv_file		Session.tsv file containing Heuristic file to use with heudiconv (default: $studydir/rawdata/sub-\$sID/ses-\$ssID/sub-\$sID/ses-\$ssID_scans.tsv)
  -h / -help / --help           Print usage.
"
  exit;
}

dMRI_rawdata_visualisation ()
{
    # get input file
    file=$1;
    echo $file

    filebase=`basename $file .nii.gz`
    filedir=`dirname $file`

    # check if SBRef file
    issbref=`echo $file | grep sbref`

    # if sbref file, then just visualise this
    if [[ $issbref ]]; then
	mrview $file -mode 2 
    else #is dwi file
	# Launch viewer and load all images
	mrconvert -quiet -fslgrad $filedir/$filebase.bvec $filedir/$filebase.bval $file tmp.mif
	shells=`mrinfo -shell_bvalues tmp.mif`;
	for shell in $shells; do
	    echo Inspecting shell with b-value=$shell
	    dwiextract -quiet -shell $shell tmp.mif - | mrview - -mode 2 
	done
	rm tmp.mif
    fi
}

################ ARGUMENTS ################

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
ssID=$2
shift; shift

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studydir=$PWD 
rawdatadir=$studydir/rawdata
tsvfile=$rawdatadir/sub-$sID/ses-$ssID/sub-${sID}_ses-${ssID}_scans.tsv

# Read arguments
while [ $# -gt 0 ]; do
    case "$1" in
	-f|-tsv_file)  shift; tsvfile=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Go to rawdata dir
cd $rawdatadir/sub-$sID/ses-$ssID

echo "QC eye-balling of BIDS rawdata given by $tsvfile"

# Read input file line by line, but skip first line
{
    read;
    while IFS= read -r line
    do
	file=`echo "$line" | awk '{ print $1 }'`
	filedir=`dirname $file`
	
	if [ $filedir == "dwi" ]; then
	    dMRI_rawdata_visualisation $file;
	else
	    echo $file
	    mrview $file -mode 2 
	fi
        
    done
} < "$tsvfile"

cd $studydir
