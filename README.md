# zagreb_dhcp
These are dHCP inspired processing pipelines for neonatal MRI 
 
This is the repository can go inside the /code folder within of a BIDS studyfolder

The data is organized in the same way as the 2nd data release for the dHCP (https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view) and expects the nifti sourcedata files to be located in the BIDS folder /sourcedata (SIC!). Processed data/Processing pipelines store results in /derivatives

The processing pipelines and processing scripts are located 
## Data organisation /bids
To organise the data in BIDS datastructure format
## Structural pipeline in /sMRI
dhcp-structural-pipeline: https://github.com/BioMedIA/dhcp-structural-pipeline
## Diffusion pipeline in /dMRI
dhcp-diffusion-pipeline: https://git.fmrib.ox.ac.uk/matteob/dHCP_neo_dMRI_pipeline_release
## Resting-state fMRI pipeline in /rsfMRI
dhcp-fmri-pipeline: https://git.fmrib.ox.ac.uk/seanf/dhcp-neonatal-fmri-pipeline


