import os
import subprocess
import pandas as pd
import sys

# Initialize paths to parameter files and mask files

sID = "PMR001"
ssID = "MR2"

# Check if the number of input arguments (excluding the script name) is equal to 2
if len(sys.argv) != 3:
    print("Usage: python script_name.py arg1 arg2")
    print("Description: This script requires exactly two arguments. arg1 and arg2 are used for...")
    sys.exit(1)
else:
    # Assign arguments to variables
    sID = sys.argv[1]
    ssID = sys.argv[2]

    print("Argument 1:", sID)
    print("Argument 2:", ssID)

    # Your script logic goes here


def find_files_with_string(relative_directory, match_string):
    """
    Returns a list of all files containing the specified match_string within the specified directory, 
    which is given as a relative path to the current working directory.

    Args:
    relative_directory (str): The relative path to the directory to search in.
    match_string (str): The string to match in the filenames.

    Returns:
    list: A list of file paths that contain the match_string.
    """
    # Get the absolute path of the relative directory
    base_directory = os.getcwd()
    absolute_directory = os.path.join(base_directory, relative_directory)

    matching_files = []
    for root, dirs, files in os.walk(absolute_directory):
        for file in files:
            if match_string in file:
                matching_files.append(os.path.join(base_directory, relative_directory, file))
    return matching_files

# Function to convert .mif.gz files to .nii.gz using mrconvert command
def convert_mif_to_nii(mif_file):
    """
    Converts a .mif or .mif.gz file to a .nii file using mrconvert.

    Args:
    mif_file (str): The path to the .mif or .mif.gz file.

    Returns:
    str: The path to the converted .nii file.
    """
    base, ext = os.path.splitext(mif_file)

    # Check if file has .gz extension
    if ext == '.gz':
        base, _ = os.path.splitext(base)  # Remove the .mif extension
        nii_file = base + '.nii'
    else:
        nii_file = base + '.nii'

    subprocess.run(['mrconvert', mif_file, nii_file, '-force'], check=True)
    return nii_file

# Function to calculate statistics using fslstats
def calculate_stats(nii_file, mask_file):
    result = subprocess.run(['fslstats', nii_file, '-k', mask_file, '-M'], 
                            capture_output=True, text=True)
    print(result)
    print(result.stdout.strip())
    # Check if the command was successful
    if result.returncode != 0:
        print(f"Error in running fslstats: {result.stderr}")
        return None

    # Ensure that the output is not empty
    if not result.stdout.strip():
        print(f"No output received from fslstats for files {nii_file} and {mask_file}")
        return None

    try:
        return float(result.stdout.strip())
    except ValueError as e:
        print(f"Could not convert output to float: {result.stdout.strip()}")
        return None



FILE_PATH_TEMPLATE_1 =  os.path.join( os.getcwd(), "derivatives/dMRI/sub-{}/ses-{}/dwi/preproc/{}.mif.gz" )
parameters = [ 'adc',  "ad" , "dt", "ev" , "fa", "rd" ]
parameter_files = []  # Update with actual paths
for p in parameters:
    parameter_files.append( FILE_PATH_TEMPLATE_1.format(sID, ssID, p) )

FILE_PATH_TEMPLATE_NODDI =  os.path.join( os.getcwd(), "derivatives/dMRI/sub-{}/ses-{}/dwi/noddi/AMICO/NODDI/{}.nii.gz" )
parameters_noddi = [ 'fit_dir',  "fit_FWF" , "fit_NDI", "fit_ODI" ]
for p in parameters_noddi:
    parameter_files.append( FILE_PATH_TEMPLATE_NODDI.format(sID, ssID, p) )

print(parameter_files)

FILE_PATH_TEMPLATE_2 =  "derivatives/dMRI/sub-{}/ses-{}/dwi/tractography_roi/tractography/neonatal-5TT-M-CRIB"
mask_dir= FILE_PATH_TEMPLATE_2.format(sID, ssID)

mask_files = find_files_with_string(mask_dir, "mask")
print(mask_files)

# DataFrame to store the results
df = pd.DataFrame(index=[os.path.basename(mask) for mask in mask_files], 
                  columns=[os.path.basename(param) for param in parameter_files])

# Processing each combination of parameter file and mask file
for param_file in parameter_files:
    nii_file = convert_mif_to_nii(param_file)
    for mask_file in mask_files:
        nii_file_mask = convert_mif_to_nii(mask_file)
        mask_name = os.path.basename(mask_file)
        param_name = os.path.basename(param_file)
        print(param_name)
        df.at[mask_name, param_name] = calculate_stats(nii_file, nii_file_mask)
        #os.remove(nii_file_mask)
    #os.remove(nii_file)

print(df)

FILE_PATH_TEMPLATE_SAVE_DIR =  os.path.join( os.getcwd(), "derivatives/dMRI/sub-{}/ses-{}/dwi/results" )
file_path_save_dir = FILE_PATH_TEMPLATE_SAVE_DIR.format(sID, ssID)

FILE_PATH_TEMPLATE_SAVE_NAME =  "sub-{}_ses-{}_calc_dwi_params_from_mask.csv"
file_path_save_name = FILE_PATH_TEMPLATE_SAVE_NAME.format(sID, ssID)

file_path_save_full = os.path.join(file_path_save_dir, file_path_save_name)

# Create the directory if it does not exist
os.makedirs(file_path_save_dir, exist_ok=True)

# Save the DataFrame to a CSV file
df.to_csv(file_path_save_full, index=False)  # Set index=False if you don't want to include the index in the CSV