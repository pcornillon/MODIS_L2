#!/bin/bash

# Generate the output filename for this job.

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="tester_${CURRENT_TIME}.out"

echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "Now you need to ssh to the spot instance: ssh -o StrictHostKeyChecking=no ubuntu@44.235.238.218" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "and submit Matlab job as follows: " 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
echo "nohup matlab -nodisplay -nosplash -nodesktop -r \"prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); AWS_batch_test\" > \"/mnt/uri-nfs-cornillon/Logs/nohup/$FILENAME\" 2>&1 &" 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt

nohup matlab -nodisplay -nosplash -nodesktop -r \"prj=openProject('/home/ubuntu/Documents/MODIS_L2/MODIS_L2.prj'); AWS_batch_tester\" > \"/mnt/uri-nfs-cornillon/Logs/nohup/$FILENAME\" 2>&1 &" 2>&1 | tee -a /mnt/uri-nfs-cornillon/tester_session_log.txt

echo "Script execution completed." 2>&1 | tee -a /mnt/uri-nfs-cornillon/simple_session_log.txt
