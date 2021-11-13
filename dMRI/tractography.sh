#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Performs whole-brain tractography and SIFT-filtering

Arguments:
  sID				Subject ID (e.g. PK356) 
  ssID                       	Session ID (e.g. MR1)
Options:
  -csd				CSD mif.gz-file (default: derivatives/dMRI/sub-sID/ses-ssID/csd/csd_msmt_5tt_wm.mif.gz)
  -5TT				5TT mif.gz-file in dMRI space (default: derivatives/dMRI/sub-sID/ses-ssID/act/5TT.mif.gz)
  -nbr				Number of streamlines in whole-brain tractogram (default: 10M)
  -threads			Number of threads for parallell processing (default: 10)
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
datadir=derivatives/dMRI/sub-$sID/ses-$ssID

method=neonatal-5TT
atlas=M-CRIB
actdir=act_neonatal-5TT-M-CRIB
csddir=csd/$actdir
tractdir=tractography/$actdir

csd=derivatives/dMRI/sub-$sID/ses-$ssID/$csddir/csd_msmt_5tt_wm.mif.gz
act5tt=derivatives/dMRI/sub-$sID/ses-$ssID/$actdir/5TT_coreg.mif.gz

nbr=10M
threads=10

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
	-csd) shift; csd=$1; ;;
	-5TT) shift; act5tt=$1; ;;
	-nbr) shift; nbr=$1; ;;
	-threads) shift; threads=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Whole-brain ACT tractography
Subject:       $sID 
Session:       $ssID
CSD:	       $csd
5TT:           $act5tt
Nbr:	       $nbr
Threads:       $threads
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo


##################################################################################
# 0. Copy to files to datadir (incl .json if present at original location)

for file in $csd $act5tt; do
    origdir=`dirname $file`
    filebase=`basename $file .mif.gz`
    
    if [[ $file = $csd ]];then outdir=$datadir/$csddir;fi
    if [[ $file = $act5tt ]];then outdir=$datadir/$actdir;fi
    if [ ! -d $outdir ]; then mkdir -p $outdir; fi
    
    if [ ! -f $outdir/$filebase.mif.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# Update variables to point at corresponding filebases in $datadir
csd=`basename $csd .mif.gz`
act5tt=`basename $act5tt .mif.gz`

##################################################################################
# 1. Perform whole-brain tractography

cd $datadir

if [ ! -d $tractdir ]; then mkdir -p $tractdir; fi

# If a gmwmi mask does not exist, then create one
if [ ! -f $actdir/${act5tt}_gmwmi.mif.gz ];then
    5tt2gmwmi $actdir/$act5tt.mif.gz $actdir/${act5tt}_gmwmi.mif.gz
fi

# Whole-brain tractography
cutoff=0.05; # This is the value that is used in Blesa et al, Cerebral Cortex 2021. Default is 0.1
init=$cutoff; # default is equal to cutoff
cutofftext=`echo $cutoff | sed 's/\./p/g'`
inittext=$cutofftext;
# using above cutoff and init
if [ ! -f $tractdir/whole_brain_${nbr}.tck ];then
    tckgen -nthreads $threads -cutoff $cutoff -seed_cutoff $init -act $actdir/$act5tt.mif.gz -backtrack -seed_gmwmi $actdir/${act5tt}_gmwmi.mif.gz -crop_at_gmwmi -select $nbr $csddir/$csd.mif.gz $tractdir/whole_brain_${nbr}.tck
fi
if [ ! -f $tractdir/whole_brain_${nbr}_edit100k.tck ];then
    tckedit $tractdir/whole_brain_${nbr}.tck -number 100k $tractdir/whole_brain_${nbr}_edit100k.tck
fi

# SIFT-filtering of whole-brain tractogram
if [ ! -f $tractdir/whole_brain_${nbr}_sift.tck ]; then
    count=`tckinfo $tractdir/whole_brain_$nbr.tck | grep \ count: | awk '{print $2}'`;
    count0p10=`echo "$count / 10" | bc`;
    tcksift -act $actdir/$act5tt.mif.gz -term_number $count0p10 $tractdir/whole_brain_$nbr.tck $csddir/$csd.mif.gz $tractdir/whole_brain_${nbr}_sift.tck
fi
if [ ! -f $tractdir/whole_brain_${nbr}_sift_edit100k.tck ];then
    tckedit $tractdir/whole_brain_${nbr}_sift.tck -number 100k $tractdir/whole_brain_${nbr}_sift_edit100k.tck
fi

cd $currdir
