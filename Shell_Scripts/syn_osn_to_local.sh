#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <start_year> <end_year>"
  exit 1
fi

# Assign the arguments to variables
START_YEAR=$1
END_YEAR=$2

# Validate that the start year is less than or equal to the end year
if [ "$START_YEAR" -gt "$END_YEAR" ]; then
  echo "Error: Start year must be less than or equal to end year."
  exit 1
fi

echo "Processing from $START_YEAR through $END_YEAR."

# Define the S3 bucket path and local destination base directory
# S3_BUCKET="s3://uri-gso-pcornillon-useast1/SST"
# PROFILE="iam_pcornillon"
S3_BUCKET="s3://modis-aqua-l2-sst-orbits/SST/"
LOCAL_BASE_DIR="/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits"
PROFILE="cornillon_osn"

# Loop over the years between START_YEAR and END_YEAR
for YEAR in $(seq $START_YEAR $END_YEAR); do
  # Loop over the months 01 to 12
  for MONTH in $(seq -w 01 12); do
    # Print out the year and month being processed and the start time
    START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    echo "Processing Year: $YEAR, Month: $MONTH"
    echo "Start Time: $START_TIME"

    # Capture the start time in seconds since epoch
    START_EPOCH=$(date +%s)

    # Construct the S3 source path and local destination path
    S3_SOURCE="$S3_BUCKET$YEAR/$MONTH/"
    LOCAL_DEST="$LOCAL_BASE_DIR/$YEAR/$MONTH/"

    # Create the local directory if it doesn't exist
    mkdir -p "$LOCAL_DEST"

    # Sync the data from S3 to the local directory and capture the output
    # SYNC_OUTPUT=$(aws s3 sync "$S3_SOURCE" "$LOCAL_DEST" --profile "$PROFILE" 2>&1)
    
    # Get a listing: aws s3 ls s3://modis-aqua-l2-sst-orbits/SST/2002/07/ --profile cornillon_osn --endpoint-url https://uri.osn.mghpcc.org
    # Get data:   aws s3 sync s3://modis-aqua-l2-sst-orbits/SST/2009/01/ /Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/2009/01/ --profile cornillon_osn --endpoint-url https://uri.osn.mghpcc.org 
    SYNC_OUTPUT=$(aws s3 sync "$S3_SOURCE" "$LOCAL_DEST" --profile "$PROFILE" --endpoint-url https://uri.osn.mghpcc.org 2>&1)
    # echo $S3_SOURCE
    # echo $LOCAL_DEST
    # echo $PROFILE

    # Capture the end time in seconds since epoch
    END_EPOCH=$(date +%s)

    # Calculate the elapsed time in seconds
    ELAPSED_TIME=$(($END_EPOCH - $START_EPOCH))

    # Check if the sync was successful
    if [ $? -eq 0 ]; then
      echo "Successfully synced $S3_SOURCE to $LOCAL_DEST"

      # Count the number of files copied
      FILE_COUNT=$(echo "$SYNC_OUTPUT" | grep -c "download:")

      # Extract file sizes and sum them
      TOTAL_SIZE_BYTES=$(echo "$SYNC_OUTPUT" | grep "download:" | awk '{sum += $3} END {print sum}')

      # If no files were copied, set size to zero
      if [ -z "$TOTAL_SIZE_BYTES" ]; then
        TOTAL_SIZE_BYTES=0
      fi

      # Convert total size to megabytes
      TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_BYTES / 1048576" | bc)

      # Calculate files per second
      if [ "$ELAPSED_TIME" -gt 0 ]; then
        FILES_PER_SECOND=$(echo "scale=2; $FILE_COUNT / $ELAPSED_TIME" | bc)
        MB_PER_SECOND=$(echo "scale=2; $TOTAL_SIZE_MB / $ELAPSED_TIME" | bc)
      else
        FILES_PER_SECOND="N/A"
        MB_PER_SECOND="N/A"
      fi

      # Output the summary
      echo "Files copied: $FILE_COUNT"
      echo "Elapsed time: ${ELAPSED_TIME} seconds"
      echo "Files per second: $FILES_PER_SECOND"
      echo "Megabytes per second: $MB_PER_SECOND"
    else
      echo "Failed to sync $S3_SOURCE to $LOCAL_DEST"
      echo "Error: $SYNC_OUTPUT"
    fi
  done
done