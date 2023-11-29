
#!/bin/bash

# Base directories
INPUT_DIR="derivatives/dMRI"
OUTPUT_DIR="derivatives/dMRI_thalamic_study"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

#response functions are in: 

# 5. Compute response functions
# located in derivatives/dMRI/sub-$sID/ses-$ssID/dwi/preproc/dwi_preproc_inorm.mif.gz

# 6. Calculate the mean response function across all subjects
responsemean $INPUT_DIR/sub-*/ses-MR2/dwi/response/*_wm.txt $OUTPUT_DIR/group_average_response_wm.txt
responsemean $INPUT_DIR/sub-*/ses-MR2/dwi/response/*_gm.txt $OUTPUT_DIR/group_average_response_gm.txt
responsemean $INPUT_DIR/sub-*/ses-MR2/dwi/response/*_csf.txt $OUTPUT_DIR/group_average_response_csf.txt

# 7. Resample the DWI data to a common voxel size - NOT NEEDED

# 8. Generate a brain mask
#located in derivatives/dMRI/sub-$sID/ses-$ssID/dwi/preproc/mask.mif.gz

#9. Compute FODs
for sID in `ls $INPUT_DIR`; do  #"$INPUT_DIR"/* 
    echo $sID
    if [ -d "$INPUT_DIR/$sID" ]; then
        #origdir=`dirname $file`
        #filebase=`basename $file .mif.gz`
        ssID=MR2
        mkdir -p "$OUTPUT_DIR/$sID/ses-$ssID"
        dwi2fod msmt_csd $INPUT_DIR/$sID/ses-$ssID/dwi/preproc/dwi_preproc_inorm.mif.gz $OUTPUT_DIR/group_average_response_wm.txt $OUTPUT_DIR/$sID/ses-$ssID/wmfod_group.mif $OUTPUT_DIR/group_average_response_gm.txt $OUTPUT_DIR/$sID/ses-$ssID/gmfod_group.mif  $OUTPUT_DIR/group_average_response_csf.txt $OUTPUT_DIR/$sID/ses-$ssID/csffod_group.mif -mask $INPUT_DIR/$sID/ses-$ssID/dwi/preproc/mask.mif.gz
    fi
done

# 10. Normalize the FOD images
for sID in `ls $INPUT_DIR`; do  #"$INPUT_DIR"/* 
    echo $sID
    if [ -d "$INPUT_DIR/$sID" ]; then
        #origdir=`dirname $file`
        #filebase=`basename $file .mif.gz`
        ssID=MR2
        mkdir -p "$OUTPUT_DIR/$sID/ses-$ssID"
        mtnormalise $OUTPUT_DIR/$sID/ses-$ssID/wmfod_group.mif $OUTPUT_DIR/$sID/ses-$ssID/wmfod_group_norm.mif $OUTPUT_DIR/$sID/ses-$ssID/gmfod_group.mif $OUTPUT_DIR/$sID/ses-$ssID/gmfod_group_norm.mif $OUTPUT_DIR/$sID/ses-$ssID/csffod_group.mif $OUTPUT_DIR/$sID/ses-$ssID/csffod_group_norm.mif -mask $INPUT_DIR/$sID/ses-$ssID/dwi/preproc/mask.mif.gz
    fi
done

# 11. Prepare for population template generation
mkdir -p $OUTPUT_DIR/template/fod_input
mkdir $OUTPUT_DIR/template/mask_input

# 12. Create symbolic links for FOD images and masks
for sID in `ls $INPUT_DIR`; do  #"$INPUT_DIR"/* 
    echo $sID
    if [ -d "$INPUT_DIR/$sID" ]; then
        ln -sr $OUTPUT_DIR/$sID/ses-$ssID/wmfod_group_norm.mif $OUTPUT_DIR/template/fod_input/${sID}_${ssID}_wmfod_group_norm.mif.gz
        ln -sr $INPUT_DIR/$sID/ses-$ssID/dwi/preproc/mask.mif.gz $OUTPUT_DIR/template/mask_input/${sID}_${ssID}_mask.mif.gz
    fi
done

# 14. Generate a FOD-based population template
population_template $OUTPUT_DIR/template/fod_input -mask_dir $OUTPUT_DIR/template/mask_input $OUTPUT_DIR/template/wmfod_template.mif 




if false; then


# 1. Denoise the DWI data
#for_each $INPUT_DIR/sub-*/ses-MR2 : dwidenoise IN/dwi.mif $OUTPUT_DIR/IN/dwi_denoised.mif

