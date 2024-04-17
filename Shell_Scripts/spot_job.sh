#!/bin/bash

# Associate fixed IP address.

MYID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

su ubuntu -c "/usr/local/bin/aws --profile iam_pcornillon ec2 associate-address --allocation-id eipalloc-095c69c402b90902b --instance-id ${MYID}"

while true; do
    myip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    if [[ "$myip" == "44.235.238.218" ]]; then
        break
    else
        sleep 2
    fi
done

umount /mnt/uri-nfs-cornillon
mount /mnt/uri-nfs-cornillon

# write commands to excecute here

echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
date 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
echo "" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
echo "Starting the script..." 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

echo "I am $(whoami) and proud of it" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

touch /home/ubuntu/proof_of_life

# Define the Matlab Project directory.

MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"

# Define the output directory for the nohup logs to be generated from the Matlab and python commands below.

OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/nohup/"

# Ensure the output directory exists, if it doesn't, create it.

mkdir -p "$OUTPUT_DIRECTORY"
echo "Checked for the output directory, created if it did not exist." 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

# Make sure that we are using the most recent version of MODIS_L2

cd "$MATLAB_PROJECT_DIRECTORY"
echo "Pulling to $MATLAB_PROJECT_DIRECTORY" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
su ubuntu -c 'git pull' 

# Sanity check to make sure that it pulled properly.

sed -n '41p' "${MATLAB_PROJECT_DIRECTORY}batch_jobs/AWS_batch_test.m" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

# Start Matlab and run test script. The script it runs will exit after at least 75% (which could be changed, e.g./ to 100%) of the jobs have finished
# or after the estimated required processing time has elapsed. It estimates this time based on the time for one of the submitted batch jobs to finish.
# It estimates this time assuming 100 minutes per orbit and 11 minutes to process an orbit. These numbers are changeable depending on how fast the CPU is.
# Note that the command opens the Matlab project for MODIS_L2. From there it finds all of the functions it needs. First, construct the output filename
# then execute the command

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="matlab_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Matlab portion to $FILENAME" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

echo "I am still $(whoami) and about to fire up Matlab." 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

# su ubuntu -c 'nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('${MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'); AWS_batch_test"  > "${OUTPUT_DIRECTORY}${FILENAME}" 2>&1 &'
# sudo -u ubuntu -i bash -c 'nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('\''${MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'\''); AWS_batch_test" > "${OUTPUT_DIRECTORY}${FILENAME}" 2>&1 &'
#  sudo -u ubuntu -i bash -c 'export MATLAB_PROJECT_DIRECTORY="/home/ubuntu/Documents/MODIS_L2/"; export OUTPUT_DIRECTORY="/mnt/uri-nfs-cornillon/Logs/nohup/"; CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S"); FILENAME="matlab_${CURRENT_TIME}.out"; 
# nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('\''${MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'\''); AWS_batch_test" > "${OUTPUT_DIRECTORY}${FILENAME}" 2>&1 &'
nohup matlab -nodisplay -nosplash -nodesktop -r "prj=openProject('${MATLAB_PROJECT_DIRECTORY}MODIS_L2.prj'); AWS_batch_test; exit" > "${OUTPUT_DIRECTORY}${FILENAME}" 2>&1 | tee -a "${OUTPUT_DIRECTORY}tester_session_log.txt"

echo "I just started Matlab. Am still $(whoami). It should be running in the background." 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt
echo -e "Here are the running Matlab jobs \n$(ps aux | grep MATLAB | grep -v grep)\n" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

echo "Wait for 60 seconds..."
sleep 60
echo "Continuing now."

echo -e "Check again for running Matlab jobs \n$(ps aux | grep MATLAB | grep -v grep)\n" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

echo "Wait for 60 seconds..."
sleep 60
echo "Continuing now."

echo -e "Check again for running Matlab jobs \n$(ps aux | grep MATLAB | grep -v grep)\n" 2>&1 | tee -a /mnt/uri-nfs-cornillon/session_log.txt

# Submit Python job to copy .nc4 files from local storage to remote storage. Note that we first move to the folder with the copy script in it.

cd Shell_Scripts

CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="AWS_copy_${CURRENT_TIME}.out"
echo "Current time is $CURRENT_TIME and it will write the output for the Python portion to $FILENAME"

nohup python "${MATLAB_PROJECT_DIRECTORY}Shell_Scripts/AWS_copy_nc4_to_remote.py" > "${OUTPUT_DIRECTORY}/${FILENAME}" 2>&1 &

echo "Script execution completed."
