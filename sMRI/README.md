# Processing of sMRI files

This folder harbours scripts for processing sMRI files

## 1. Preprocessing
Run script `preprocess.sh`
- do motion-correction (not yet implemented)
- make high-resolution versions of T2w MCRIB
- create relevant brain masks for neonatal-segmentation

## 2. Neonatal segmentation
Run script `neonatal-segmentation.sh` (for MIRTK DrawEM) och `dhcp_structural_pipeline.sh` (for dHCP structural pipeline)

This runs DrawEM algorithm on anatomical T2w data (shou.

NOTE: 
- Faulty results are achieved for 3D-T2w (SPACE), so the algorithm is run on upsampled/highres cor/tra T2w. 
Preferably tra T2w since has more homogenous signal => better cortical segmentation
- The current parameters from DrawEM in dhcp performs better than DrawEM1p3. To run dhcp's neonatal-segmentation, run script neonatal-segmentation_dhcp-structural-pipeline_only.sh

## 3. Neonatal-5TT
Run script neonatal-5TT_DrawEM/MCRIB.sh

### 5TT_DrawEM
Converts a DrawEM segmentation into a 5TT file/s

### 5TT_neonatal-5TT
This runs an adapted version of Manuel Bleza's procedure [neonatal-5TT](https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT) to achieve MRtrix 5TT image
