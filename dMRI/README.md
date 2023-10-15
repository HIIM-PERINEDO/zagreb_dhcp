## Data organisation

Data is organised with inspiration/accordning to FSL eddy pipeline in the [3rd dHCP data release](https://biomedia.github.io/dHCP-release-notes/structure.html#diffusion-eddy-pipeline).

E.g. in the case of session MR2 of PMR001 
```
derivatives/dMRI 
	└── sub-PMR001 
    	    └── ses-MR2 
            	├── anat
					└── orig
        		├── dwi 
					└── orig
        		├── fmap
					└── orig 
        		├── qc 
				├── session_QC.tsv 
        		└── xfm 
```

## Processing

Essentially follows the [BATMAN tutorial](https://osf.io/pm9ba/)

Run scripts in the following order:

0. prepare_dmri_pipeline.sh -> Copies relevant files to a like above described directory structure
1. preprocess.sh
2. response.sh
3. csd.sh
4. neonatal-5TT (neonatal-5TT_DrawEM or neonatal-5TT_MCRIB)
5. registration.sh
6. tractography.sh
7. connectome.sh

The resulting directory structure after processing is like:
```
derivatives/dMRI 
	└── sub-PMR001 
    	    └── ses-MR2 
            	├── anat 
					└── orig
        		├── dwi 
					├── orig
					├── preproc
					├── response
					├── csd
					├── 5TT
					├── registration
					├── tractography
					├── connectome
        		├── fmap 
					└── orig
        		├── qc 
				├── session_QC.tsv 
        		└── xfm 
```