# 2. Remove Gibbs ringing artifacts
#for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrdegibbs IN/dwi_denoised.mif IN/dwi_denoised_unringed.mif -axes 0,1

# 3. Pre-process DWI data with FSL eddy
#for_each $OUTPUT_DIR/sub-*/ses-MR2 : dwifslpreproc IN/dwi_denoised_unringed.mif IN/dwi_denoised_unringed_preproc.mif -rpe_none -pe_dir AP

# 4. Bias field correction
#for_each $OUTPUT_DIR/sub-*/ses-MR2 : dwibiascorrect ants IN/dwi_denoised_unringed_preproc.mif IN/dwi_denoised_unringed_preproc_unbiased.mif

# 5. Compute response functions
#for_each $OUTPUT_DIR/sub-*/ses-MR2 : dwi2response dhollander IN/dwi_denoised_unringed_preproc_unbiased.mif IN/response_wm.txt IN/response_gm.txt IN/response_csf.txt

# 6. Calculate the mean response function across all subjects
responsemean $OUTPUT_DIR/sub-*/ses-MR2/response_wm.txt $OUTPUT_DIR/group_average_response_wm.txt
responsemean $OUTPUT_DIR/sub-*/ses-MR2/response_gm.txt $OUTPUT_DIR/group_average_response_gm.txt
responsemean $OUTPUT_DIR/sub-*/ses-MR2/response_csf.txt $OUTPUT_DIR/group_average_response_csf.txt

# 7. Resample the DWI data to a common voxel size
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrgrid IN/dwi_denoised_unringed_preproc_unbiased.mif regrid -vox 1.25 IN/dwi_denoised_unringed_preproc_unbiased_upsampled.mif

# 8. Generate a brain mask
for_each $OUTPUT_DIR/sub-*/ses-MR2 : dwi2mask IN/dwi_denoised_unringed_preproc_unbiased_upsampled.mif IN/dwi_mask_upsampled.mif

# 9. Compute FODs
for_each $OUTPUT_DIR/sub-*/ses-MR2 : dwi2fod msmt_csd IN/dwi_denoised_unringed_preproc_unbiased_upsampled.mif $OUTPUT_DIR/group_average_response_wm.txt IN/wmfod.mif $OUTPUT_DIR/group_average_response_gm.txt IN/gm.mif  $OUTPUT_DIR/group_average_response_csf.txt IN/csf.mif -mask IN/dwi_mask_upsampled.mif


# 10. Normalize the FOD images
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mtnormalise IN/wmfod_norm.mif IN/wmfod_norm.mif IN/gm_norm.mif IN/gm_norm.mif IN/csf_norm.mif IN/csf_norm.mif -mask IN/dwi_mask_upsampled.mif

# 11. Prepare for population template generation
mkdir -p $OUTPUT_DIR/template/fod_input
mkdir $OUTPUT_DIR/template/mask_input

# 12. Create symbolic links for FOD images and masks
for_each $OUTPUT_DIR/sub-*/ses-MR2 : ln -sr IN/wmfod_norm.mif $OUTPUT_DIR/template/fod_input/PRE.mif
for_each $OUTPUT_DIR/sub-*/ses-MR2 : ln -sr IN/dwi_mask_upsampled.mif $OUTPUT_DIR/template/mask_input/PRE.mif

# Skipping step 13 as it requires random selection

# 14. Generate a FOD-based population template
population_template $OUTPUT_DIR/template/fod_input -mask_dir $OUTPUT_DIR/template/mask_input $OUTPUT_DIR/template/wmfod_template.mif -voxel_size 1.25

# 15. Register individual subject FOD images to the population template
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrregister IN/wmfod_norm.mif -mask1 IN/dwi_mask_upsampled.mif $OUTPUT_DIR/template/wmfod_template.mif -nl_warp IN/subject2template_warp.mif IN/template2subject_warp.mif

