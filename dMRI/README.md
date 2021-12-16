### Data organisation

Data is organised with inspiration/accordning to FSL eddy pipeline in the [3rd dHCP data release](https://biomedia.github.io/dHCP-release-notes/structure.html#diffusion-eddy-pipeline).

derivatives/dMRI
	└── sub-PMR001
    	    └── ses-MR2
            	├── anat
        	├── dwi
        	├── fmap
        	├── qc
        	└── xfm


### Processing pipeline

Essentially follows the [BATMAN tutorial](https://osf.io/pm9ba/)

Run scripts in the following order:

1. preprocess.sh
2. neonatal-5TT (neonatal-5TT_DrawEM or neonatal-5TT_MCRIB)
3. registration.sh
4. response.sh
5. csd.sh
6. tractography.sh
7. connectome.sh
