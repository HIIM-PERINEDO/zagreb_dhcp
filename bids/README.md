# Re-arrangement & Conversion of DCM to NIfTI and QC of rawdata NIfTI

## 0. Re-arrangement of DCM data

1. DCM data is downloaded from the SECTRA PACS system by "Exporting to media"  \
The downloaded DMCs should be stored the in a folder in `$studyfolder/DICOM_DoB/"study_id"_"session"_DoB"YYYYMMDD"` \
E.g. `$studyfolder/DICOM_DoB/PMR000_MR2_DoB20001201`

2. The DCM images are not ordered in any eligible way, so the small script `DoBDCM_to_sourcedataDCM.sh` is run which re-names the folders and files in a more eligible way into `sourcedata`\
E.g. `$studyfolder/DICOM_DoB/PMR000_MR2_DoB20001201` => `$studyfolder/sourcedata/sub-PMR000/ses-MR2/...` 

## 1. Conversion of DCM data into BIDS NIfTI data

The conversion is done with the script `sourcedataDCM_to_rawdataBIDS.sh` which uses [heudiconv](https://heudiconv.readthedocs.io/en/latest/) to convert DICOMs into [BIDS-format](https://bids-specification.readthedocs.io/en/stable/)

- DICOMs are expected to be in `$studyfolder/sourcedata`
- Heuristics-files are located in code-subfolder `$codefolder/bids/heudiconv_heuristics`
- NIfTIs are written into a BIDS-organised folder `$studyfolder/rawdata`

# Visual inspection of rawdata image quality 

After BIDS conversion, the rawdata is visually inspected to detect bad imaging data.

## 1. Eye-balling of BIDS data 
Launch the script `QC_visualise_rawdata.sh` and eye-ball all the images in the BIDS-rawdata folder as listed in the file `rawdata/sub-sID/ses-ssID/sub-$sID_ses-$ssID_scans.tsv`.

The script creates a file `rawdata/sub-sID/ses-ssID/session_QC.tsv` which should be used for QC book keeping.

In this tab-seperated file, all NIfTI images in are judged for overall images quality given by `qc_pass_fail = 1 (pass), 0.5 (borderline/unclear), 0 (fail)`. Additional informationen for processing can be be stored, e.g. which dMRI_dwiAP sequence to use and what b0 to use for TOPUP.

One example (note that proper tab-separation exists between columns).
```
participant_id	session_id	filename	qc_pass_fail	qc_signature	dMRI_dwiAP	dMRI_vol_for_b0AP	dMRI_vol_for_b0PA	sMRI_use_for_5ttgen_mcrib
sub-PMR001	ses-MR2	anat/sub-PMR001_ses-MR2_acq-MPRAGE_run-1_T1w.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	anat/sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz	1FL	-	-	-	1
sub-PMR001	ses-MR2	anat/sub-PMR001_ses-MR2_acq-cor_run-1_T2w.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	anat/sub-PMR001_ses-MR2_acq-MCRIB_run-1_T2w.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	anat/sub-PMR001_ses-MR2_run-1_FLAIR.nii.gz	1	FL	-	-	-	-
sub-PMR001	ses-MR2	fmap/sub-PMR001_ses-MR2_acq-se_dir-AP_run-1_epi.nii.gz	0FL	-	-	-	-
sub-PMR001	ses-MR2	fmap/sub-PMR001_ses-MR2_acq-se_dir-PA_run-1_epi.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_sbref.nii.gz	1	FL	-	-	-	-
sub-PMR001	ses-MR2	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_bold.nii.gz	1	FL	-	-	-	-
sub-PMR001	ses-MR2	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_sbref.nii.gz	1	FL	-	-	-	-
sub-PMR001	ses-MR2	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_bold.nii.gz	1	FL	-	-	-	-
sub-PMR001	ses-MR2	dwi/sub-PMR001_ses-MR2_dir-PA_run-1_sbref.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-1_epi.nii.gz1FL	-	-	0	-
sub-PMR001	ses-MR2	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_sbref.nii.gz	1FL	-	-	-	-
sub-PMR001	ses-MR2	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_dwi.nii.gz	1	FL	1	0	-	-
sub-PMR001	ses-MR2	dwi/sub-PMR001_ses-MR2_dir-PA_run-2_sbref.nii.gz	0FL	-	-	-	-
sub-PMR001	ses-MR2	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-2_epi.nii.gz1FL	-	-
```
# Generation av tsv-files
particpants.tsv
session.tsv

TBC

# MRI protocol and BIDS conversion rules
## Scanning protocol 
The complete MR-protocol i stored in `$studydir/sequences` but outlined here

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
Typical output of series (not including re-runs) \
s01_AAHead_Scout_64ch-head-coil \
s02_AAHead_Scout_64ch-head-coil_MPR_sag \
s03_AAHead_Scout_64ch-head-coil_MPR_cor \
s04_AAHead_Scout_64ch-head-coil_MPR_tra \
s05_localizer \
s06_t1_mprage_sag_iso \
s07_t2_space_sag_iso_edinburgh \
s08_t2_qtse_cor \
s09_t2_tse_tra_1mm_MCRIB_p2 \
s10_t2_space_dark-fluid_sag_iso \
s11_Mag_Images \
s12_Pha_Images \
s13_mIP_Images(SW) \
s14_SWI_Images \
s15_SpinEchoFieldMap_AP \
s16_SpinEchoFieldMap_PA \
s17_rfMRI_REST_PA_SBRef \
s18_rfMRI_REST_PA \
s19_rfMRI_REST_AP_SBRef \
s20_rfMRI_REST_AP \
s21_dMRI_dir106_PA_2x2x2_SBRef \
s22_dMRI_dir106_PA_2x2x2 \
s23_dMRI_dir106_AP_2x2x2_SBRef \
s24_dMRI_dir106_AP_2x2x2  \
s25_dMRI_dir106_AP_2x2x2_ADC \
s26_dMRI_dir106_AP_2x2x2_FA \
s27_dMRI_dir106_AP_2x2x2_ColFA \
s29_dMRI_dir106_PA_2x2x2_SBRef \
s30_dMRI_dir106_PA_2x2x2 \
s31_t2_tse_tra \
s32_ep2d_diff_4scan_trace_p2_TRACEW \
s33_ep2d_diff_4scan_trace_p2_ADC

## BIDS conversion and BIDS data organisation
The BIDS conversion and BIDS organization is dictated by rules set up in the heuristic file.

All sequences will have running number (run-X) to handle re-runs or multiple runs.

NOTE - dir-PA_dwi will be put in `/fmap` whereas dir-PA_SBRef is put in `/dwi`

### Anatomy goes in `/anat`
t1_mprage_sag_iso		->	anat/sub-PMR001_ses-MR2_acq-MPRAGE_run-1_T1w.nii.gz \
t2_space_sag_iso_edinburgh	->	anat/sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz \
t2_qtse_cor			->	anat/sub-PMR001_ses-MR2_acq-cor_run-1_T2w.nii.gz \
t2_tse_tra_1mm_MCRIB_p2		->	anat/sub-PMR001_ses-MR2_acq-MCRIB_run-1_T2w.nii.gz \
t2_space_dark-fluid_sag_iso	->	anat/sub-PMR001_ses-MR2_run-1_FLAIR.nii.gz

### Fieldmaps goes in `/fmap`
SpinEchoFieldMap_AP		->	fmap/sub-PMR001_ses-MR2_acq-se_dir-AP_run-1_epi.nii.gz \
SpinEchoFieldMap_PA		->	fmap/sub-PMR001_ses-MR2_acq-se_dir-PA_run-1_epi.nii.gz  \
dMRI_dir106_PA_2x2x2 (1st run)	->	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-1_epi.nii.gz \
dMRI_dir106_PA_2x2x2 (2nd run)	->	fmap/sub-PMR001_ses-MR2_acq-dwi_dir-PA_run-2_epi.nii.gz 

### Functionals (rs-fMRI) goes into `/func`
rfMRI_REST_PA_SBRef		->	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_sbref.nii.gz \
rfMRI_REST_PA			->	func/sub-PMR001_ses-MR2_task-rest_dir-PA_run-1_bold.nii.gz \
rfMRI_REST_AP_SBRef		->	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_sbref.nii.gz \
rfMRI_REST_AP			->	func/sub-PMR001_ses-MR2_task-rest_dir-AP_run-1_bold.nii.gz 

### Diffusion goes into `/dwi`
dMRI_dir106_PA_2x2x2_SBRef(1st)	->	dwi/sub-PMR001_ses-MR2_dir-PA_run-1_sbref.nii.gz \
dMRI_dir106_AP_2x2x2_SBRef	->	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_sbref.nii.gz \
dMRI_dir106_AP_2x2x2		->	dwi/sub-PMR001_ses-MR2_dir-AP_run-1_dwi.nii.gz \
dMRI_dir106_PA_2x2x2_SBRef(2nd)	->	dwi/sub-PMR001_ses-MR2_dir-PA_run-2_sbref.nii.gz 

