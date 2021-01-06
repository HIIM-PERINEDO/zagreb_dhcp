# Processing of sMRI files

This folder harbours scripts for processing sMRI files

## 1. Preprocessing
Run script process.sh

- Upsamples inplane 2D anatomicals (tra T2w and cor T2w)
- Registers anatomicals (FLAIR, cor highres T2w and tra highres T2w) to 3D-T2w
- Transforms FLAIR into T2w-space (3D-T2w) and creates adapted brain mask from transformed FLAIR

## 2. Neonatal segmentation
Run script neonatal-segmentation.sh

This runs DrawEM algorithm on anatomical T2w data.

NOTE: 
- Faulty results are achieved for 3D-T2w (SPACE), so the algorithm is run on upsampled/highres cor/tra T2w. 
Preferably tra T2w since has more homogenous signal => better cortical segmentation
- The current parameters from DrawEM in dhcp performs better than DrawEM1p3, and should ideally be used (currently NOT implemented)

## 3. Neonatal-5TT
Run 

Runs an adapted version of Manuel Bleza's [neonatal-5TT(https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT) to achieve MRtrix 5TT image
