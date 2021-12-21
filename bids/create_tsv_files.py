#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 20 12:23:34 2021

@author: jelena
Script for creating participants.tsv (and session.tsv?) files
"""

import os
import pandas as pd
import glob


StudyFolder="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/rawdata"
patientTableFile="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/clinical_data/Patient_table-Project_PERINEDO.xlsx"
participantsFile="/Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/rawdata/participants.tsv"


#get list of subject_ids from a StudyFolder; split each part to get only last part, from the last three values of each last part get a sub_id and add it to a list; sort the list at the end
folderList=glob.glob(StudyFolder + '/sub-*')
newList=[]
for string in folderList :
    stringSplit=os.path.split(string)
    stringNew=stringSplit[1]
    newList.append(stringNew[-3:])
newList.sort()


#load original tsv file
orig_tsv = pd.read_csv(participantsFile, sep='\t')


#load patient table .xlsx file - sheet has some empty rows atc so do a small manipulation to create header
my_sheet = "PROJECT YEAR 2021"
patient_data=pd.read_excel(patientTableFile, sheet_name=my_sheet, engine='openpyxl')
# use fourth row (index=3) as a header, and data from there afterwards
patient_data.columns = patient_data.iloc[3]
patient_data = patient_data[5:]

    
# create new participants.tsv - new file needs to have participant_id, sex (can keep it from original file), birth_age, birth_weight, singleton (S = singleton, M = multiple pregnancy)
COLUMN_NAMES=['participant_id', 'sex', 'birth_age', 'birth_weight', 'singleton']
part_tsv = pd.DataFrame(columns=COLUMN_NAMES)
    
for sub_id in newList : 
       
    sex=orig_tsv.loc[(orig_tsv['participant_id'].str.contains(sub_id)),'sex']
    sex=sex.iloc[0]
    
    # to calculate birth age we need to take GW column and PLUS DAYS column and convert into float
    plus_days=patient_data.loc[(patient_data['CODE'] == sub_id)]['PLUS DAYS']
    gw=patient_data.loc[(patient_data['CODE'] == sub_id)]['GW'] 
    age=float(gw+plus_days/7)
    
    weight=float(patient_data.loc[(patient_data['CODE'] == sub_id)]['BIRTH WEIGHT'])
    
    s=pd.Series({'participant_id':sub_id, 'sex':sex, 'birth_age':age, 'birth_weight':weight})
    part_tsv=part_tsv.append(s, ignore_index=True)
    

# save the file with a new filename so we don't overwrite
part_tsv.to_csv(StudyFolder + "/participants_updated.tsv", sep="\t", index=False)
