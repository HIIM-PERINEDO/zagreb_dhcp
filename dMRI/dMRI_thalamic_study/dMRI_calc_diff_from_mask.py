{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "!ls\n",
    "\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "import subprocess\n",
    "import pandas as pd\n",
    "\n",
    "# Initialize paths to parameter files and mask files\n",
    "parameter_files = ['path/to/param1.mif.gz', 'path/to/param2.mif.gz']  # Update with actual paths\n",
    "mask_files = ['path/to/mask1.nii.gz', 'path/to/mask2.nii.gz']  # Update with actual paths\n",
    "\n",
    "# Function to convert .mif.gz files to .nii.gz using mrconvert command\n",
    "def convert_mif_to_nii(mif_file):\n",
    "    nii_file = mif_file.replace('.mif.gz', '.nii.gz')\n",
    "    subprocess.run(['mrconvert', mif_file, nii_file], check=True)\n",
    "    return nii_file\n",
    "\n",
    "# Function to calculate statistics using fslstats\n",
    "def calculate_stats(nii_file, mask_file):\n",
    "    result = subprocess.run(['fslstats', nii_file, '-k', mask_file, '-M'], capture_output=True, text=True)\n",
    "    return float(result.stdout.strip())\n",
    "\n",
    "# DataFrame to store the results\n",
    "df = pd.DataFrame(index=[os.path.basename(mask) for mask in mask_files], \n",
    "                  columns=[os.path.basename(param) for param in parameter_files])\n",
    "\n",
    "# Processing each combination of parameter file and mask file\n",
    "for param_file in parameter_files:\n",
    "    nii_file = convert_mif_to_nii(param_file)\n",
    "    for mask_file in mask_files:\n",
    "        mask_name = os.path.basename(mask_file)\n",
    "        param_name = os.path.basename(param_file)\n",
    "        df.at[mask_name, param_name] = calculate_stats(nii_file, mask_file)\n",
    "\n",
    "print(df)\n"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.8.10"
  },
  "orig_nbformat": 4
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
