#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 15 13:26:16 2022

@author: jelena


Script for updating session.tsv file by adding scan_age
"""

import argparse
import pandas as pd
import sys


parser = argparse.ArgumentParser(description='Script for updating session.tsv file by adding scan_age')
parser.add_argument('--subid', help='Subject ID (e.g. sub-PK350 or sub-PMR020) for which the session.tsv file needs to be updated', required=True)
parser.add_argument('--sesid', help='Session ID (e.g. ses-MR2) for which the session.tsv file needs to be updated', required=True)
parser.add_argument('--patientTableFile', help='xlsx workbook with patient data', required=True)
parser.add_argument('--StudyFolder', help='path to the folder with subjects, e.g. /Users/jelena/projekti/HIIM_Perinatal/data/testing_pmr_new/rawdata', required=True)
args = vars(parser.parse_args())


sub_id=args['subid']
ses_id=args['sesid']
patientTableFile=args['patientTableFile']
StudyFolder=args['StudyFolder']

# check if the subject is from the PK or PMR study to load the correct sheet from the Patient table
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
    

#check if the subject is in the xlsx sheet, if not, exit
if sub_id_code not in patient_data['CODE'].values :
    print('Subject ', sub_id, ' does not exits in the Patient Table in the sheet ', sheet)
    sys.exit()



# get scan_age from the Patient Table
scan_age=patient_data.loc[(patient_data['CODE'] == sub_id_code)]['WEEKS AT 2. MR']


#path to session.tsv file; load session.tsv
session_file = StudyFolder + '/' + sub_id + '/' + ses_id + '/' + 'session.tsv'
session_tsv = pd.read_csv(session_file, sep='\t')


# insert scan_age into session.tsv file after column 'filename'
index_no = session_tsv.columns.get_loc('filename')
session_tsv.insert(index_no + 1, 'scan_age', float(scan_age))


# save the updated session.tsv file
session_tsv.to_csv(session_file, sep="\t", index=False)

