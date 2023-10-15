import amico  #pip install dmri-amico -U
import os
import shutil
import subprocess
import numpy as np
import sys

def run_cmd(cmd):
    return subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)

# Check if the correct number of arguments is provided
if len(sys.argv) != 3:
    print("Usage: script_name.py <subject_name> <session_name>")
    sys.exit()

# Store the arguments in the desired variables
subject_name, session_name = sys.argv[1], sys.argv[2]

# Define paths
#subject_name = "PMR001"
#session_name = "MR2"
study_folder = f'derivatives/dMRI/sub-{subject_name}/ses-{session_name}/dwi/preproc'
new_folder = f'derivatives/dMRI/sub-{subject_name}/ses-{session_name}/dwi/noddi'

# Create new directory if it doesn't exist
os.makedirs(os.path.join(new_folder), exist_ok=True)

# Copy and rename files
shutil.copy2(os.path.join(study_folder, 'mask.mif.gz'),
             os.path.join(new_folder, 'DWI_mask.mif.gz'))

shutil.copy2(os.path.join(study_folder, 'dwi_den_unr_eddy.mif.gz'),
             os.path.join(new_folder, 'DWI.mif.gz'))


# Extract .nii, .bval, .bvec files using mrconvert
run_cmd(f"mrconvert -export_grad_fsl {os.path.join(new_folder, 'DWI.bvec')} {os.path.join(new_folder, 'DWI.bval')} {os.path.join(new_folder, 'DWI.mif.gz')} {os.path.join(new_folder, 'DWI.nii')}")
# Now 'DWI.nii', 'DWI.bval', 'DWI.bvec' files should be in the target directory

# Extract mask using mrconvert
run_cmd(f"mrconvert  {os.path.join(new_folder, 'DWI_mask.mif.gz')} {os.path.join(new_folder, 'DWI_mask.nii')}")
# Now 'DWI_mask.nii' should be in the target directory

# Convert FSL's bvals/bvecs to an AMICO scheme file
amico.util.fsl2scheme(os.path.join(new_folder, 'DWI.bval'),
                      os.path.join(new_folder, 'DWI.bvec'))

# Change to the new directory
#os.chdir(os.path.join(new_folder))
os.chdir(new_folder)

# 1. Setup
amico.core.setup()

# 2. Create an "study" object
ae = amico.Evaluation(".", ".")

# 3. Load the diffusion MRI data and the acquisition scheme
ae.load_data(dwi_filename="DWI.nii", scheme_filename="DWI.scheme", mask_filename="DWI_mask.nii" , b0_thr=5) # minimal b-value is 5

# 4. Load the NODDI model
amico.core.model = amico.models.NODDI()

# 5. Generate the kernels corresponding to the acquisition protocol
ae.set_model("NODDI")
ae.model.set(
    dPar=1.7e-3,
    dIso=3.0E-3,
    IC_VFs=np.linspace(0.1,0.99,12),
    IC_ODs=np.hstack((np.array([0.03, 0.06]),np.linspace(0.09,0.99,10))),
    isExvivo=False)
ae.generate_kernels(regenerate=True)
ae.load_kernels()

# 6. Fit the model
ae.fit()

# 7. Save the results to NIFTI files
ae.save_results()
