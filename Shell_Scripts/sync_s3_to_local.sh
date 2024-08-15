#!/bin/bash

# Define the S3 bucket path and local destination base directory

S3_BUCKET="s3://uri-gso-pcornillon-useast1/SST"
LOCAL_BASE_DIR="/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits"
PROFILE="iam_pcornillon"

# Loop over the years 2002 to 2023
for YEAR in {2002..2023}; do
  echo $YEAR
  date

  # Loop over the months 01 to 12

  for MONTH in {01..12}; do
    # Construct the S3 source path and local destination path

    S3_SOURCE="$S3_BUCKET/$YEAR/$MONTH/"
    LOCAL_DEST="$LOCAL_BASE_DIR/$YEAR/$MONTH/"

    # Create the local directory if it doesn't exist
    mkdir -p "$LOCAL_DEST"

    # Sync the data from S3 to the local directory
    aws s3 sync "$S3_SOURCE" "$LOCAL_DEST" --profile "$PROFILE"

    # Check if the sync was successful
    if [ $? -eq 0 ]; then
      echo "Successfully synced $S3_SOURCE to $LOCAL_DEST"
    else
      echo "Failed to sync $S3_SOURCE to $LOCAL_DEST"
    fi
  done
done