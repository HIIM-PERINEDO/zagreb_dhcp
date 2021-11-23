sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_5TT.nii.gz

Work with SPC/Edinburgh data

sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz

#Create mask
bet sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_brain.nii.gz -m -R

# Do N4
mirtk convert-image sub-PMR001_ses-MR2_acq-SPC_run-1_T2w.nii.gz sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_rescaled.nii.gz -rescale 0 1000 -double
mirtk N4 3 -i sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_rescaled.nii.gz -x sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_brain_mask.nii.gz -o [sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_restore.nii.gz,sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_bias.nii.gz] -c [50x50x50,0.001] -s 2 -b [100,3] -t [0.15,0.01,200]

# Perform 5ttgen neonatal
5ttgen neonatal -nocleanup -mask sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_brain_mask.nii.gz -parallel 2 -cores 10 -mcrib_path /home/finn/Research/Atlases/M-CRIB/M-CRIB_for_MRtrix_5ttgen_neonatal -sgm_amyg_hipp -hard_segmentation ../5TT_5ttgen-neonatal-M-CRIB/sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_Labels.nii.gz sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_restore.nii.gz ../5TT_5ttgen-neonatal-M-CRIB/sub-PMR001_ses-MR2_acq-SPC_run-1_T2w_5TT.nii.gz

# Transform into dwi-space
