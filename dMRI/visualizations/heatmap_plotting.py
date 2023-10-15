import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import sys

# Check if the correct number of arguments are given
if len(sys.argv) != 3:
    print('Usage: python script.py [pmr] [mr]')
    sys.exit()

pmr = sys.argv[1]
mr = sys.argv[2]

# Adjust the parameters below according to your needs
csv_file_path = f'/home/perinedo/Projects/PK_PMR/derivatives/dMRI_connectome/sub-{pmr}/ses-{mr}/connectome/neonatal-5TT-M-CRIB/Structural_M-CRIB/whole_brain_10M_Structural_M-CRIB_Connectome.csv'

# Load data from CSV
data = pd.read_csv(csv_file_path)

# Generate heatmap
plt.figure(figsize=(15, 12))  # This can be adjusted to change the size of the heatmap
sns.heatmap(data,
            cmap='coolwarm',  # This can be adjusted to change the color scheme
            annot=False,       # This can be adjusted. If True, the values will be printed on the cells
            fmt=".1f",        # This changes the number of decimal points for the annotations
            linewidths=.5,    # This changes the width of the lines between cells
            )

# Show the heatmap
plt.show()
