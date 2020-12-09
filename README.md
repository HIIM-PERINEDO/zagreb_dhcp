# zagreb_dhcp
These are dHCP inspired processing pipelines for neonatal MRI 
The repository can go inside the /code folder within of a BIDS studyfolder

The data is organized in the same way as the 2nd data release for the dHCP (https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view) and expects the nifti sourcedata files to be located in the BIDS folder /sourcedata (SIC!). Processed data/Processing pipelines store results in /derivatives

The processing pipelines and processing scripts are organised as followed: 

## Data organisation /bids
To organise the data in BIDS datastructure format

## Structural pipeline in /sMRI
To process the sMRI data with the main purpose to achieve tissue segmenation for the 5TT framework in MRtrix and anatomical parcellations for structural dMRI connectiviy analysis. 

Data is processed with the DrawEM algorithm: https://github.com/MIRTK/DrawEM

dhcp-structural-pipeline: https://github.com/BioMedIA/dhcp-structural-pipeline

## Diffusion pipeline in /dMRI
To process dMRI neonatal data within the 5TT framework.

dhcp-diffusion-pipeline: https://git.fmrib.ox.ac.uk/matteob/dHCP_neo_dMRI_pipeline_release

## Resting-state fMRI pipeline in /rsfMRI
To process rs-fMRI neonatal data.

dhcp-fmri-pipeline: https://git.fmrib.ox.ac.uk/seanf/dhcp-neonatal-fmri-pipeline


