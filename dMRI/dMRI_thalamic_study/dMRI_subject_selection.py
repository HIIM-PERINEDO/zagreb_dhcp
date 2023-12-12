import os
import pandas as pd
import subprocess
import os

# Hardcoded values
START_PMR = 1  # Starting PMR value
END_PMR = 2  # Ending PMR value
SESSION_NAME = 'MR2'
FILE_PATH_TEMPLATE = "rawdata/sub-PMR{}/ses-{}/session_QC.tsv"
COLUMNS_TO_CHECK = ['dMRI_dwiAP', 'dMRI_vol_for_b0AP', 'dMRI_vol_for_b0PA'] #, 'sMRI_use_for_5ttgen_mcrib'



def is_numerical(val):
    """Check if the value is numerical."""
    try:
        float(val)
        return True
    except:
        return False

def main():
    summary = {}
    
    for i in range(START_PMR, END_PMR + 1):
        pmr_value = str(i).zfill(3)  # Convert i to a string with leading zeros, e.g., '001'
        file_path = FILE_PATH_TEMPLATE.format(pmr_value, SESSION_NAME)

        # Check if the file exists
        if not os.path.exists(file_path):
            print(f"File {file_path} not found!")
            summary[pmr_value] = 0
            continue

        # Load the TSV file
        data = pd.read_csv(file_path, sep='\t')
        
        # Check for numerical values
        output_values = []
        for col in COLUMNS_TO_CHECK:
            if col in data.columns:
                numerical_values = [val for val in data[col] if is_numerical(val)]
                output_values.extend(numerical_values)
            else:
                output_values.append('ColumnNotFound')

        # Determine the conclusion
        if all(item == 'ColumnNotFound' for item in output_values):
            conclusion = 0
        elif len(output_values) == len(COLUMNS_TO_CHECK) and all(output_values):
            conclusion = 1
        else:
            conclusion = 0
        
        summary[pmr_value] = conclusion
        print(pmr_value, *output_values, conclusion)

    # Print the summary
    for pmr, conclusion in summary.items():
        print(f"PMR{pmr}", conclusion)
        
        currdir = subprocess.check_output(['pwd']).decode('utf-8').strip()
        print("Currrent directory: " + str(currdir) )
        sub_id = int(pmr[-3:])
        print(sub_id)
        cmd = ['bash', os.path.join( currdir , "code" , "zagreb_dhcp" , "dMRI" , "pipeline" , "dMRI_thalamic_study_full_pipeline.sh" ),
           str(sub_id) , str(sub_id) ]
        #subprocess.run(cmd)

if __name__ == "__main__":
    main()
