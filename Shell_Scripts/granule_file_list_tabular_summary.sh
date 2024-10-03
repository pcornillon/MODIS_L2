#!/bin/bash

# Check if the correct number of arguments is provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <satellite> <start_year> <end_year>"
    echo "Example: $0 AQUA 2003 2024"
    exit 1
fi

satellite=$1
start_year=$2
end_year=$3
output_file="/Volumes/MODIS_L2_Original/granule_lists_from_OBPG/${satellite}_table.csv"

# Enable nullglob to prevent errors if no files are found
shopt -s nullglob

# Create the title for the table and the header row
echo "Satellite: $satellite" > "$output_file"
echo "Year,File Name,Number of Lines,Column 4,Column 5" >> "$output_file"

# Loop over the specified range of years
for year in $(seq $start_year $end_year)
do
    # Debugging: show the pattern being searched
    echo "Looking for files matching: /Volumes/MODIS_L2_Original/granule_lists_from_OBPG/${year}_${satellite}_*.txt"
    
    # Find files that match the year and satellite pattern
    files=(/Volumes/MODIS_L2_Original/granule_lists_from_OBPG/${year}_${satellite}_*.txt)
    
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

        # Get the number of lines in the file
        num_lines=$(wc -l < "$file")
        
        # Write the row to the CSV file: Year, File Name, Number of Lines, (Empty column 4), (Empty column 5)
        echo "$year,$file,$num_lines,," >> "$output_file"
    done
done

# Notify the user of the file creation
echo "Table created in file: $output_file"

#!/bin/bash