# 16. Transform individual brain masks to template space
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrtransform IN/dwi_mask_upsampled.mif -warp IN/subject2template_warp.mif -interp nearest -datatype bit IN/dwi_mask_in_template_space.mif

# 17. Create a template mask
mrmath $OUTPUT_DIR/sub-*/ses-MR2/dwi_mask_in_template_space.mif min $OUTPUT_DIR/template/template_mask.mif -datatype bit

# 18. Convert FOD images to fixel format within the template mask
for_each $OUTPUT_DIR/sub-*/ses-MR2 : fod2fixel -mask $OUTPUT_DIR/template/template_mask.mif $OUTPUT_DIR/template/wmfod_template.mif $OUTPUT_DIR/template/fixel_mask -fmls_peak_value 0.06

# 19. Register individual FOD images to the population template without reorienting the FODs
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrtransform IN/wmfod_norm.mif -warp IN/subject2template_warp.mif -reorient_fod no IN/fod_in_template_space_NOT_REORIENTED.mif

# 20. Convert individual non-reoriented FODs to fixel format
for_each $OUTPUT_DIR/sub-*/ses-MR2 : fod2fixel -mask $OUTPUT_DIR/template/template_mask.mif IN/fod_in_template_space_NOT_REORIENTED.mif IN/fixel_in_template_space_NOT_REORIENTED -afd fd.mif

# 21. Reorient fixels to align with the population template fixel directions
for_each $OUTPUT_DIR/sub-*/ses-MR2 : fixelreorient IN/fixel_in_template_space_NOT_REORIENTED IN/subject2template_warp.mif IN/fixel_in_template_space

# 22. Compute a corresponding fixel-based measure of fiber density (FD) for each subject in template space
for_each $OUTPUT_DIR/sub-*/ses-MR2 : fixelcorrespondence IN/fixel_in_template_space/fd.mif $OUTPUT_DIR/template/fixel_mask $OUTPUT_DIR/template/fd PRE.mif

# 23. Generate a fiber cross-section (FC) metric in template space for each subject
for_each $OUTPUT_DIR/sub-*/ses-MR2 : warp2metric IN/subject2template_warp.mif -fc $OUTPUT_DIR/template/fixel_mask $OUTPUT_DIR/template/fc IN.mif

# 24. Log-transform the FC metric
mkdir $OUTPUT_DIR/template/log_fc
cp $OUTPUT_DIR/template/fc/index.mif $OUTPUT_DIR/template/fc/directions.mif $OUTPUT_DIR/template/log_fc
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrcalc $OUTPUT_DIR/template/fc/IN.mif -log $OUTPUT_DIR/template/log_fc/IN.mif

# 25. Compute a fiber density and cross-section (FDC) metric in template space for each subject
mkdir $OUTPUT_DIR/template/fdc
cp $OUTPUT_DIR/template/fc/index.mif $OUTPUT_DIR/template/fdc
cp $OUTPUT_DIR/template/fc/directions.mif $OUTPUT_DIR/template/fdc
for_each $OUTPUT_DIR/sub-*/ses-MR2 : mrcalc $OUTPUT_DIR/template/fd/IN.mif $OUTPUT_DIR/template/fc/IN.mif -mult $OUTPUT_DIR/template/fdc/IN.mif

# 26. Generate whole-brain streamlines using probabilistic tractography
cd $OUTPUT_DIR/template
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.mif -seed_image template_mask.mif -mask template_mask.mif -select 20000000 -cutoff 0.06 tracks_20_million.tck

# 27. SIFT (Spherical-deconvolution Informed Filtering of Tractograms) the tractogram to 2 million streamlines
tcksift tracks_20_million.tck wmfod_template.mif tracks_2_million_sift.tck -term_number 2000000

# 28. Compute fixel-fixel connectivity
fixelconnectivity fixel_mask/ tracks_2_million_sift.tck matrix/

# 29. Smooth the fixel data
fixelfilter fd smooth fd_smooth -matrix matrix/
fixelfilter log_fc smooth log_fc_smooth -matrix matrix/
fixelfilter fdc smooth fdc_smooth -matrix matrix/

# 30. Perform fixel-based statistical analysis for FD, log-transformed FC, and FDC
fixelcfestats fd_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_fd/
fixelcfestats log_fc_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_log_fc/
fixelcfestats fdc_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_fdc/

fi