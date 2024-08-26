#!/bin/bash

# Variables
REMOTE_USER="ubuntu"
REMOTE_HOST="ec2-52-11-152-158.us-west-2.compute.amazonaws.com"
REMOTE_BASE_DIR="/datadisk/SST/"
LOCAL_BASE_DIR="/Volumes/MODIS_L2_Modified/OBPG/SST_Orbits/"
SSH_KEY="~/.ssh/id_rsa"  # Path to your SSH private key

# Specify the year you want to copy files for
YEAR=$1

# Construct the remote directory path
REMOTE_DIR="${REMOTE_BASE_DIR}/${YEAR}"

# Use rsync to recursively copy all .nc4 files from the remote directory to the local directory
rsync -avz --include="*/" --include="*.nc4" --exclude="*" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" "${LOCAL_BASE_DIR}${YEAR}"

# Check if the rsync command was successful
if [ $? -eq 0 ]; then
  # If successful, delete the original .nc4 files on the remote server
  ssh ${REMOTE_USER}@${REMOTE_HOST} "find ${REMOTE_DIR} -type f -name '*.nc4' -delete"
  
  # Print a success message
  echo "All .nc4 files from ${REMOTE_DIR} successfully copied and deleted from the remote server."
else
  # If rsync failed, print an error message
  echo "Failed to copy files from ${REMOTE_DIR}. Original files not deleted."
fi