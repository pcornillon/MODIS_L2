#!/bin/bash

# Script to run remove_missing_data_filenames_from_granuleList in Matlab from
# the linux command line. Make sure that the year(s) to process are properly
# selected in remove_missing_data_filenames_from_granuleList.m 
#
# To run this script, connect to an AWS instance with access to /mnt/s3-uri-gso-pcornillon/,
# cd to /home/ubuntu/Documents/MODIS_L2/Shell_Scripts and ./remove_missing_data_filenames_from_granuleList 
sudo -u ubuntu bash -c '
  export REMOTE_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export REMOTE_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export REMOTE_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remove_missing_granules.txt"
  cd "$REMOTE_MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $REMOTE_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remove_missing_granules.txt"
  git pull
  FILENAME="matlab_$(date +'%Y-%m-%d_%H-%M-%S').out"
  echo "Starting Matlab as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remove_missing_granules.txt"
  nohup matlab -batch "prj=openProject('\''$REMOTE_MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); remove_missing_data_filenames_from_granuleList;" > "$REMOTE_OUTPUT_DIRECTORY/$FILENAME" 2>&1 &
  echo "Just started Matlab."  | tee -a "${REMOTE_OUTPUT_DIRECTORY}/remove_missing_granules.txt" '
