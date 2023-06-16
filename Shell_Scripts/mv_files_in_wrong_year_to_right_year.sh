#!/bin/bash

YEAR=$1
FOLDER="/Volumes/Aqua-1/MODIS_R2019/combined/"

# Get previous and next year
PREVIOUS_YEAR=$((YEAR - 1))
NEXT_YEAR=$((YEAR + 1))

echo "Processing files for year ${YEAR}..."

# Go to the folder of the year
cd ${FOLDER}${YEAR}

# Process files for previous year
echo "Moving files for previous year ${PREVIOUS_YEAR}..."
for file in AQUA_MODIS.${PREVIOUS_YEAR}*; do
    if [ -e "../${PREVIOUS_YEAR}/${file}" ]; then
        echo "File ${file} already exists in ${PREVIOUS_YEAR} folder. Removing from ${YEAR} folder..."
        rm "${file}"
    else
        echo "Moving ${file} to ${PREVIOUS_YEAR} folder..."
        mv "${file}" "../${PREVIOUS_YEAR}/"
    fi
done

# Process files for next year
echo "Moving files for next year ${NEXT_YEAR}..."
for file in AQUA_MODIS.${NEXT_YEAR}*; do
    if [ -e "../${NEXT_YEAR}/${file}" ]; then
        echo "File ${file} already exists in ${NEXT_YEAR} folder. Removing from ${YEAR} folder..."
        rm "${file}"
    else
        echo "Moving ${file} to ${NEXT_YEAR} folder..."
        mv "${file}" "../${NEXT_YEAR}/"
    fi
done

echo "Done processing files for year ${YEAR}."
