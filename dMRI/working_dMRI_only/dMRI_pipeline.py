import subprocess
import sys
import shutil
import os

def usage():
    # function definition
    pass  # replace with your usage message

if len(sys.argv) < 3:
    usage()
    sys.exit(1)

command = sys.argv[1:]
sID = sys.argv[1]
ssID = sys.argv[2]

print("Command: " + str(command) + ", Subject: " + str(sID)+ ", Subject: " + str(ssID))


currdir = subprocess.check_output(['pwd']).decode('utf-8').strip()
print("Currrent directory: " + str(currdir) )

# Defaults
dwi = f'rawdata/sub-{sID}/ses-{ssID}/dwi/sub-{sID}_ses-{ssID}_dir-AP_run-1_dwi.nii.gz'
dwiPA = f'rawdata/sub-{sID}/ses-{ssID}/fmap/sub-{sID}_ses-{ssID}_acq-dwi_dir-PA_run-1_epi.nii.gz'
dwiAPsbref = f'rawdata/sub-{sID}/ses-{ssID}/dwi/sub-{sID}_ses-{ssID}_dir-AP_run-1_sbref.nii.gz'
dwiPAsbref = f'rawdata/sub-{sID}/ses-{ssID}/dwi/sub-{sID}_ses-{ssID}_dir-PA_run-1_sbref.nii.gz'
seAP = f'rawdata/sub-{sID}/ses-{ssID}/fmap/sub-{sID}_ses-{ssID}_acq-se_dir-AP_run-1_epi.nii.gz'
sePA = f'rawdata/sub-{sID}/ses-{ssID}/fmap/sub-{sID}_ses-{ssID}_acq-se_dir-PA_run-1_epi.nii.gz'
datadir = f'derivatives/dMRI_python/sub-{sID}/ses-{ssID}'
sessionfile = f'rawdata/sub-{sID}/ses-{ssID}/session_QC.tsv'

# check whether the different tools are set and load parameters
codedir = subprocess.check_output(['dirname', sys.argv[0]]).decode('utf-8').strip()
print("Code directory: " + str(codedir) )


args = sys.argv[3:]
while args:
    print(args)
    if args[0] == '-s' or args[0] == '-session-file':
        sessionfile = args[1]
        args = args[2:]
    elif args[0] == '-dwi':
        dwi = args[1]
        args = args[2:]
    elif args[0] == '-dwiAPsbref':
        dwiAPsbref = args[1]
        args = args[2:]
    elif args[0] == '-dwiPA':
        dwiPA = args[1]
        args = args[2:]
    elif args[0] == '-dwiPAsbref':
        dwiPAsbref = args[1]
        args = args[2:]
    elif args[0] == '-seAP':
        seAP = args[1]
        args = args[2:]
    elif args[0] == '-sePA':
        sePA = args[1]
        args = args[2:]
    elif args[0] == '-d' or args[0] == '-data-dir':
        datadir = args[1]
        args = args[2:]
    elif args[0] == '-h' or args[0] == '-help' or args[0] == '--help':
        usage()
        sys.exit(0)
    elif args[0].startswith('-'):
        print(f"{sys.argv[0]}: Unrecognized option {args[0]}", file=sys.stderr)
        usage()
        sys.exit(1)
    else:
        break

if not os.path.isfile(sessionfile):
    sessionfile = ""
if not os.path.isfile(dwi):
    dwi = ""
if not os.path.isfile(dwiAPsbref):
    dwiAPsbref = ""
if not os.path.isfile(dwiPA):
    dwiPA = ""
if not os.path.isfile(dwiPAsbref):
    dwiPAsbref = ""
if not os.path.isfile(seAP):
    seAP = ""
if not os.path.isfile(sePA):
    sePA = ""

for file in [sessionfile, dwi, dwiAPsbref, dwiPA, dwiPAsbref, seAP, sePA]:
    print(file)


if  sessionfile == "" :
    print(f"Preparing for dMRI pipeline\nSubject:\t\t{sID}\nSession:\t\t{ssID}\nDWI (AP):\t\t{dwi}\nDWI (AP_SBRef):\t{dwiAPsbref}\nDWI (PA):\t\t{dwiPA}\nDWI (PA_SBRef):\t{dwiPAsbref}\nSE fMAP (AP):\t{seAP}\nSE fMAP (PA):\t{sePA}\nDirectory:\t\t{datadir}\n$BASH_SOURCE\t$command\n----------------------------")
