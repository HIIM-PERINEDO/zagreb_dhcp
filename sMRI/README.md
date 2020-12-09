# Processing of sMRI files

This folder harbours scripts for processing sMRI files

## 1. Preprocessing
Run script process.sh

- Upsamples inplane 2D anatomicals (tra T2w and cor T2w)
- Registers anatomicals (FLAIR, cor highres T2w and tra highres T2w) to 3D-T2w
- Create adapted brain mask in 3D-T2w space (space-T2w) from transformed FLAIR

## 2. Neonatal segmentation
Runs DrawEM algorithm on anatomical T2w data.

Faulty results are achieved for 3D-T2w, so the algorithm is run on upsampled/highres cor/tra T2w.
Preferably tra T2w since has more homogenous signal => better cortical segmentation

## 3. Neonatal-5TT
Runs an adapted version of Manuel Bleza's 5TT-script to achieve MRtrix 5TT image

neonatal-5TT: https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT
