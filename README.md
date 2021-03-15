# zagreb_dhcp
These are dHCP inspired processing pipelines for neonatal MRI 
The repository can go inside the /code folder within of a [BIDS](https://bids.neuroimaging.io/) studyfolder

The data is organized in the same way as the [2nd data release](https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view) for the dHCP and expects the nifti sourcedata files to be located in the BIDS folder /sourcedata (SIC!). Processed data/Processing pipelines store results in /derivatives

The processing pipelines and processing scripts are organised as followed: 

## Data organisation /bids
To organise the data in BIDS datastructure format

## Structural pipeline in /sMRI
To process the sMRI data within the framework of the [dhcp-structural-pipeline](https://github.com/BioMedIA/dhcp-structural-pipeline)
These includes neonatal segmentation with DrawEM and surface generation and analysis. 

One purpose is to achieve tissue segmenation that can be used in the dMRI analysis (see below)

NOTE - current version of [DrawEM version 1.3](https://github.com/MIRTK/DrawEM) has incorporated optional segmentation according to the [M-CRIB_2.0 atlas](https://osf.io/4vthr/)

## Diffusion pipeline in /dMRI
To process dMRI neonatal data 

Different approaches may be taken
- 5TT framework in MRtrix and anatomical parcellations for structural dMRI connectiviy analysis
- Potentially the [dhcp-diffusion-pipeline](https://git.fmrib.ox.ac.uk/matteob/dHCP_neo_dMRI_pipeline_release)

## Resting-state fMRI pipeline in /rsfMRI
To process rs-fMRI neonatal data.

This would use the [dhcp-fmri-pipeline](https://git.fmrib.ox.ac.uk/seanf/dhcp-neonatal-fmri-pipeline)


