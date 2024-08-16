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

# Define the S3 bucket path and local destination base directory
S3_BUCKET="s3://uri-gso-pcornillon-useast1/SST"
LOCAL_BASE_DIR="/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits"
PROFILE="iam_pcornillon"

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
    S3_SOURCE="$S3_BUCKET/$YEAR/$MONTH/"
    LOCAL_DEST="$LOCAL_BASE_DIR/$YEAR/$MONTH/"

    # Create the local directory if it doesn't exist
    mkdir -p "$LOCAL_DEST"

    # Sync the data from S3 to the local directory and capture the output
    SYNC_OUTPUT=$(aws s3 sync "$S3_SOURCE" "$LOCAL_DEST" --profile "$PROFILE" 2>&1)

    # Capture the end time in seconds since epoch
    END_EPOCH=$(date +%s)

    # Calculate the elapsed time in seconds
    ELAPSED_TIME=$(($END_EPOCH - $START_EPOCH))

    # Convert elapsed time to minutes
    ELAPSED_MINUTES=$(echo "scale=2; $ELAPSED_TIME / 60" | bc)

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

      # Calculate megabytes per minute
      if [ "$ELAPSED_MINUTES" != "0" ]; then
        MB_PER_MINUTE=$(echo "scale=2; $TOTAL_SIZE_MB / $ELAPSED_MINUTES" | bc)
      else
        MB_PER_MINUTE="N/A"
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