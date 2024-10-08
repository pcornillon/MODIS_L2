#!/bin/bash

# This script will generate a csv file for the specified satellite and years
# with the year in the first column, the number of granules found at OBPG in
# the second column, 4 blank columns and the file name from which the list 
# providing the number of granules in the 2nd column was extracted. The csv
# file will be /Volumes/MODIS_L2_Original/${satellite}/Logs/${satellite}_table.csv
#
# INPUT: satellite (TERRA or AQUA) first_year last_year
#
# EXAMPLE
#
# ./granule_file_list_tabular_summary.sh TERRA 2002 2005

# Check if the correct number of arguments is provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <satellite> <start_year> <end_year>"
    echo "Example: $0 AQUA 2003 2024"
    exit 1
fi

satellite=$1
start_year=$2
end_year=$3
output_file="/Volumes/MODIS_L2_Original/${satellite}/Logs/${satellite}_table.csv"

# Enable nullglob to prevent errors if no files are found
shopt -s nullglob

# Create the title for the table and the header row
echo "Satellite: $satellite" > "$output_file"
echo "Year,Number of Lines,Column 3,Column 4,Column 5,Column 6,File Name" >> "$output_file"

# Loop over the specified range of years
for year in $(seq $start_year $end_year)
do
    # Debugging: show the pattern being searched
    echo "Looking for files matching: /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/${year}_${satellite}_filelist-*.txt"
    
    # Find files that match the year and satellite pattern
    files=(/Volumes/MODIS_L2_Original/granule_lists_from_OBPG/${year}_${satellite}_filelist-*.txt)
    
    # Check if any files are found
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found for year $year"
        continue
    fi
    
    # Loop over the files
    for file in "${files[@]}"
    do
        # Debugging: print the found file name
        echo "Found file: $file"

        # Get the number of lines in the file. Add 1 since these listings do not have a linefeed for the last line so it doesn't get counted.
        num_lines=$(( $(wc -l < "$file") + 1 ))
        
        # Write the row to the CSV file: Year, Number of Lines, (Empty 3rd to 6th columns), File Name in 7th column
        echo "$year,$num_lines,,,,,$file" >> "$output_file"
    done
done

# Notify the user of the file creation
echo "Table created in file: $output_file"
