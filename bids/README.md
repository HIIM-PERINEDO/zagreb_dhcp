This folder contains scripts that uses [heudiconv](https://heudiconv.readthedocs.io/en/latest/) to convert DICOMs into [BIDS-format](https://bids-specification.readthedocs.io/en/stable/)

- DICOMs are expected to be in `$studyfolder/sourcedata`
- Heuristics-files are located in code-subfolder `$codefolder/bids/heudiconv_heuristics`
- NIfTIs are written into a BIDS-organised folder `$studyfolder/rawdata`

BIDS format: https://bids-specification.readthedocs.io/en/stable/

Heudiconv: https://heudiconv.readthedocs.io/en/latest/

## Scanning protocol 
1. Head Scout
2. Localizer
3. t1_mprage_sag_iso
4. t2_space_sag_iso_edinburgh
5. t2_qtse_cor
6. t2_tse_tra_1mm_MCRIB_p2
7. t2_space_dark-fluid_sag_iso
8. SWI
9. SpinEchoFieldMap_AP
10. SpinEchoFieldMap_PA
11. rfMRI_REST_PA
12. rfMRI_REST_AP
13. dMRI_dir106_PA_2x2x2
14. dMRI_dir106_AP_2x2x2
15. dMRI_dir106_PA_2x2x2
16. t2_tse_tra

## DICOM outputs
Typical output of series (now re-runs)
s01_AAHead_Scout_64ch-head-coil
s02_AAHead_Scout_64ch-head-coil_MPR_sag
s03_AAHead_Scout_64ch-head-coil_MPR_cor
s04_AAHead_Scout_64ch-head-coil_MPR_tra
s05_localizer
s06_t1_mprage_sag_iso
s07_t2_space_sag_iso_edinburgh
s08_t2_qtse_cor
s09_t2_tse_tra_1mm_MCRIB_p2
s10_t2_space_dark-fluid_sag_iso
s11_Mag_Images
s12_Pha_Images
s13_mIP_Images(SW)
s14_SWI_Images
s15_SpinEchoFieldMap_AP
s16_SpinEchoFieldMap_PA
s17_rfMRI_REST_PA_SBRef
s18_rfMRI_REST_PA
s19_rfMRI_REST_AP_SBRef
s20_rfMRI_REST_AP
s21_dMRI_dir106_PA_2x2x2_SBRef
s22_dMRI_dir106_PA_2x2x2
s23_dMRI_dir106_AP_2x2x2_SBRef
s24_dMRI_dir106_AP_2x2x2
s25_dMRI_dir106_AP_2x2x2_ADC
s26_dMRI_dir106_AP_2x2x2_FA
s27_dMRI_dir106_AP_2x2x2_ColFA
s29_dMRI_dir106_PA_2x2x2_SBRef
s30_dMRI_dir106_PA_2x2x2
s31_t2_tse_tra
s32_ep2d_diff_4scan_trace_p2_TRACEW
s33_ep2d_diff_4scan_trace_p2_ADC

## BIDS conversion and BIDS data organisation
All sequences will have running number (run-0X) to handle re-runs or multiple runs.
NOTE - dir-PA_dwi will be put in `/fmap` but dir-PA_SBRef will not and instead into `/dwi`

### Anatomy goes in `/anat`
t1_mprage_sag_iso		->	anat/sub-PMR001_ses-MR2_acq-MPRAGE_run-1_T1w.nii.gz
t2_space_sag_iso_edinburgh	->	anat/sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz
t2_qtse_cor			->	anat/sub-PMR001_ses-MR2_acq-cor_run-1_T2w.nii.gz
t2_tse_tra_1mm_MCRIB_p2		->	anat/sub-PMR001_ses-MR2_acq-MCRIB_run-1_T2w.nii.gz
t2_space_dark-fluid_sag_iso	->	anat/sub-PMR001_ses-MR2_run-1_FLAIR.nii.gz

### Fieldmaps goes in `/fmap`
SpinEchoFieldMap_AP		->	fmap/sub-PMR001_ses-MR2_acq-se_dir-AP_run-1_epi.nii.gz
SpinEchoFieldMap_PA		->	fmap/sub-PMR001_ses-MR2_acq-se_dir-PA_run-1_epi.nii.gz
dMRI_dir106_PA_2x2x2 (1st run)	->	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-1_epi.nii.gz
dMRI_dir106_PA_2x2x2 (2nd run)	->	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-2_epi.nii.gz

### Functionals (rs-fMRI) goes into `/func`
rfMRI_REST_PA_SBRef		->	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_sbref.nii.gz
rfMRI_REST_PA			->	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_bold.nii.gz
rfMRI_REST_AP_SBRef		->	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_sbref.nii.gz
rfMRI_REST_AP			->	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_bold.nii.gz

### Diffusion goes into `/dwi`
dMRI_dir106_PA_2x2x2_SBRef(1st)	->	dwi/sub-PMR001_ses-MR2_dir-PA_run-1_sbref.nii.gz
dMRI_dir106_AP_2x2x2_SBRef	->	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_sbref.nii.gz
dMRI_dir106_AP_2x2x2		->	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_dwi.nii.gz
dMRI_dir106_PA_2x2x2_SBRef(2nd)	->	dwi/sub-PMR001_ses-MR2_dir-PA_run-2_sbref.nii.gz

