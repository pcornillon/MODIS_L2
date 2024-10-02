#!/bin/bash

# Check if the correct number of arguments is provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <satellite> <start_year> <end_year>"
    echo "Example: $0 AQUA 2003 2005"
    exit 1
fi

satellite=$1
start_year=$2
end_year=$3

# Validate the satellite argument
if [ "$satellite" == "AQUA" ]; then
    sensor_id=7
    dtid=1047
elif [ "$satellite" == "TERRA" ]; then
    sensor_id=8
    dtid=1087
else
    echo "Invalid satellite. Please choose either AQUA or TERRA."
    exit 1
fi

# Validate the year range
if ! [[ "$start_year" =~ ^[0-9]{4}$ ]] || ! [[ "$end_year" =~ ^[0-9]{4}$ ]]; then
    echo "Start year and end year must be valid 4-digit numbers."
    exit 1
fi

if [ "$start_year" -gt "$end_year" ]; then
    echo "Start year cannot be greater than end year."
    exit 1
fi

# Loop over the specified range of years
for year in $(seq $start_year $end_year)
do
    # Replace the year and satellite in the wget command
    wget -q --post-data="results_as_file=1&sensor_id=${sensor_id}&dtid=${dtid}&sdate=${year}-01-01 00:00:00&edate=${year}-12-31 23:59:59&subType=1&addurl=1" -O /Users/petercornillon/${year}_${satellite}_filelist-10-02-2024.txt - https://oceandata.sci.gsfc.nasa.gov/api/file_search

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded file for year ${year} for ${satellite}"
    else
        echo "Failed to download file for year ${year} for ${satellite}"
    fi
done