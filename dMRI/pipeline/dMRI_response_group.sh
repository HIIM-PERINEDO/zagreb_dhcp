#!/bin/bash

# Check if an input file is provided as an argument; otherwise, use a hardcoded file path
input_file=${1:-"path/to/subject_ids.txt"}

# Directory where subject folders are located
base_directory="path/to/base/directory"

# Array to store all input response functions
response_functions=()

# Read subject IDs and build the list of response function files
while IFS= read -r subject_id; do
    response_file="$base_directory/sub-${subject_id}/ses-MR2/dwi/response.txt"
    if [[ -f "$response_file" ]]; then
        response_functions+=("$response_file")
    else
        echo "Response function file not found for subject: $subject_id"
    fi
done < "$input_file"

# Check if there are any response functions to process
if [[ ${#response_functions[@]} -eq 0 ]]; then
    echo "No response function files found. Exiting."
    exit 1
fi

# Calculate the average response function
output_response="average_response.txt"
responsemean "${response_functions[@]}" "$output_response"

echo "Average response function calculated: $output_response"
