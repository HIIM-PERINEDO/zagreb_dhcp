#!/bin/bash

# Define a usage function
usage() {
  echo "Usage: $0 <start> <end>"
  echo "Runs pipeline for subjects from <start> to <end>, where <start> and <end> are positive numbers and <start> < <end>."
  exit 1
}

# Check that the correct number of input parameters is provided
if [[ $# -ne 2 ]]; then
  usage
fi

# Get the start and end values from input parameters
script_dir=$(dirname "$0")
start=$1
end=$2
mr=MR2
nbr=10M
tractography_type=FROM_THALAMUS_TO_WHOLE_HEMISPHERE
from_args=( )
# 9 is LeftThalamus, 48 is RightThalamus
#Left cortex is 1000 - 1035, Right cortex is 2000 - 2035
# Hardcoded list of strings for "-to"
to_args=(  )
exclude_args=(  )

case "$tractography_type" in
	FROM_THALAMUS_TO_WHOLE_HEMISPHERE) 
    from_args=( "9" "48" )
    # Hardcoded list of numerical arguments for "-from"
    # Creating the first string with numbers from 1000 to 1035
    numbers1=$(printf "%s," {1000..1035})
    numbers1=${numbers1%,}  # Removing the trailing comma

    # Creating the second string with numbers from 2000 to 2035
    numbers2=$(printf "%s," {2000..2035})
    numbers2=${numbers2%,}  # Removing the trailing comma

    # Creating an array with two elements
    to_args=("$numbers1" "$numbers2")

    exclude_args=( "41,48,170,192" "2,9,170,192"  ) # ("Left-Cerebral-White-Matter","Left-Thalamus", "brainstem", "Corpus_Callosum")

    # Displaying the elements of the array
    #echo "First element: ${number_list[0]}"
    #echo "Second element: ${number_list[1]}"
    ;;
	FROM_THALAMUS_TO_WHOLE_OCCIPITAL) 
    from_args=( "9" "48" )
    # 9 is LeftThalamus, 48 is RightThalamus
    #Left cortex is 1000 - 1035, Right cortex is 2000 - 2035
    # Hardcoded list of strings for "-to"
    to_args=( "1011,1013,1021" "2011,2013,2021" )
    exclude_args=( "" ""  )
    ;;
esac

echo "FROM element: ${from_args[0]}"
echo "TO element: ${to_args[0]}"

scripts_python=( "dMRI_noddi.py" ) 
scripts_bash=( "dMRI_prepare_dmri_pipeline.sh" "dMRI_preprocess.sh" "dMRI_response.sh" "dMRI_csd.sh"  "dMRI_neonatal_5tt_mcrib.sh" "dMRI_registration.sh" )
scripts_bash_additional_args=( "" "" "" ""  "" "" )
# Loop through the array and print each element along with its index
#for ((i=0; i<${#from_args[@]}; i++)); do
#    #echo "Index: $i, Element: ${scripts_bash[$i]}"
#    scripts_bash+=("dMRI_tractography_roi.sh")
#    temp_str="-from ${from_args[$i]} -to ${to_args[$i]} -exclude ${exclude_args[$i]} -nbr ${nbr}"
    #echo $temp_str
#    scripts_bash_additional_args+=( "$temp_str" )
#done

scripts_bash+=("dMRI_tractography.sh")
scripts_bash_additional_args+=(" -nbr 10M")

scripts_bash+=("dMRI_connectome.sh")
scripts_bash_additional_args+=("")

#for script_file in ${scripts_bash_additional_args[@]}; do
  #echo "Script $script_file"
#done

# Check if the input parameters are valid
if ! [[ "$start" =~ ^[1-9][0-9]*$ ]] || ! [[ "$end" =~ ^[1-9][0-9]*$ ]] || (( start > end )); then
  echo "Error: Invalid input parameters. Please provide two positive numbers, with the first one smaller than the second."
  usage
fi

# Loop through subjects from start to end
for (( i=$start; i<=$end; i++ )); do
  # Construct the subject ID (e.g. PMR001)
  subject_id=$(printf "PMR%03d" $i)

  for ((j=0; j<${#scripts_bash[@]}; j++)); do
    if [ -f $script_dir/${scripts_bash[$j]}  ]; then
      # If it exists, run the script
      echo "Running script ${scripts_bash[$j]} for subject $subject_id"
      bash $script_dir/${scripts_bash[$j]} $subject_id $mr ${scripts_bash_additional_args[$j]}
    else
      # If it doesn't exist, print an error message
      echo "Error: script file not found: ${scripts_bash[$j]}"
    fi
  done

  for script_file in ${scripts_python[@]}; do
    if [ -f $script_dir/$script_file ]; then
      # If it exists, run the script
      echo "Running script $script_file for subject $subject_id"
      python $script_dir/$script_file $subject_id $mr
    else
      # If it doesn't exist, print an error message
      echo "Error: script file not found: $script_file"
    fi
  done

  # Loop for running dMRI_tractography_multiple_roi.sh with paired "-from" and "-to"
  #for idx in "${!from_args[@]}"; do
  #  if [ -f $script_dir/dMRI_tractography_roi_multiple.sh ]; then
  #  #if true ; then
  #    from_value=${from_args[$idx]}
  #    to_value=${to_args[$idx]}
  #    echo "Running dMRI_tractography_roi_multiple.sh with -from $from_value and -to $to_value for subject $subject_id"
  #    echo $script_dir/dMRI_tractography_roi_multiple.sh $subject_id $mr -from $from_value -to $to_value
  #  else
  #    echo "Error: script file not found: dMRI_tractography_multiple_roi.sh"
  #  fi
  #done
done
