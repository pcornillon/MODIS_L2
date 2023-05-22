#!/bin/bash
#
# This script will copy all the files in folder 1 to folder 2, which do not alrealy exist in
# folder 2. If the file already exists, it will not copy it; it will leave it folder 1.
#
#  MAKE SURE TO CHANGE THE YEAR TO PROCESS IN THE FOLLOWING TWO LINES.

folder1="/Volumes/Aqua-1/MODIS_R2019/day/2009/"
folder2="/Volumes/Aqua-1/MODIS_R2019/combined/2009/"

for file in "$folder1"/*; do
    if [ -e "$folder2/$(basename "$file")" ]; then
        echo "File $(basename "$file") exists in $folder2. Skipping..."
    else
        mv "$file" "$folder2"
#        echo "Moved $(basename "$file") to $folder2."
    fi
done
