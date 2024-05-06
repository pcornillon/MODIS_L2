#!/bin/bash

echo "Running as user: $(whoami)"

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"

# write commands to excecute here

echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
date  | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "Starting the script..." | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "I am $(whoami) and proud of it" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"

# Make sure that we are using the most recent version of MODIS_L2

cd "$MATLAB_PROJECT_DIRECTORY"
echo "Pulling to $MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
git pull

# Start Matlab and run test script. 

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="matlab_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"

echo "I am still $(whoami) and about to fire up Matlab." 2>&1 | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"

sudo -u ubuntu -i bash -c 'nohup matlab -batch "prj=openProject('${MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'); AWS_batch_test;" > "${OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 | tee -a "${OUTPUT_DIRECTORY}/tester_session_log.txt" &'

echo "I just started Matlab. Am still $(whoami). It should be running in the background." | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
