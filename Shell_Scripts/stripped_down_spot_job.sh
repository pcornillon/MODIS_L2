#!/bin/bash

echo "Running as user: $(whoami)"

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

# write commands to excecute here

echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
date  | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "Starting the script..." | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
echo "I am $(whoami) and proud of it" | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"

# Start Matlab and run test script. 

echo "I am still $(whoami) and about to fire up Matlab." 2>&1 | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"

sudo -u ubuntu bash -c '
  export OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/"
  export MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"
  export OUTPUT_DIRECTORY_NOHUP="/mnt/uri-nfs-cornillon/Logs/nohup/"
  echo "Am running in sudo submitted version of script." | tee -a "${OUTPUT_DIRECTORY}/inner_session_log.txt"
  cd "$MATLAB_PROJECT_DIRECTORY"
  echo "Pulling to $MATLAB_PROJECT_DIRECTORY as user $(whoami)" | tee -a "${OUTPUT_DIRECTORY}/inner_session_log.txt"
  git pull
  FILENAME="matlab_$(date +'%Y-%m-%d_%H-%M-%S').out"
  nohup matlab -batch "prj=openProject('\''$MATLAB_PROJECT_DIRECTORY/MODIS_L2.prj'\''); AWS_batch_test;" > "$OUTPUT_DIRECTORY/$FILENAME" 2>&1 &
  echo "Just started Matlab mother job"  | tee -a "${OUTPUT_DIRECTORY}/inner_session_log.txt" '

echo "I just started Matlab. Am still $(whoami). It should be running in the background." | tee -a "${OUTPUT_DIRECTORY}/session_log.txt"
