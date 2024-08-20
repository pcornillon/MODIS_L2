#!/bin/bash

# Assign the filename passed in to an internal variable.

BATCH_JOB_FILENAME="$1"

# Get local date and time to use in output log file names and generate the names of these log files.

LOCAL_CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")

AWS_FILENAME="AWS_copy_${LOCAL_CURRENT_TIME}.out"
LOCAL_SESSION_FILENAME="local_session_${LOCAL_CURRENT_TIME}.txt"
REMOTE_SESSION_FILENAME="remote_session_${LOCAL_CURRENT_TIME}.txt"
MATLAB_FILENAME="matlab_${LOCAL_CURRENT_TIME}.txt"

# Define the output directory for the log file for this session.

LOCAL_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
LOCAL_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

LOCAL_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"

# Write out the names of output log files.

echo ${LOCAL_OUTPUT_DIRECTORY}
echo $LOCAL_SESSION_FILENAME
echo ${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME

echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "Will write to the following files:" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "AWS_FILENAME: ${LOCAL_OUTPUT_DIRECTORY}/$AWS_FILENAME" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$AWS_FILENAME"
echo "LOCAL_SESSION_FILENAME: ${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "REMOTE_SESSION_FILENAME: ${LOCAL_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME"
echo "MATLAB_FILENAME: ${LOCAL_OUTPUT_DIRECTORY}/$MATLAB_FILENAME" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$MATLAB_FILENAME"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"

# Write test file.

touch /home/ubuntu/proof_of_life

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$LOCAL_OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"

# Some output.

echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
date  | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "Starting the script" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"
echo "I am $(whoami) and proud of it" | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"

# Change to the git repo directory for this project and pull the latest changes as user ubuntu

cd "$LOCAL_MATLAB_PROJECT_DIRECTORY"
git pull

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

echo "Current time is $LOCAL_CURRENT_TIME and it will write the output for the Python portion to $AWS_FILENAME"

echo ${LOCAL_MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py
echo ${LOCAL_OUTPUT_DIRECTORY}/${LOCAL_FILENAME}

nohup python "${LOCAL_MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${LOCAL_OUTPUT_DIRECTORY}/${LOCAL_FILENAME}" 2>&1 &

# Start Matlab and submit the jobs to submit batch jobs for processing. 

echo "I am about to fire up Matlab." 2>&1 | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"

sudo -u ubuntu bash -c '
  export REMOTE_OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export REMOTE_MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export REMOTE_OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${REMOTE_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME"
  cd "$REMOTE_MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $REMOTE_MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME"
  git pull
  echo "Starting Matlab as user $(whoami)" | tee -a "${REMOTE_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME"
  nohup matlab -batch "prj=openProject('\''$REMOTE_MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); $BATCH_JOB_FILENAME;" > "$REMOTE_OUTPUT_DIRECTORY/$MATLAB_FILENAME" 2>&1 &
  echo "Just started Matlab."  | tee -a "${REMOTE_OUTPUT_DIRECTORY}/$REMOTE_SESSION_FILENAME" '

echo "I just started Matlab. Am still $(whoami). It should be running in the background. This script is finished." | tee -a "${LOCAL_OUTPUT_DIRECTORY}/$LOCAL_SESSION_FILENAME"

