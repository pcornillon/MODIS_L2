#!/bin/bash

# Path to your bad files list
BAD_FILES_LIST=~/Dropbox/Data/MODIS_L2/check_orbits/bad_files.txt

# Base paths
S3_BASE_PATH="s3://modis-aqua-l2-sst-orbits/SST/"
LOCAL_BASE_PATH="/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/"

# Profile and endpoint for OSN
AWS_PROFILE="cornillon_osn"
ENDPOINT_URL="https://uri.osn.mghpcc.org"

# Mode: test or execute
MODE=$1

# Check for correct mode
if [ "$MODE" != "test" ] && [ "$MODE" != "execute" ]; then
    echo "Usage: $0 [test|execute]"
    exit 1
fi

# Read through each line in the bad_files.txt file
while IFS= read -r file; do
    # Strip the local base path to construct the OSN path
    OSN_PATH="${S3_BASE_PATH}${file#${LOCAL_BASE_PATH}}"
    
    # Echo the local file to be removed
    echo "Local file to be removed: ${file}"
    
    # Echo the corresponding file to be removed from OSN
    echo "OSN file to be removed: ${OSN_PATH}"

    if [ "$MODE" == "execute" ]; then
        # Remove the local file
        if [ -f "$file" ]; then
            rm "$file"
            echo "Removed local file: $file"
        else
            echo "Local file not found: $file"
        fi

        # Remove the file from OSN
        aws s3 rm "${OSN_PATH}" --profile ${AWS_PROFILE} --endpoint-url ${ENDPOINT_URL}
        if [ $? -eq 0 ]; then
            echo "Successfully removed ${OSN_PATH} from OSN"
        else
            echo "Failed to remove ${OSN_PATH} from OSN"
        fi
    fi

done < "${BAD_FILES_LIST}"

echo "Process completed in $MODE mode."