else:
    print(f"Preparing for dMRI pipeline\nSubject:\t\t{sID}\nSession:\t\t{ssID}\nSession file:\t{sessionfile}\nData directory:\t{datadir}\n$BASH_SOURCE\t$command\n----------------------------")


logdir = f"{datadir}/logs"
if not os.path.exists(datadir):
    os.makedirs(datadir)
if not os.path.exists(logdir):
    os.makedirs(logdir)


print(f"dMRI preprocessing on subject {sID} and session {ssID}")
script = os.path.basename(__file__).split(".")[0]
with open(f"{logdir}/sub-{sID}_ses-{ssID}_dMRI_{script}.log", "w") as f:
    f.write(f"Executing: {codedir}/{script}.sh {command}\n")
    f.write("\n")
    f.write(f"Printout {script}.sh\n")
    with open(f"{codedir}/{script}.py", "r") as script_file:
        f.write(script_file.read())
    f.write("\n")

##################################################################################
# 0a. Create subfolders in $datadir

os.chdir(datadir)

if not os.path.exists('anat/orig'):
    os.makedirs('anat/orig')
if not os.path.exists('dwi/orig'):
    os.makedirs('dwi/orig')
if not os.path.exists('fmap/orig'):
    os.makedirs('fmap/orig')
if not os.path.exists('xfm'):
    os.makedirs('xfm')
if not os.path.exists('qc'):
    os.makedirs('qc')

os.chdir(currdir)

#################################################################################
# 0. Copy to files to $datadir (incl .json and bvecs/bvals files if present at original location)


if os.path.isfile(sessionfile):
    # Use files listed in "session.tsv" file, which refer to file on session level in BIDS rawdata directory
    rawdatadir = f"rawdata/sub-{sID}/ses-{ssID}"
    # Read $sessionfile, copy files and meanwhile create a local session_QC.tsv in $datadir
    print(f"Transfer data in {sessionfile} which has qc_pass_fail = 1 or 0.5")
    with open(sessionfile, 'r') as f:
        linecounter = 1
        for line in f:
            line = line.strip()
            if linecounter == 1 and not os.path.isfile(f"{datadir}/session_QC.tsv"):
                with open(f"{datadir}/session_QC.tsv", 'w') as qc_file:
                    qc_file.write(line)
            # check if the file/image has passed QC (qc_pass_fail = fourth column) (1 or 0.5)
            QCPass = line.split()[3]
            if QCPass == "1" or QCPass == "0.5":
                file = line.split()[2]
                filebase = os.path.basename(file).split(".")[0]
                filedir = os.path.dirname(file)
                if filedir == "anat":
                    if not os.path.isfile(f"{datadir}/anat/orig/{filebase}.nii.gz"):
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.nii.gz",  f"{datadir}/anat/orig/")
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.json", f"{datadir}/anat/orig/")
                        with open(f"{datadir}/session_QC.tsv", 'a') as qc_file:
                            qc_file.write(f"{line.replace(filedir + '/', f'{filedir}/orig/').strip()}\n")
                elif filedir == "dwi":
                    if not os.path.isfile(f"{datadir}/dwi/orig/{filebase}.nii.gz"):
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.nii.gz", f"{datadir}/dwi/orig/")
                        for suff in [ ".json", ".bval", ".bvec"]:
                            print("{rawdatadir}/{filedir}/{filebase}"+ suff)
                            if os.path.isfile(f"{rawdatadir}/{filedir}/{filebase}"+ suff):
                                print("copy")
                                shutil.copy(f"{rawdatadir}/{filedir}/{filebase}" + suff, f"{datadir}/dwi/orig/")
                        """shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.json", f"{datadir}/dwi/orig/")
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.bval", f"{datadir}/dwi/orig/")
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.bvec", f"{datadir}/dwi/orig/")"""
                        with open(f"{datadir}/session_QC.tsv", 'a') as qc_file:
                            qc_file.write(f"{line.replace(filedir + '/', f'{filedir}/orig/').strip()}\n")
                elif filedir == "fmap":
                    if not os.path.isfile(f"{datadir}/anat/fmap/{filebase}.nii.gz"):
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.nii.gz", f"{datadir}/fmap/orig/")
                        shutil.copy(f"{rawdatadir}/{filedir}/{filebase}.json", f"{datadir}/fmap/orig/")
                        with open(f"{datadir}/session_QC.tsv", 'a') as qc_file:
                            qc_file.write(f"{line.replace(filedir + '/', f'{filedir}/orig/').strip()}\n")
            linecounter += 1
