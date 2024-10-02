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
output_file="${satellite}_table.csv"

# Create the title for the table and the header row
echo "Satellite: $satellite" > "$output_file"
echo "Year,File Name,Number of Lines,Column 4,Column 5" >> "$output_file"

# Loop over the specified range of years
for year in $(seq $start_year $end_year)
do
    # Loop over the files in the folder that match the satellite and year pattern
    for file in ./${year}_${satellite}_*.txt
    do
        # Check if the file exists (in case there are no matches for some years)
        if [ -f "$file" ]; then
            # Get the number of lines in the file
            num_lines=$(wc -l < "$file")
            
            # Write the row to the CSV file: Year, File Name, Number of Lines, (Empty column 4), (Empty column 5)
            echo "$year,$file,$num_lines,," >> "$output_file"
        fi
    done
done

# Notify the user of the file creation
echo "Table created in file: $output_file"