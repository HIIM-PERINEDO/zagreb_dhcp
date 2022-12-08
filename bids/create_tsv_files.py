#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 20 12:23:34 2021

@author: jelena
Script for creating participants.tsv (and session.tsv?) files
"""
import pandas as pd


StudyFolder="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/rawdata"
patientTableFile="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/clinical_data/Patient_table-Project_PERINEDO.xlsx"
participantsFile="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/rawdata/participants.tsv"

#load original tsv file
orig_tsv = pd.read_csv(participantsFile, sep='\t')

# get list of subjects from the original participants.tsv file;
subject_ids=orig_tsv['participant_id']

# create new participants.tsv - new file needs to have participant_id, sex, birth_age, birth_weight
COLUMN_NAMES=['participant_id', 'sex', 'birth_age', 'birth_weight']
part_tsv = pd.DataFrame(columns=COLUMN_NAMES)
  

for sub_id in subject_ids : 
    
    # go through PK and PMR subjcts - they are in two different sheets in the xlsx. workbook
    #load patient table .xlsx file - sheet has some empty rows so do a small manipulation to create header
    if 'PMR' in sub_id :
        sheet = "PROJECT YEAR 2021"
    elif 'PK' in sub_id :
        sheet = "BEFORE PROJECT START"
    
    patient_data=pd.read_excel(patientTableFile, sheet_name=sheet, engine='openpyxl')
    #find a row with "CODE" and use it as header, and use data from there afterwards
    selectRow = patient_data[patient_data.iloc[:,0].str.match('CODE', na=False)]
    rowIdx=selectRow.index.item()
    
    patient_data.columns = patient_data.iloc[rowIdx]
    patient_data = patient_data[rowIdx+1:]
  
    #convert columns to strings because in a sheet with PK subjects something didn't work properly without this line
    patient_data['CODE']=patient_data['CODE'].apply(str)

    # extract the numeric code from the subject ID (last three digits)
    sub_id_code=sub_id[-3:]   
    
    #check if the subject is in the xlsx sheet, if not, return to he beginning of the for loop
    if sub_id_code not in patient_data['CODE'].values :
        print ('Subject ', sub_id, ' does not exits in the Patient Table in the sheet ', sheet)
        continue
    
    # to calculate birth age we need to take GW column and PLUS DAYS column and convert into float
    plus_days=patient_data.loc[(patient_data['CODE'] == sub_id_code)]['PLUS DAYS']
    gw=patient_data.loc[(patient_data['CODE'] == sub_id_code)]['GW'] 
    age=float(gw+plus_days/7)
    
    weight=float(patient_data.loc[(patient_data['CODE'] == sub_id_code)]['BIRTH WEIGHT'])
    
    sex=orig_tsv.loc[(orig_tsv['participant_id'].str.contains(sub_id)),'sex']
    sex=sex.iloc[0]
    
    s=pd.Series({'participant_id':sub_id, 'sex':sex, 'birth_age':age, 'birth_weight':weight})
    part_tsv=part_tsv.append(s, ignore_index=True)
    

# save the file with a new filename so we don't overwrite
part_tsv.to_csv(StudyFolder + "/participants_updated.tsv", sep="\t", index=False)
