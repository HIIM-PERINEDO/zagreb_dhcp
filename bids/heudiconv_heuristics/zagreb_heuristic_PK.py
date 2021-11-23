# Heuristics file 
# Author: Finn Lennartsson 
# Date: 2021-05-05
# For PK study

import os


def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

def find_PE_direction_from_protocol_name(prot_name, default_dir_name='normal'):
    # valid phase-encoding directions in the protocol name
    PE_directions = ['AP','PA','RL','LR','rev']
    direction = default_dir_name
    for peDir in PE_directions:
        if (
            '_'+peDir in prot_name
            or '-'+peDir in prot_name
        ):
            direction = peDir
            break

    return direction


def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    # ANATOMY
    t1wmprage = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-MPRAGE_run-{item:01d}_T1w')
    t2w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-MCRIB_run-{item:01d}_T2w')
    t2wspc = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-SPC_run-{item:01d}_T2w')
    t2wcorclin = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-cor_run-{item:01d}_T2w')
    t2wtraclin = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-tra_run-{item:01d}_T2w')
    flair = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:01d}_FLAIR')
    
    # DWI
    dwi_ap = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_dir-AP_run-{item:01d}_dwi')
    
    # fMRI
    rest_ap = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_dir-AP_run-{item:01d}_bold')
    rest_pa = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_dir-PA_run-{item:01d}_bold')
    
    # FMAPs
    fmap_se_ap = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-se_dir-AP_run-{item:01d}_epi')
    fmap_se_pa = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-se_dir-PA_run-{item:01d}_epi')
    # FL - Problem with dwi_pa as this contains only 1 b0 => no bvecs/bvals are created which makes it a non-valid _dwi 
    # This is only a problem when the sole volume in dir-AP_sbref is corrupted and fmap_se cannot be used for some reason, and another b0 in MB-collected dir-AP_dwi might have to be used for TOPUP/EDDY. This would have to be combined with MB-collected dir-PA_dwi
    # so we put in the fmaps    
    fmap_dwi_pa = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-dwi_dir-PA_run-{item:01d}_epi')
    
    # SBRefs
    dwi_ap_sbref = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_dir-AP_run-{item:01d}_sbref')
    dwi_pa_sbref = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_dir-PA_run-{item:01d}_sbref')
    rest_ap_sbref = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_dir-AP_run-{item:01d}_sbref')
    rest_pa_sbref = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_dir-PA_run-{item:01d}_sbref')

    info = {t1wmprage: [], t2w: [], t2wspc: [], t2wcorclin: [], t2wtraclin: [], flair: [], dwi_ap: [], fmap_dwi_pa: [], rest_ap: [], rest_pa: [], fmap_se_ap: [], fmap_se_pa: [], dwi_ap_sbref: [], dwi_pa_sbref: [], rest_ap_sbref: [], rest_pa_sbref: []}
    #info = {t1wmprage: [], t2w: [], dwi: [], dwi_sbref: [], rest: [], rest_sbref: [], fmap_se}
    last_run = len(seqinfo)

    for idx, s in enumerate(seqinfo):
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """
        # ANATOMY
        # 3D T1w
        if ('t1_mprage_sag' in s.protocol_name) and ('NORM' in s.image_type): # takes normalized images:
            info[t1wmprage] = [s.series_id] # assign if a single series meets criteria   
        # 3D T2w
        if ('T2w_SPC' in s.protocol_name) and ('NORM' in s.image_type): # takes normalized images
            info[t2wspc] = [s.series_id] # assign if a single series meets criteria
        # T2w Ax
        if ('t2_qtse_tra' in s.protocol_name): 
            info[t2wtraclin] = [s.series_id] # assign if a single series meets
        # T2w Cor
        if ('t2_qtse_cor' in s.protocol_name): 
            info[t2wcorclin] = [s.series_id] # assign if a single series meets criteria
        # FLAIR
        if ('t2_space_dark-fluid_sag' in s.protocol_name) and ('NORM' in s.image_type): # takes normalized images
            info[flair] = [s.series_id] # assign if a single series meets criteria
        
        # DIFFUSION
        # dir AP
        if (s.dim4 == 107) and ('dMRI_dir106_AP_2x2x2' in s.series_description) and ('ORIGINAL' in s.image_type):
            info[dwi_ap].append(s.series_id) # append if multiple series meet criteria
            
            
        # rs-fMRI
        # dir AP
        if (s.dim4 == 550 ) and ('rfMRI_REST_AP' in s.series_description) and ('ORIGINAL' in s.image_type):
            info[rest_ap].append(s.series_id) # append if multiple series meet criteria
        # dir PA
        if (s.dim4 == 10 ) and ('rfMRI_REST_PA' in s.series_description) and ('ORIGINAL' in s.image_type):
            info[rest_pa].append(s.series_id) # append if multiple series meet criteria

        # FMAPs
        # SE dir-AP
        if ('SpinEchoFieldMap_AP' in s.series_description):
            info[fmap_se_ap].append(s.series_id)
        # SE dir-PA
        if ('SpinEchoFieldMap_PA' in s.series_description):
            info[fmap_se_pa].append(s.series_id)
        # DWI dir-PA - NOTE that we have to place these here as they cannot easily by put in the BIDS /dwi folder
        if (s.dim4 == 1) and ('dMRI_dir106_PA_2x2x2' in s.series_description) and ('DIFFUSION' in s.image_type):
            info[fmap_dwi_pa].append(s.series_id) # append if multiple series meet criteria

            
        # SBREFs
        # dir AP
        if ('dMRI_dir106_AP_2x2x2_SBRef' in s.series_description):
            info[dwi_ap_sbref].append(s.series_id) # append if multiple series meet criteria
        if ('rfMRI_REST_AP_SBRef' in s.series_description):
            info[rest_ap_sbref].append(s.series_id) # append if multiple series meet criteria
        # dir PA
        if ('dMRI_dir106_PA_2x2x2_SBRef' in s.series_description):
            info[dwi_pa_sbref].append(s.series_id) # append if multiple series meet criteria
        if ('rfMRI_REST_PA_SBRef' in s.series_description):
            info[rest_pa_sbref].append(s.series_id) # append if multiple series meet criteria
        
    return info
