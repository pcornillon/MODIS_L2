#!/bin/bash

# Variables
REMOTE_USER="ubuntu"
REMOTE_HOST="ec2-52-11-152-158.us-west-2.compute.amazonaws.com"
REMOTE_BASE_DIR="/datadisk/SST"
LOCAL_BASE_DIR="."
SSH_KEY="/path/to/your-key.pem"

# Loop through the years 2003 to 2008
for YEAR in {2003..2008}; do
  # Loop through the months 01 to 12
  for MONTH in {01..12}; do
    # Construct the remote directory path
    REMOTE_DIR="${REMOTE_BASE_DIR}/${YEAR}/${MONTH}"
    
    # Use rsync to copy the .nc4 files from the remote directory to the local directory
    rsync -avz "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/*.nc4" ${LOCAL_BASE_DIR}/
    
    # Check if the rsync command was successful
    if [ $? -eq 0 ]; then
      # If successful, delete the original files on the remote server
      ssh -i ${SSH_KEY} ${REMOTE_USER}@${REMOTE_HOST} "rm -f ${REMOTE_DIR}/*.nc4"
      
      # Print a success message
      echo "Files from ${REMOTE_DIR} successfully copied and deleted from the remote server."
    else
      # If rsync failed, print an error message
      echo "Failed to copy files from ${REMOTE_DIR}. Original files not deleted."
    fi
  done
done