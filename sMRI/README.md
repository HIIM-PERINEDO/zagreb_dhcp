# Processing of sMRI files

This folder harbours scripts for processing sMRI files

## 1. Preprocessing
Run script `preprocess.sh`
- do motion-correction (not yet implemented)
- make high-resolution versions of T2w MCRIB
- create relevant brain masks for neonatal-segmentation

## 2. Neonatal segmentation
Run script `neonatal-segmentation.sh` (for MIRTK DrawEM) or `dhcp_structural_pipeline.sh` (for dHCP structural pipeline)
This runs DrawEM algorithm on anatomical highres MCRIB T2w data.

NOTE: 
- The current parameters from DrawEM in dhcp performs better than DrawEM1p3. 
- To run dhcp's neonatal-segmentation, run script neonatal-segmentation_dhcp-structural-pipeline_only.sh

## 3. Neonatal-5TT
Run script `neonatal-5TT_DrawEM.sh`or `neonatal-5TT_MCRIB.sh`.
This creates 5TT maps to use for ACT tractography.

### 5TT_DrawEM
The script/routine `neonatal-5TT_DrawEM.sh` converts a DrawEM segmentation into a 5TT file/s

### 5TT_neonatal-5TT
The script/routine `neonatal-5TT_MCRIB.sh` runs an adapted version of Manuel Bleza's procedure [neonatal-5TT](https://git.ecdf.ed.ac.uk/jbrl/neonatal-5TT) to achieve a MRtrix 5TT image and M-CRIB parcellation using a co-registration routine (ANTs JointLabelFusion) and the M-CRIB atlas.

NOTE: 
- The implementation requires that the M-CRIB atlas has been run through DrawEM. This has been done in relevant subfolderns in "`/$atlasdir/M-CRIB`". 
- A modified version (using MRtrix routine `5ttgen neonatal`) is being tested
