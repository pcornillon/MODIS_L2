#!/bin/bash

# Get local date and time to use in output log file names and generate the names of these log files.

LOCAL_CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
AWS_FILENAME="AWS_copy_${LOCAL_CURRENT_TIME}.out"

# Define the output directory for the log file for this session.

LOCAL_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
LOCAL_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

# Change to the git repo directory for this project and pull the latest changes as user ubuntu

cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
git pull

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

echo "Current time is $LOCAL_CURRENT_TIME and it will write the output for the Python portion to $AWS_FILENAME"

nohup python "${LOCAL_MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${LOCAL_OUTPUT_DIRECTORY}${AWS_FILENAME}" 2>&1 &