else:
    # no session_QC.tsv file, so use files from input
    filelist = [dwi, dwiAPsbref, dwiPA, dwiPAsbref, seAP, sePA]
    for file in filelist:
        filebase = os.path.basename(file)[:-7] # remove the ".nii.gz" extension
        filedir = os.path.dirname(file)
        if file == dwi:
            shutil.copy(file, f"{datadir}/dwi/orig/")
            shutil.copy(f"{filedir}/{filebase}.json", f"{datadir}/dwi/orig/")
            shutil.copy(f"{filedir}/{filebase}.bval", f"{datadir}/dwi/orig/")
            shutil.copy(f"{filedir}/{filebase}.bvec", f"{datadir}/dwi/orig/")
        else: # should be put in /fmap
            shutil.copy(file,  f"{datadir}/fmap/orig/")
            shutil.copy(f"{filedir}/{filebase}.json", f"{datadir}/fmap/orig/")


############################PREPROCESS##################################



if not os.path.isfile(sessionfile):
    dwi = f"derivatives/dMRI/sub-{sID}/ses-{ssID}/dwi/orig/sub-{sID}_ses-{ssID}_dir-AP_run-1_dwi.nii.gz"


# 0. Copy to files to $datadir (incl .json and bvecs/bvals files if present at original location)
inputfilesdir = os.path.dirname(sessionfile)

if not os.path.isdir(os.path.join(datadir, 'topup')):
    os.makedirs(os.path.join(datadir, 'topup'))

if os.path.isfile(sessionfile):
    with open(sessionfile, 'r') as f:
        f.readline()  # skip header
        for line in f:
            QCPass = line.split()[3]

            if QCPass == '1':
                file = line.split()[2]
                filebase = os.path.splitext(os.path.basename(file))[0]
                filedir = os.path.dirname(file)

                dwiAP = line.split()[5]
                if dwiAP == '1':
                    if not os.path.isfile(os.path.join(datadir, 'dwiAP.mif.gz')):
                        cmd = ['mrconvert', '-json_import', os.path.join(inputfilesdir, filedir, filebase + '.json'),
                               '-fslgrad', os.path.join(inputfilesdir, filedir, filebase + '.bvec'),
                               os.path.join(inputfilesdir, filedir, filebase + '.nii.gz'),
                               os.path.join(datadir, 'dwiAP.mif.gz')]
                        subprocess.run(cmd)

                volb0AP = line.split()[6]
                if volb0AP != '-':
                    b0APvol = volb0AP
                    if not os.path.isfile(os.path.join(datadir, 'b0AP.mif.gz')):
                        cmd1 = ['mrconvert', os.path.join(inputfilesdir, filedir, filebase + '.nii.gz'),
                                '-json_import', os.path.join(inputfilesdir, filedir, filebase + '.json'), '-']
                        cmd2 = ['mrconvert', '-coord', '3', b0APvol, '-axes', '0,1,2', '-', os.path.join(datadir, 'topup', 'b0AP.mif.gz')]
                        p1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE)
                        p2 = subprocess.Popen(cmd2, stdin=p1.stdout)
                        p1.stdout.close()
                        p2.communicate()

                volb0PA = line.split()[7]
                if volb0PA != '-':
                    if not os.path.isfile(os.path.join(datadir, 'b0PA.mif.gz')):
                        cmd = ['mrconvert', os.path.join(inputfilesdir, filedir, filebase + '.nii.gz'),
                               '-json_import', os.path.join(inputfilesdir, filedir, filebase + '.json'),
                               os.path.join(datadir, 'topup', 'b0PA.mif.gz')]
                        subprocess.run(cmd)
else:
    print('No session.tsv file, using input/defaults')
    filedir = os.path.dirname(dwi)
    filebase = os.path.splitext(os.path.basename(dwi))[0]
    cmd = ['mrconvert', os.path.join(filedir, filebase + '.nii.gz'),
           '-json_import', os.path.join(filedir, filebase + '.json'),
           '-fslgrad', os.path.join(filedir, filebase + '.bvec'),
           os.path.join(datadir, 'dwi.mif.gz')]
    subprocess.run(cmd)

